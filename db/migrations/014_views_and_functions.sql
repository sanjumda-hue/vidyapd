-- =============================================================================
-- 014_views_and_functions.sql
-- The prediction engine, in SQL.
--
-- Two layers, on purpose:
--   1. mv_program_cutoff_trend collapses millions of cutoff rows into ONE row
--      per (authority, exam, program, seat_type, quota, gender), holding the
--      last-round closing rank for each of the five most recent years as fixed
--      columns closing_y0..closing_y4.
--   2. fn_predict_colleges applies the recency WEIGHTS at query time, reading
--      them from prediction_year_weights. Weights therefore stay tunable
--      without rebuilding the view.
--
-- ref_year is computed per counselling AUTHORITY, not globally: COMEDK may have
-- published 2026 before a state authority has, and offset 0 must mean "that
-- authority's newest year" or the weighting silently skews.
-- =============================================================================

BEGIN;

CREATE MATERIALIZED VIEW mv_program_cutoff_trend AS
WITH ref AS (
  SELECT cp.counselling_authority_id,
         max(c.academic_year) AS ref_year
  FROM cutoff_data c
  JOIN counselling_processes cp ON cp.id = c.counselling_process_id
  WHERE c.closing_rank IS NOT NULL
  GROUP BY cp.counselling_authority_id
),
final_round AS (
  -- The closing rank of the LAST published round is the real cutoff for a year.
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
         c.opening_rank,
         c.closing_rank
  FROM cutoff_data c
  JOIN counselling_processes cp ON cp.id = c.counselling_process_id
  WHERE c.closing_rank IS NOT NULL
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
  max(w.ref_year)::SMALLINT                                    AS ref_year,

  max(w.closing_rank) FILTER (WHERE w.year_offset = 0)         AS closing_y0,
  max(w.closing_rank) FILTER (WHERE w.year_offset = 1)         AS closing_y1,
  max(w.closing_rank) FILTER (WHERE w.year_offset = 2)         AS closing_y2,
  max(w.closing_rank) FILTER (WHERE w.year_offset = 3)         AS closing_y3,
  max(w.closing_rank) FILTER (WHERE w.year_offset = 4)         AS closing_y4,

  min(w.closing_rank)                                          AS best_closing_rank,
  max(w.closing_rank)                                          AS worst_closing_rank,
  (array_agg(w.closing_rank ORDER BY w.academic_year DESC))[1] AS latest_closing_rank,
  max(w.academic_year)::SMALLINT                               AS latest_year,
  count(*)::SMALLINT                                           AS years_available,
  -- Negative slope = closing rank falling = admission getting harder.
  regr_slope(w.closing_rank::DOUBLE PRECISION,
             w.academic_year::DOUBLE PRECISION)::NUMERIC(12,2) AS trend_slope,

  jsonb_object_agg(
    w.academic_year::TEXT,
    jsonb_build_object('opening', w.opening_rank,
                       'closing', w.closing_rank,
                       'round',   w.round_no)
  )                                                            AS cutoff_history
FROM windowed w
GROUP BY w.counselling_authority_id, w.exam_id, w.college_branch_id, w.college_id,
         w.branch_id, w.seat_type_id, w.category_id, w.quota_id, w.gender_id;

-- REFRESH CONCURRENTLY requires a unique index.
CREATE UNIQUE INDEX uq_mv_trend ON mv_program_cutoff_trend (
  counselling_authority_id, exam_id, college_branch_id,
  seat_type_id, quota_id, gender_id
);

-- The prediction sweep: filter by exam + eligible dimensions, then by rank.
CREATE INDEX idx_mv_trend_predict ON mv_program_cutoff_trend (
  exam_id, seat_type_id, quota_id, gender_id, closing_y0
);
CREATE INDEX idx_mv_trend_program ON mv_program_cutoff_trend (college_branch_id);
CREATE INDEX idx_mv_trend_college ON mv_program_cutoff_trend (college_id, branch_id);

CREATE OR REPLACE FUNCTION fn_refresh_cutoff_trend(p_concurrently BOOLEAN DEFAULT true)
RETURNS void
LANGUAGE plpgsql
AS $fn$
BEGIN
  IF p_concurrently THEN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_program_cutoff_trend;
  ELSE
    REFRESH MATERIALIZED VIEW mv_program_cutoff_trend;
  END IF;
END;
$fn$;

COMMENT ON FUNCTION fn_refresh_cutoff_trend(BOOLEAN) IS
  'Called at the end of every published cutoff import. Pass false for the first build, when no rows exist yet.';

-- -----------------------------------------------------------------------------
-- fn_weighted_rank
-- Recency-weighted closing rank. Missing years drop out of BOTH numerator and
-- denominator, so a program with only two years of data is still weighted
-- correctly rather than being pulled toward zero.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_weighted_rank(
  y0 BIGINT, y1 BIGINT, y2 BIGINT, y3 BIGINT, y4 BIGINT,
  w0 NUMERIC, w1 NUMERIC, w2 NUMERIC, w3 NUMERIC, w4 NUMERIC
) RETURNS BIGINT
LANGUAGE sql
IMMUTABLE
AS $fn$
  SELECT CASE WHEN s.wsum = 0 THEN NULL
              ELSE round(s.vsum / s.wsum)::BIGINT
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
-- fn_grade_match -- design doc section 14.
-- There is no "you will get in" band. The wording of every band is about
-- historical data, and the enum has no value that claims otherwise.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_grade_match(
  p_rank                 BIGINT,
  p_weighted_closing     BIGINT,
  p_best_closing         BIGINT,   -- strictest year (smallest closing rank)
  p_worst_closing        BIGINT,   -- most lenient year
  p_years_available      SMALLINT,
  p_strong_factor        NUMERIC,
  p_borderline_factor    NUMERIC,
  p_min_years_for_strong SMALLINT
) RETURNS match_grade
LANGUAGE sql
IMMUTABLE
AS $fn$
  SELECT CASE
    WHEN p_weighted_closing IS NULL THEN 'outside_historical_range'::match_grade
    -- Better than even the strictest year, with margin, and enough history.
    WHEN p_rank <= p_best_closing * p_strong_factor
         AND p_years_available >= p_min_years_for_strong
      THEN 'strong_historical_match'::match_grade
    WHEN p_rank <= p_weighted_closing
      THEN 'historical_match'::match_grade
    WHEN p_rank <= p_worst_closing * p_borderline_factor
      THEN 'borderline'::match_grade
    ELSE 'outside_historical_range'::match_grade
  END;
$fn$;

-- -----------------------------------------------------------------------------
-- fn_predict_colleges
--
-- Eligibility, not just rank comparison:
--   seat types -- the candidate's own category PLUS the OPEN pool, because a
--                 reserved candidate is always also considered for OPEN seats.
--                 PwD variants only when the candidate is PwD.
--   genders    -- driven by genders.allowed_applicant_genders, so a female
--                 candidate sees both the neutral and the female-only pool.
--   quotas     -- HS only where the college sits in the candidate's home state,
--                 OS only where it does not. Driven by the quota flags, so a
--                 new state authority needs seed rows, not code.
-- -----------------------------------------------------------------------------
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
  ORDER BY
    CASE g.grade
      WHEN 'strong_historical_match' THEN 1
      WHEN 'historical_match'        THEN 2
      WHEN 'borderline'              THEN 3
      ELSE 4
    END,
    g.score DESC,
    g.weighted_closing_rank DESC
  LIMIT p_limit;
END;
$fn$;

COMMENT ON FUNCTION fn_predict_colleges IS
  'Historical-match engine. Returns bands, never a guarantee. See docs/04-prediction-engine.md.';

-- -----------------------------------------------------------------------------
-- fn_percentile_to_rank -- design doc section 15.
--
-- Resolution order, strictest first:
--   1. An official published pair for this exam/year/session/category.
--   2. Linear interpolation between the two nearest official pairs.
--   3. appeared_candidates * (100 - percentile) / 100 from exam_rank_data.
-- Only step 1 returns is_official = true. Steps 2 and 3 MUST be surfaced to the
-- student as an estimate; the API layer reads `method` to decide the label.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_percentile_to_rank(
  p_exam_id     SMALLINT,
  p_year        SMALLINT,
  p_percentile  NUMERIC,
  p_category_id SMALLINT DEFAULT NULL,
  p_session_id  INT      DEFAULT NULL
)
RETURNS TABLE (
  rank_from   BIGINT,
  rank_to     BIGINT,
  is_official BOOLEAN,
  method      TEXT
)
LANGUAGE plpgsql
STABLE
AS $fn$
#variable_conflict use_column
DECLARE
  v_lo       percentile_rank_mapping%ROWTYPE;  -- next official pair BELOW p_percentile
  v_hi       percentile_rank_mapping%ROWTYPE;  -- next official pair ABOVE p_percentile
  v_appeared INT;
  v_frac     NUMERIC;
BEGIN
  IF p_percentile IS NULL OR p_percentile < 0 OR p_percentile > 100 THEN
    RAISE EXCEPTION 'fn_percentile_to_rank: percentile must be between 0 and 100, got %', p_percentile;
  END IF;

  -- 1. Exact published pair.
  RETURN QUERY
  SELECT m.rank_from, m.rank_to, m.is_official, m.estimation_method
  FROM percentile_rank_mapping m
  WHERE m.exam_id = p_exam_id
    AND m.academic_year = p_year
    AND m.percentile = p_percentile
    AND (p_session_id  IS NULL OR m.exam_session_id IS NOT DISTINCT FROM p_session_id)
    AND (p_category_id IS NULL OR m.category_id     IS NOT DISTINCT FROM p_category_id)
  ORDER BY m.is_official DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN;
  END IF;

  -- 2. Interpolate between bracketing official pairs.
  SELECT * INTO v_hi
  FROM percentile_rank_mapping m
  WHERE m.exam_id = p_exam_id AND m.academic_year = p_year
    AND m.is_official AND m.percentile > p_percentile
    AND (p_category_id IS NULL OR m.category_id IS NOT DISTINCT FROM p_category_id)
  ORDER BY m.percentile ASC
  LIMIT 1;

  SELECT * INTO v_lo
  FROM percentile_rank_mapping m
  WHERE m.exam_id = p_exam_id AND m.academic_year = p_year
    AND m.is_official AND m.percentile < p_percentile
    AND (p_category_id IS NULL OR m.category_id IS NOT DISTINCT FROM p_category_id)
  ORDER BY m.percentile DESC
  LIMIT 1;

  IF v_lo.id IS NOT NULL AND v_hi.id IS NOT NULL THEN
    -- Higher percentile => better (smaller) rank, so we walk from hi down to lo.
    v_frac := (v_hi.percentile - p_percentile) / NULLIF(v_hi.percentile - v_lo.percentile, 0);
    RETURN QUERY SELECT
      round(v_hi.rank_from + v_frac * (v_lo.rank_from - v_hi.rank_from))::BIGINT,
      round(v_hi.rank_to   + v_frac * (v_lo.rank_to   - v_hi.rank_to))::BIGINT,
      false,
      'interpolated_between_official'::TEXT;
    RETURN;
  END IF;

  -- 3. Candidate-count fallback, +/- 3% band to avoid false precision.
  SELECT e.appeared_candidates INTO v_appeared
  FROM exam_rank_data e
  WHERE e.exam_id = p_exam_id
    AND e.academic_year = p_year
    AND e.category_id IS NULL
    AND e.appeared_candidates IS NOT NULL
  ORDER BY e.exam_session_id NULLS FIRST
  LIMIT 1;

  IF v_appeared IS NOT NULL THEN
    RETURN QUERY SELECT
      GREATEST(1, floor(v_appeared * (100 - p_percentile) / 100 * 0.97))::BIGINT,
      GREATEST(1, ceil (v_appeared * (100 - p_percentile) / 100 * 1.03))::BIGINT,
      false,
      'candidate_count_linear'::TEXT;
    RETURN;
  END IF;

  -- Nothing to go on. Returning no rows is correct: the API then tells the
  -- student we cannot convert their percentile rather than inventing a rank.
  RETURN;
END;
$fn$;

-- -----------------------------------------------------------------------------
-- fn_sync_nirf_latest
-- Refreshes the denormalised colleges.nirf_rank_latest columns used for sorting
-- college lists. Run after any NIRF import.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_sync_nirf_latest()
RETURNS INT
LANGUAGE plpgsql
AS $fn$
DECLARE
  v_updated INT;
BEGIN
  WITH latest AS (
    SELECT DISTINCT ON (a.college_id)
           a.college_id, a.rank_value, a.academic_year
    FROM college_accreditations a
    WHERE a.kind = 'NIRF'
      AND a.rank_value IS NOT NULL
      AND (a.category IS NULL OR a.category = 'Engineering')
    ORDER BY a.college_id, a.academic_year DESC
  )
  UPDATE colleges c
  SET nirf_rank_latest = l.rank_value,
      nirf_year_latest = l.academic_year
  FROM latest l
  WHERE c.id = l.college_id
    AND (c.nirf_rank_latest IS DISTINCT FROM l.rank_value
         OR c.nirf_year_latest IS DISTINCT FROM l.academic_year);

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$fn$;

-- -----------------------------------------------------------------------------
-- v_exam_calendar
-- Flattened feed for the month grid. Kept as a plain view because the calendar
-- is small and must never lag behind an admin edit.
-- -----------------------------------------------------------------------------
CREATE VIEW v_exam_calendar AS
SELECT
  s.id            AS schedule_id,
  s.academic_year,
  e.id            AS exam_id,
  e.code          AS exam_code,
  e.name          AS exam_name,
  e.short_name    AS exam_short_name,
  e.level         AS exam_level,
  e.logo_url,
  st.code         AS home_state_code,
  ses.session_no,
  ses.name        AS session_name,
  s.event_type,
  s.event_name,
  s.start_date,
  s.end_date,
  s.start_at,
  s.end_at,
  s.is_tentative,
  coalesce(s.detail_url, e.official_website) AS detail_url,
  s.notes
FROM exam_schedules s
JOIN exams e            ON e.id = s.exam_id AND e.is_active
LEFT JOIN exam_sessions ses ON ses.id = s.exam_session_id
LEFT JOIN states st     ON st.id = e.home_state_id;

-- -----------------------------------------------------------------------------
-- v_program_summary
-- One row per program with everything the college/compare screens need, so the
-- API does not hand-assemble a six-way join on every request.
-- -----------------------------------------------------------------------------
CREATE VIEW v_program_summary AS
SELECT
  cb.id                AS college_branch_id,
  cb.program_name,
  cb.degree,
  cb.duration_years,
  cb.total_intake,
  c.id                 AS college_id,
  c.name               AS college_name,
  c.short_name         AS college_short_name,
  c.slug               AS college_slug,
  c.college_type,
  c.ownership,
  c.nirf_rank_latest,
  c.has_hostel,
  st.id                AS state_id,
  st.name              AS state_name,
  ct.name              AS city_name,
  b.id                 AS branch_id,
  b.code               AS branch_code,
  b.name               AS branch_name,
  sp.id                AS specialization_id,
  sp.name              AS specialization_name,
  f.tuition_fee_annual,
  f.academic_year      AS fee_year,
  p.average_package,
  p.highest_package,
  p.placement_percentage,
  p.academic_year      AS placement_year
FROM college_branches cb
JOIN colleges c        ON c.id = cb.college_id
JOIN states st         ON st.id = c.state_id
LEFT JOIN cities ct    ON ct.id = c.city_id
JOIN branches b        ON b.id = cb.branch_id
LEFT JOIN specializations sp ON sp.id = cb.specialization_id
LEFT JOIN LATERAL (
  SELECT cf.tuition_fee_annual, cf.academic_year
  FROM college_fees cf
  WHERE cf.college_id = c.id
    AND (cf.college_branch_id = cb.id OR cf.college_branch_id IS NULL)
  ORDER BY cf.academic_year DESC, cf.college_branch_id NULLS LAST
  LIMIT 1
) f ON true
LEFT JOIN LATERAL (
  SELECT pd.average_package, pd.highest_package, pd.placement_percentage, pd.academic_year
  FROM placement_data pd
  WHERE pd.college_id = c.id
    AND (pd.college_branch_id = cb.id OR pd.college_branch_id IS NULL)
  ORDER BY pd.academic_year DESC, pd.college_branch_id NULLS LAST
  LIMIT 1
) p ON true
WHERE cb.is_active AND c.is_active;

COMMIT;
