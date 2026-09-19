-- =============================================================================
-- 015_prediction_ordering.sql
--
-- Replaces fn_predict_colleges to fix result ordering. See the ORDER BY comment
-- below. Migrations are forward-only, so this restates the whole function
-- rather than editing 014.
-- =============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION fn_predict_colleges(
  p_exam_id          SMALLINT,
  p_rank             BIGINT,
  p_category_id      SMALLINT,
  p_applicant_gender applicant_gender,
  p_is_pwd           BOOLEAN        DEFAULT false,
  p_home_state_id    SMALLINT       DEFAULT NULL,
  p_branch_ids       SMALLINT[]     DEFAULT NULL,
  p_state_ids        SMALLINT[]     DEFAULT NULL,
  p_college_types    college_type[] DEFAULT NULL,
  p_profile_code     TEXT           DEFAULT 'default',
  p_limit            INT            DEFAULT 200
)
RETURNS TABLE (
  college_branch_id        BIGINT,
  college_id               INT,
  branch_id                SMALLINT,
  counselling_authority_id SMALLINT,
  seat_type_id             SMALLINT,
  quota_id                 SMALLINT,
  gender_id                SMALLINT,
  grade                    match_grade,
  score                    NUMERIC,
  weighted_closing_rank    BIGINT,
  best_closing_rank        BIGINT,
  worst_closing_rank       BIGINT,
  latest_closing_rank      BIGINT,
  rank_margin              BIGINT,
  years_available          SMALLINT,
  trend_slope              NUMERIC,
  cutoff_history           JSONB
)
LANGUAGE plpgsql
STABLE
AS $fn$
#variable_conflict use_column
DECLARE
  v_profile prediction_weight_profiles%ROWTYPE;
  w0 NUMERIC; w1 NUMERIC; w2 NUMERIC; w3 NUMERIC; w4 NUMERIC;
BEGIN
  IF p_rank IS NULL OR p_rank <= 0 THEN
    RAISE EXCEPTION 'fn_predict_colleges: rank must be a positive integer, got %', p_rank;
  END IF;

  SELECT * INTO v_profile
  FROM prediction_weight_profiles
  WHERE code = p_profile_code;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'fn_predict_colleges: unknown weight profile %', p_profile_code;
  END IF;

  SELECT coalesce(max(pw.weight) FILTER (WHERE pw.year_offset = 0), 0.40),
         coalesce(max(pw.weight) FILTER (WHERE pw.year_offset = 1), 0.30),
         coalesce(max(pw.weight) FILTER (WHERE pw.year_offset = 2), 0.20),
         coalesce(max(pw.weight) FILTER (WHERE pw.year_offset = 3), 0.10),
         coalesce(max(pw.weight) FILTER (WHERE pw.year_offset = 4), 0.00)
    INTO w0, w1, w2, w3, w4
  FROM prediction_year_weights pw
  WHERE pw.profile_id = v_profile.id;

  RETURN QUERY
  WITH eligible_seat_types AS (
    SELECT st.id
    FROM seat_types st
    JOIN categories cat ON cat.id = st.category_id
    WHERE (st.category_id = p_category_id OR cat.is_open_pool)
      AND (NOT st.is_pwd OR p_is_pwd)
  ),
  eligible_genders AS (
    SELECT g.id
    FROM genders g
    WHERE p_applicant_gender = ANY (g.allowed_applicant_genders)
  ),
  candidate AS (
    SELECT
      t.college_branch_id,
      t.college_id,
      t.branch_id,
      t.counselling_authority_id,
      t.seat_type_id,
      t.quota_id,
      t.gender_id,
      t.best_closing_rank,
      t.worst_closing_rank,
      t.latest_closing_rank,
      t.years_available,
      t.trend_slope,
      t.cutoff_history,
      col.state_id AS college_state_id,
      fn_weighted_rank(t.closing_y0, t.closing_y1, t.closing_y2, t.closing_y3, t.closing_y4,
                       w0, w1, w2, w3, w4) AS wcr
    FROM mv_program_cutoff_trend t
    JOIN colleges col     ON col.id = t.college_id AND col.is_active
    JOIN college_branches cb ON cb.id = t.college_branch_id AND cb.is_active
    JOIN quotas q         ON q.id = t.quota_id
    WHERE t.exam_id = p_exam_id
      AND t.seat_type_id IN (SELECT id FROM eligible_seat_types)
      AND t.gender_id    IN (SELECT id FROM eligible_genders)
      -- Home-state / other-state eligibility.
      AND (NOT q.requires_home_state_match
           OR (p_home_state_id IS NOT NULL AND col.state_id = p_home_state_id))
      AND (NOT q.requires_other_state
           OR (p_home_state_id IS NULL OR col.state_id <> p_home_state_id))
      AND (p_branch_ids    IS NULL OR t.branch_id       = ANY (p_branch_ids))
      AND (p_state_ids     IS NULL OR col.state_id      = ANY (p_state_ids))
      AND (p_college_types IS NULL OR col.college_type  = ANY (p_college_types))
  ),
  graded AS (
    -- Grade and score once, here. Computing them again in ORDER BY would both
    -- duplicate the work and make the sort depend on an output-column alias.
    SELECT
      c.college_branch_id,
      c.college_id,
      c.branch_id,
      c.counselling_authority_id,
      c.seat_type_id,
      c.quota_id,
      c.gender_id,
      fn_grade_match(p_rank, c.wcr, c.best_closing_rank, c.worst_closing_rank,
                     c.years_available, v_profile.strong_match_factor,
                     v_profile.borderline_factor, v_profile.min_years_for_strong) AS grade,
      -- Composite score, design doc section 13.
      --   base : logistic on ln(weighted_closing / rank). Equal ranks give 50.
      --   +/-  : data depth, home-state fit, branch/state preference, trend.
      -- Clamped to 0..100 so the UI can render it as a bar with no special cases.
      LEAST(100, GREATEST(0,
          (100.0 / (1 + exp(-3.0 * ln(GREATEST(c.wcr, 1)::DOUBLE PRECISION / p_rank))))::NUMERIC
        + CASE WHEN c.years_available >= 3 THEN 3 ELSE -5 END
        + CASE WHEN q2.requires_home_state_match THEN 4 ELSE 0 END
        + CASE WHEN p_branch_ids IS NOT NULL AND c.branch_id = ANY (p_branch_ids) THEN 5 ELSE 0 END
        + CASE WHEN p_state_ids  IS NOT NULL AND c.college_state_id = ANY (p_state_ids) THEN 3 ELSE 0 END
        -- Cutoff tightening year on year: shade the score down.
        + CASE WHEN c.trend_slope IS NOT NULL AND c.trend_slope < 0 THEN -3 ELSE 0 END
      ))::NUMERIC(6,2) AS score,
      c.wcr                AS weighted_closing_rank,
      c.best_closing_rank,
      c.worst_closing_rank,
      c.latest_closing_rank,
      (c.wcr - p_rank)     AS rank_margin,
      c.years_available,
      c.trend_slope,
      c.cutoff_history
    FROM candidate c
    JOIN quotas q2 ON q2.id = c.quota_id
    WHERE c.wcr IS NOT NULL
      -- Drop anything far outside reach; keeps the result set useful and bounded.
      AND p_rank <= c.worst_closing_rank * v_profile.borderline_factor
  )
  SELECT
    g.college_branch_id,
    g.college_id,
    g.branch_id,
    g.counselling_authority_id,
    g.seat_type_id,
    g.quota_id,
    g.gender_id,
    g.grade,
    g.score,
    g.weighted_closing_rank,
    g.best_closing_rank,
    g.worst_closing_rank,
    g.latest_closing_rank,
    g.rank_margin,
    g.years_available,
    g.trend_slope,
    g.cutoff_history
  FROM graded g
  -- Best reachable programme first.
  --
  -- Ordering by score DESC put the SAFEST rows on top, which is backwards: a
  -- rank-45000 student saw the least competitive colleges first and had to
  -- scroll to find anything they actually wanted. The weighted closing rank is
  -- a direct proxy for how sought-after a programme is, so ascending puts the
  -- best option the student can realistically reach at the top. The grade is
  -- still returned on every row, and the client renders it as a risk badge.
  ORDER BY
    g.weighted_closing_rank ASC NULLS LAST,
    g.score DESC
  LIMIT p_limit;
END;
$fn$;

COMMENT ON FUNCTION fn_predict_colleges IS
  'Historical-match engine. Returns bands, never a guarantee. Ordered best-reachable-first. See docs/04-prediction-engine.md.';

COMMIT;
