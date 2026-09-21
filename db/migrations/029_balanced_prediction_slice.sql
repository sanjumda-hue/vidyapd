-- =============================================================================
-- 029_balanced_prediction_slice.sql
-- Return a slice that spans the bands, and report what was left out.
--
-- 015 made the engine order best-reachable first, which is right. LIMIT then
-- takes the top N of that order -- and the top of "most competitive" is the
-- riskiest end of the list. For a Delhi candidate at rank 45,821:
--
--   really available   811 strong  ·  518 historical  ·  119 borderline
--   app showed (100)     0 strong  ·    0 historical  ·  100 borderline
--
-- Seven percent of the results, all of it stretches, under a summary reading
-- "100 Borderline". A student with 811 comfortable options was being told they
-- had none. Raising the limit only moves the cliff; 1,448 rows is not
-- something to send either.
--
-- So: take a fair share of each band and keep the same best-first order across
-- the whole slice. band_total carries the true size of each band, so the
-- counts a student sees describe everything that matched rather than only what
-- fitted in the response.
--
-- Written as wrappers rather than by restating fn_predict_colleges and
-- fn_predict_colleges_by_score. Those are ~150 lines each of eligibility and
-- grading rules that are correct and hard-won, and retyping them to change a
-- LIMIT is how a transcription error gets into the middle of them. The inner
-- call costs nothing extra: the existing function already computes every
-- matching row and sorts it before its own LIMIT applies.
-- =============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION fn_predict_colleges_banded(
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
  score                    NUMERIC,
  weighted_closing_rank    BIGINT,
  best_closing_rank        BIGINT,
  worst_closing_rank       BIGINT,
  latest_closing_rank      BIGINT,
  rank_margin              BIGINT,
  years_available          SMALLINT,
  trend_slope              NUMERIC,
  cutoff_history           JSONB,
  -- How many matched in this row's band, before the slice below.
  band_total               BIGINT
)
LANGUAGE sql
STABLE
AS $fn$
  WITH every_match AS (
    SELECT * FROM fn_predict_colleges(
      p_exam_id, p_rank, p_category_id, p_applicant_gender, p_is_pwd,
      p_home_state_id, p_branch_ids, p_state_ids, p_college_types,
      p_profile_code, 2147483647, p_include_declared_quotas)
  ),
  ranked AS (
    SELECT m.*,
           count(*) OVER (PARTITION BY m.grade) AS band_total,
           row_number() OVER (
             PARTITION BY m.grade
             ORDER BY m.weighted_closing_rank ASC NULLS LAST, m.score DESC
           ) AS in_band
    FROM every_match m
  )
  SELECT r.college_branch_id, r.college_id, r.branch_id, r.counselling_authority_id,
         r.seat_type_id, r.quota_id, r.gender_id, r.grade, r.score,
         r.weighted_closing_rank, r.best_closing_rank, r.worst_closing_rank,
         r.latest_closing_rank, r.rank_margin, r.years_available, r.trend_slope,
         r.cutoff_history, r.band_total
  FROM ranked r
  -- An equal share of each band, rounded up, so a limit of 100 comes back as
  -- roughly 34 from each rather than 100 from one.
  WHERE r.in_band <= GREATEST(1, (p_limit + 2) / 3)
  ORDER BY r.weighted_closing_rank ASC NULLS LAST, r.score DESC;
$fn$;

COMMENT ON FUNCTION fn_predict_colleges_banded IS
  'fn_predict_colleges, sliced across the match bands instead of taking the top N of one. band_total reports the true size of each band.';

CREATE OR REPLACE FUNCTION fn_predict_colleges_by_score_banded(
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
  score                    NUMERIC,
  weighted_closing_score   NUMERIC,
  toughest_closing_score   NUMERIC,
  easiest_closing_score    NUMERIC,
  latest_closing_score     NUMERIC,
  max_score                NUMERIC,
  score_margin             NUMERIC,
  years_available          SMALLINT,
  trend_slope              NUMERIC,
  cutoff_history           JSONB,
  band_total               BIGINT
)
LANGUAGE sql
STABLE
AS $fn$
  WITH every_match AS (
    SELECT * FROM fn_predict_colleges_by_score(
      p_exam_id, p_score, p_max_score, p_category_id, p_applicant_gender, p_is_pwd,
      p_home_state_id, p_branch_ids, p_state_ids, p_college_types,
      p_profile_code, 2147483647, p_include_declared_quotas)
  ),
  ranked AS (
    SELECT m.*,
           count(*) OVER (PARTITION BY m.grade) AS band_total,
           -- Best-first for a score is the HIGHEST cut-off, the mirror of the
           -- rank side.
           row_number() OVER (
             PARTITION BY m.grade
             ORDER BY m.weighted_closing_score DESC NULLS LAST, m.score DESC
           ) AS in_band
    FROM every_match m
  )
  SELECT r.college_branch_id, r.college_id, r.branch_id, r.counselling_authority_id,
         r.seat_type_id, r.quota_id, r.gender_id, r.grade, r.score,
         r.weighted_closing_score, r.toughest_closing_score, r.easiest_closing_score,
         r.latest_closing_score, r.max_score, r.score_margin, r.years_available,
         r.trend_slope, r.cutoff_history, r.band_total
  FROM ranked r
  WHERE r.in_band <= GREATEST(1, (p_limit + 2) / 3)
  ORDER BY r.weighted_closing_score DESC NULLS LAST, r.score DESC;
$fn$;

COMMENT ON FUNCTION fn_predict_colleges_by_score_banded IS
  'fn_predict_colleges_by_score, sliced across the match bands. band_total reports the true size of each band.';

COMMIT;
