-- =============================================================================
-- 018_cutoff_natural_key_exam.sql
--
-- Add exam_id to the cutoff natural key.
--
-- One counselling can allot the same programme from more than one merit list.
-- WBJEEB fills seats from both the WBJEE rank and the JEE (Main) rank, in the
-- same rounds, for the same categories and quotas -- two different rank series
-- and two different closing ranks.
--
-- Without exam_id in the key those rows collide and the second import silently
-- overwrites the first: loading WBJEEB 2023-2026 lost 2,647 of 13,210 valid
-- rows exactly this way. JoSAA never exposed it because its NIT+ and IIT seats
-- are at different institutes, so the programme differs too.
-- =============================================================================

BEGIN;

DROP INDEX IF EXISTS uq_cutoff_natural;

CREATE UNIQUE INDEX uq_cutoff_natural ON cutoff_data (
  academic_year, counselling_process_id, exam_id, round_no,
  college_branch_id, seat_type_id, quota_id, gender_id
);

COMMENT ON INDEX uq_cutoff_natural IS
  'One published cutoff per exam, round, programme and seat dimension. exam_id matters where a counselling allots from several merit lists.';

COMMIT;
