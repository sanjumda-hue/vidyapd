-- =============================================================================
-- 023_prediction_marks.sql
-- A marks path for the prediction engine.
--
-- Everything built so far assumes lower is better. mv_program_cutoff_trend
-- filters on `closing_rank IS NOT NULL`, fn_weighted_rank returns a BIGINT
-- rank, fn_grade_match asks "is p_rank <= the cut-off", and fn_predict_colleges
-- takes p_rank BIGINT. BITSAT breaks every one of those: it publishes a SCORE,
-- and a higher score is a better result.
--
-- Two ways to do this. Generalise the rank view to carry a signed measure, or
-- add a parallel score view. This takes the second: the rank path carries
-- 327,965 rows across five authorities and works, and rewriting its view to
-- accommodate 402 BITSAT rows would put all of that at risk for no gain.
--
-- The comparison that matters is NOT the raw score. The BITSAT paper total went
-- from 450 to 390 in 2022, so 306/450 (68.0%) and 226/390 (57.9%) are not the
-- same standard even though the raw numbers look close, and the 2021->2022 drop
-- is mostly the paper shrinking. Everything here therefore works in PERCENT OF
-- THE PAPER TOTAL, and converts back to the candidate's own total on the way
-- out so the figures they see are in the units they typed.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- fn_weighted_score -- the score-space twin of fn_weighted_rank.
-- Same recency weighting, but NUMERIC throughout: rounding a percentage to a
-- BIGINT would throw away the fraction that separates two programmes.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_weighted_score(
  y0 NUMERIC, y1 NUMERIC, y2 NUMERIC, y3 NUMERIC, y4 NUMERIC,
  w0 NUMERIC, w1 NUMERIC, w2 NUMERIC, w3 NUMERIC, w4 NUMERIC
) RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $fn$
  SELECT CASE WHEN s.wsum = 0 THEN NULL
              ELSE round(s.vsum / s.wsum, 4)
         END
  FROM (
    SELECT
      coalesce(y0 * w0, 0) + coalesce(y1 * w1, 0) + coalesce(y2 * w2, 0)
        + coalesce(y3 * w3, 0) + coalesce(y4 * w4, 0)                       AS vsum,
      (CASE WHEN y0 IS NULL THEN 0 ELSE w0 END)
        + (CASE WHEN y1 IS NULL THEN 0 ELSE w1 END)
        + (CASE WHEN y2 IS NULL THEN 0 ELSE w2 END)
        + (CASE WHEN y3 IS NULL THEN 0 ELSE w3 END)
        + (CASE WHEN y4 IS NULL THEN 0 ELSE w4 END)                         AS wsum
  ) s;
$fn$;

-- -----------------------------------------------------------------------------
-- fn_grade_score_match
--
-- The mirror of fn_grade_match: where the rank version MULTIPLIES a cut-off by
-- a factor below 1 to demand a better rank, this DIVIDES by the same factor to
-- demand a higher score. One profile therefore tunes both engines and they stay
-- in step.
--
-- The one place the mirror does not hold: a rank has no ceiling, so "10% better
-- than the strictest year" is always reachable, while a percentage stops at
-- 100. Clamping there is deliberate -- at a cut-off of 95% the strong band
-- becomes "a perfect paper", which is the honest answer, not an unreachable
-- 105%.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_grade_score_match(
  p_pct                  NUMERIC,   -- candidate, as a percent of the paper total
  p_weighted_pct         NUMERIC,
  p_toughest_pct         NUMERIC,   -- strictest year (HIGHEST cut-off)
  p_easiest_pct          NUMERIC,   -- most lenient year (LOWEST cut-off)
  p_years_available      SMALLINT,
  p_strong_factor        NUMERIC,
  p_borderline_factor    NUMERIC,
  p_min_years_for_strong SMALLINT
) RETURNS match_grade
LANGUAGE sql
IMMUTABLE
AS $fn$
  SELECT CASE
    WHEN p_weighted_pct IS NULL THEN 'outside_historical_range'::match_grade
    WHEN p_pct >= LEAST(p_toughest_pct / p_strong_factor, 100)
         AND p_years_available >= p_min_years_for_strong
      THEN 'strong_historical_match'::match_grade
    WHEN p_pct >= p_weighted_pct
      THEN 'historical_match'::match_grade
    WHEN p_pct >= p_easiest_pct / p_borderline_factor
      THEN 'borderline'::match_grade
    ELSE 'outside_historical_range'::match_grade
  END;
$fn$;

COMMIT;

-- -----------------------------------------------------------------------------
-- mv_program_score_trend
--
-- Same shape and same keys as mv_program_cutoff_trend, over score-based rows.
-- max_score is NOT NULL for any row carrying a closing_score -- see
-- chk_cutoff_score_needs_max in 021 -- so the percentage below can never divide
-- by a missing total.
-- -----------------------------------------------------------------------------
BEGIN;

CREATE MATERIALIZED VIEW mv_program_score_trend AS
WITH ref AS (
  SELECT cp.counselling_authority_id,
         max(c.academic_year) AS ref_year
  FROM cutoff_data c
  JOIN counselling_processes cp ON cp.id = c.counselling_process_id
  WHERE c.closing_score IS NOT NULL
  GROUP BY cp.counselling_authority_id
),
final_round AS (
  SELECT DISTINCT ON (c.academic_year, c.counselling_process_id, c.college_branch_id,
                      c.seat_type_id, c.quota_id, c.gender_id)
         c.academic_year,
         cp.counselling_authority_id,
         c.exam_id,
         c.college_branch_id,
         c.college_id,
         c.branch_id,
         c.seat_type_id,
         c.category_id,
         c.quota_id,
         c.gender_id,
         c.round_no,
         c.opening_score,
         c.closing_score,
         c.max_score,
         round(c.closing_score / c.max_score * 100, 4) AS closing_pct
  FROM cutoff_data c
  JOIN counselling_processes cp ON cp.id = c.counselling_process_id
  WHERE c.closing_score IS NOT NULL
    AND c.max_score > 0
    AND NOT c.is_preparatory
  ORDER BY c.academic_year, c.counselling_process_id, c.college_branch_id,
           c.seat_type_id, c.quota_id, c.gender_id,
           c.round_no DESC
),
windowed AS (
  SELECT fr.*,
         r.ref_year,
         (r.ref_year - fr.academic_year) AS year_offset
  FROM final_round fr
  JOIN ref r ON r.counselling_authority_id = fr.counselling_authority_id
  WHERE r.ref_year - fr.academic_year BETWEEN 0 AND 4
)
SELECT
  w.counselling_authority_id,
  w.exam_id,
  w.college_branch_id,
  w.college_id,
  w.branch_id,
  w.seat_type_id,
  w.category_id,
  w.quota_id,
  w.gender_id,
  max(w.ref_year)::SMALLINT                                     AS ref_year,

  max(w.closing_pct) FILTER (WHERE w.year_offset = 0)           AS closing_pct_y0,
  max(w.closing_pct) FILTER (WHERE w.year_offset = 1)           AS closing_pct_y1,
  max(w.closing_pct) FILTER (WHERE w.year_offset = 2)           AS closing_pct_y2,
  max(w.closing_pct) FILTER (WHERE w.year_offset = 3)           AS closing_pct_y3,
  max(w.closing_pct) FILTER (WHERE w.year_offset = 4)           AS closing_pct_y4,

  -- Named for what they mean, not for their arithmetic: the toughest year is
  -- the one with the HIGHEST cut-off. Calling that "best" the way the rank view
  -- does would invert on a reader halfway through a query.
  max(w.closing_pct)                                            AS toughest_pct,
  min(w.closing_pct)                                            AS easiest_pct,
  (array_agg(w.closing_pct   ORDER BY w.academic_year DESC))[1] AS latest_pct,
  (array_agg(w.closing_score ORDER BY w.academic_year DESC))[1] AS latest_closing_score,
  (array_agg(w.max_score     ORDER BY w.academic_year DESC))[1] AS latest_max_score,
  max(w.academic_year)::SMALLINT                                AS latest_year,
  count(*)::SMALLINT                                            AS years_available,
  -- Sign is the opposite of the rank view's: a POSITIVE slope means the cut-off
  -- is climbing, which is admission getting harder.
  regr_slope(w.closing_pct::DOUBLE PRECISION,
             w.academic_year::DOUBLE PRECISION)::NUMERIC(12,4)  AS trend_slope,

  -- Raw score and total are both kept: a candidate reads "226 out of 390", not
  -- a percentage, and the paper total is the only thing that makes the older
  -- years in this history intelligible.
  jsonb_object_agg(
    w.academic_year::TEXT,
    jsonb_build_object('opening', w.opening_score,
                       'closing', w.closing_score,
                       'max',     w.max_score,
                       'pct',     w.closing_pct,
                       'round',   w.round_no)
  )                                                             AS cutoff_history
FROM windowed w
GROUP BY w.counselling_authority_id, w.exam_id, w.college_branch_id, w.college_id,
         w.branch_id, w.seat_type_id, w.category_id, w.quota_id, w.gender_id;

CREATE UNIQUE INDEX uq_mv_score_trend ON mv_program_score_trend (
  counselling_authority_id, exam_id, college_branch_id,
  seat_type_id, quota_id, gender_id
);

CREATE INDEX idx_mv_score_trend_predict ON mv_program_score_trend (
  exam_id, seat_type_id, quota_id, gender_id, closing_pct_y0
);
CREATE INDEX idx_mv_score_trend_program ON mv_program_score_trend (college_branch_id);
CREATE INDEX idx_mv_score_trend_college ON mv_program_score_trend (college_id, branch_id);

COMMENT ON MATERIALIZED VIEW mv_program_score_trend IS
  'Recency window for score-based authorities, in percent of the paper total so years with different totals stay comparable. Rank-based rows live in mv_program_cutoff_trend.';

COMMIT;

-- -----------------------------------------------------------------------------
-- fn_predict_colleges_by_score
--
-- Argument for argument the same as fn_predict_colleges, except that the
-- candidate gives a score AND the total it is out of. Both are required: a
-- score without its total cannot be placed against this history at all.
-- -----------------------------------------------------------------------------
BEGIN;

CREATE OR REPLACE FUNCTION fn_predict_colleges_by_score(
  p_exam_id          SMALLINT,
  p_score            NUMERIC,
  p_max_score        NUMERIC,
  p_category_id      SMALLINT,
  p_applicant_gender applicant_gender,
  p_is_pwd           BOOLEAN        DEFAULT false,
  p_home_state_id    SMALLINT       DEFAULT NULL,
  p_branch_ids       SMALLINT[]     DEFAULT NULL,
  p_state_ids        SMALLINT[]     DEFAULT NULL,
  p_college_types    college_type[] DEFAULT NULL,
  p_profile_code     TEXT           DEFAULT 'default',
  p_limit            INT            DEFAULT 200,
  p_include_declared_quotas BOOLEAN DEFAULT false
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
  score                    NUMERIC,   -- the 0-100 composite, as in the rank engine
  -- Every figure below is expressed out of the candidate's own paper total, so
  -- it can sit next to the number they entered without a conversion in the app.
  weighted_closing_score   NUMERIC,
  toughest_closing_score   NUMERIC,
  easiest_closing_score    NUMERIC,
  latest_closing_score     NUMERIC,
  max_score                NUMERIC,
  score_margin             NUMERIC,
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
  v_pct NUMERIC;
BEGIN
  IF p_score IS NULL OR p_score <= 0 THEN
    RAISE EXCEPTION 'fn_predict_colleges_by_score: score must be positive, got %', p_score;
  END IF;
  IF p_max_score IS NULL OR p_max_score <= 0 THEN
    RAISE EXCEPTION 'fn_predict_colleges_by_score: max_score must be positive, got %', p_max_score;
  END IF;
  IF p_score > p_max_score THEN
    RAISE EXCEPTION 'fn_predict_colleges_by_score: score % is above the paper total %', p_score, p_max_score;
  END IF;

  v_pct := p_score / p_max_score * 100;

  SELECT * INTO v_profile
  FROM prediction_weight_profiles
  WHERE code = p_profile_code;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'fn_predict_colleges_by_score: unknown weight profile %', p_profile_code;
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
      t.toughest_pct,
      t.easiest_pct,
      t.latest_pct,
      t.years_available,
      t.trend_slope,
      t.cutoff_history,
      col.state_id AS college_state_id,
      fn_weighted_score(t.closing_pct_y0, t.closing_pct_y1, t.closing_pct_y2,
                        t.closing_pct_y3, t.closing_pct_y4,
                        w0, w1, w2, w3, w4) AS wcp
    FROM mv_program_score_trend t
    JOIN colleges col        ON col.id = t.college_id AND col.is_active
    JOIN college_branches cb ON cb.id = t.college_branch_id AND cb.is_active
    JOIN quotas q            ON q.id = t.quota_id
    WHERE t.exam_id = p_exam_id
      AND t.seat_type_id IN (SELECT id FROM eligible_seat_types)
      AND t.gender_id    IN (SELECT id FROM eligible_genders)
      AND (NOT q.requires_home_state_match
           OR (p_home_state_id IS NOT NULL AND col.state_id = p_home_state_id))
      AND (NOT q.requires_other_state
           OR (p_home_state_id IS NULL OR col.state_id <> p_home_state_id))
      AND (q.home_state_id IS NULL OR q.home_state_id = p_home_state_id)
      AND (NOT q.requires_declaration OR p_include_declared_quotas)
      AND (p_branch_ids    IS NULL OR t.branch_id      = ANY (p_branch_ids))
      AND (p_state_ids     IS NULL OR col.state_id     = ANY (p_state_ids))
      AND (p_college_types IS NULL OR col.college_type = ANY (p_college_types))
  ),
  graded AS (
    SELECT
      c.college_branch_id,
      c.college_id,
      c.branch_id,
      c.counselling_authority_id,
      c.seat_type_id,
      c.quota_id,
      c.gender_id,
      fn_grade_score_match(v_pct, c.wcp, c.toughest_pct, c.easiest_pct,
                           c.years_available, v_profile.strong_match_factor,
                           v_profile.borderline_factor, v_profile.min_years_for_strong) AS grade,
      -- Same logistic as the rank engine, on the ratio of candidate to cut-off,
      -- so equal still gives 50 -- but at a steeper slope. Ranks range over
      -- orders of magnitude, whereas a whole field of cut-offs fits inside
      -- 35%-80% of the paper. At the rank engine's 3.0 the entire BITSAT
      -- spread would compress into roughly 38-60 and every programme would
      -- look alike; 12.0 puts a ten-point gap where a reader expects one.
      LEAST(100, GREATEST(0,
          (100.0 / (1 + exp(-12.0 * ln(v_pct::DOUBLE PRECISION
                                       / GREATEST(c.wcp, 0.01)))))::NUMERIC
        + CASE WHEN c.years_available >= 3 THEN 3 ELSE -5 END
        + CASE WHEN q2.requires_home_state_match THEN 4 ELSE 0 END
        + CASE WHEN p_branch_ids IS NOT NULL AND c.branch_id = ANY (p_branch_ids) THEN 5 ELSE 0 END
        + CASE WHEN p_state_ids  IS NOT NULL AND c.college_state_id = ANY (p_state_ids) THEN 3 ELSE 0 END
        -- Rising cut-off = tightening. The rank view's slope is negative when
        -- that happens; here it is positive.
        + CASE WHEN c.trend_slope IS NOT NULL AND c.trend_slope > 0 THEN -3 ELSE 0 END
      ))::NUMERIC(6,2) AS score,
      round(c.wcp          * p_max_score / 100, 2)  AS weighted_closing_score,
      round(c.toughest_pct * p_max_score / 100, 2)  AS toughest_closing_score,
      round(c.easiest_pct  * p_max_score / 100, 2)  AS easiest_closing_score,
      round(c.latest_pct   * p_max_score / 100, 2)  AS latest_closing_score,
      p_max_score                                   AS max_score,
      round((v_pct - c.wcp) * p_max_score / 100, 2) AS score_margin,
      c.years_available,
      c.trend_slope,
      c.cutoff_history
    FROM candidate c
    JOIN quotas q2 ON q2.id = c.quota_id
    WHERE c.wcp IS NOT NULL
      -- Mirror of the rank engine's reach cut-off: drop anything the candidate
      -- is further below than the borderline factor allows.
      AND v_pct >= c.easiest_pct / v_profile.borderline_factor
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
    g.weighted_closing_score,
    g.toughest_closing_score,
    g.easiest_closing_score,
    g.latest_closing_score,
    g.max_score,
    g.score_margin,
    g.years_available,
    g.trend_slope,
    g.cutoff_history
  FROM graded g
  -- Best reachable programme first, the same correction 015 made to the rank
  -- engine: sorting by the composite score puts the SAFEST rows on top, so a
  -- candidate scoring 300/390 opens the page on B.Pharm and has to scroll past
  -- everything they might actually want. The weighted cut-off is the proxy for
  -- how sought-after a programme is -- DESC here, where the rank engine uses
  -- ASC, because a higher score means harder. The grade rides on every row and
  -- the client renders it as a risk badge.
  ORDER BY
    g.weighted_closing_score DESC NULLS LAST,
    g.score DESC
  LIMIT p_limit;
END;
$fn$;

COMMENT ON FUNCTION fn_predict_colleges_by_score IS
  'Historical-match engine for marks-based admissions (BITSAT). Bands, never a guarantee. Mirror of fn_predict_colleges; see docs/04-prediction-engine.md.';

-- Both views are rebuilt together: an import publishes into one table and the
-- caller has no business knowing which measure its rows carried.
CREATE OR REPLACE FUNCTION fn_refresh_cutoff_trend(p_concurrently BOOLEAN DEFAULT true)
RETURNS void
LANGUAGE plpgsql
AS $fn$
BEGIN
  IF p_concurrently THEN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_program_cutoff_trend;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_program_score_trend;
  ELSE
    REFRESH MATERIALIZED VIEW mv_program_cutoff_trend;
    REFRESH MATERIALIZED VIEW mv_program_score_trend;
  END IF;
END;
$fn$;

COMMIT;
