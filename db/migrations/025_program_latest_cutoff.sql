-- =============================================================================
-- 025_program_latest_cutoff.sql
-- One relation the screens can read without knowing which engine a programme
-- belongs to.
--
-- The college list, the college detail page, the compare table and the saved
-- shortlist all want the same small fact: what did this programme close at most
-- recently, and in which year. All four ask mv_program_cutoff_trend, which is
-- rank-only -- so a BITS programme shows a blank on every one of them although
-- ten years of its cut-offs are loaded.
--
-- Widening four hand-written LATERAL joins into four hand-written UNIONs would
-- put the same mistake in four places. This puts it in one, and makes the thing
-- the callers were silently assuming -- that a cut-off is a rank -- into a
-- column they have to read.
-- =============================================================================

BEGIN;

CREATE VIEW v_program_latest_cutoff AS
SELECT
  t.counselling_authority_id,
  t.exam_id,
  t.college_branch_id,
  t.college_id,
  t.branch_id,
  t.seat_type_id,
  t.category_id,
  t.quota_id,
  t.gender_id,
  'rank'::TEXT                     AS measure,
  t.latest_closing_rank::NUMERIC   AS latest_closing,
  -- A rank is out of nothing. Only a score has a total.
  NULL::NUMERIC                    AS latest_max_score,
  t.latest_year,
  t.years_available,
  t.trend_slope
FROM mv_program_cutoff_trend t

UNION ALL

SELECT
  s.counselling_authority_id,
  s.exam_id,
  s.college_branch_id,
  s.college_id,
  s.branch_id,
  s.seat_type_id,
  s.category_id,
  s.quota_id,
  s.gender_id,
  'score'::TEXT                    AS measure,
  s.latest_closing_score           AS latest_closing,
  s.latest_max_score,
  s.latest_year,
  s.years_available,
  s.trend_slope
FROM mv_program_score_trend s;

COMMENT ON VIEW v_program_latest_cutoff IS
  'Latest published cut-off per programme and seat, across both measures. Read `measure` before comparing two rows: a rank sorts ascending and a score descending, and `latest_max_score` is the paper total a score is out of.';

COMMENT ON COLUMN v_program_latest_cutoff.latest_closing IS
  'A rank when measure = rank, a score out of latest_max_score when measure = score. Never compare the two as one number.';

COMMIT;
