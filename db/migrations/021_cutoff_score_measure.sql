-- =============================================================================
-- 021_cutoff_score_measure.sql
-- Make the score measure usable end to end.
--
-- cutoff_data has carried opening_score/closing_score since 009, but nothing
-- ever wrote to them: every authority so far publishes a rank. BITS does not.
-- It runs its own admissions, has no counselling authority, and publishes a
-- BITSAT cut-off SCORE per programme.
--
-- Two things were missing:
--
--   1. max_score. The BITSAT paper total went from 450 to 390 in 2022, so a
--      raw score is meaningless without the total it was out of. 306/450 and
--      226/390 are the same programme in different years; compared raw, the
--      trend looks like a collapse.
--
--   2. Ordering and positivity checks. Ranks and percentiles both have them;
--      scores had neither, so a corrupted row could pass unnoticed the way the
--      10x decimal ranks nearly did.
--
-- BPharm is added to degree_type for the same import: BITSAT admits to B.Pharm
-- on the same merit list, and dropping those rows would hide the lowest cut-off
-- in the feed -- exactly the one a borderline student needs to see.
-- =============================================================================

-- ALTER TYPE ... ADD VALUE may not be used in the same transaction that adds
-- it, so this stands alone ahead of the table changes.
BEGIN;
ALTER TYPE degree_type ADD VALUE IF NOT EXISTS 'BPharm';
COMMIT;

BEGIN;

ALTER TABLE cutoff_data
  ADD COLUMN IF NOT EXISTS max_score NUMERIC(10,4);

COMMENT ON COLUMN cutoff_data.max_score IS
  'Paper total the score is out of. BITSAT: 450 up to 2021, 390 from 2022. Required for any cross-year comparison of closing_score.';

-- Scores run the same way as percentiles: the closing value is the lower one.
ALTER TABLE cutoff_data
  ADD CONSTRAINT chk_cutoff_score_order
  CHECK (opening_score IS NULL OR closing_score IS NULL OR opening_score >= closing_score);

ALTER TABLE cutoff_data
  ADD CONSTRAINT chk_cutoff_positive_score
  CHECK ((opening_score IS NULL OR opening_score > 0)
     AND (closing_score IS NULL OR closing_score > 0)
     AND (max_score     IS NULL OR max_score     > 0));

-- A score you cannot normalise is a score you cannot compare, so refuse it at
-- write time rather than discovering it in a trend line.
ALTER TABLE cutoff_data
  ADD CONSTRAINT chk_cutoff_score_needs_max
  CHECK (closing_score IS NULL OR max_score IS NOT NULL);

ALTER TABLE cutoff_data
  ADD CONSTRAINT chk_cutoff_score_within_max
  CHECK (max_score IS NULL
         OR ((opening_score IS NULL OR opening_score <= max_score)
         AND (closing_score IS NULL OR closing_score <= max_score)));

COMMIT;
