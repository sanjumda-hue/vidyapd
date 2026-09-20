-- =============================================================================
-- 024_prediction_results_score.sql
-- Let a stored prediction hold a score result.
--
-- prediction_results exists so that a student reopening a saved prediction sees
-- the numbers they screenshotted, not whatever the trend view says today. Its
-- columns are all ranks, so a BITSAT run would persist a row with every measure
-- NULL -- the snapshot would survive and say nothing.
--
-- prediction_requests already anticipated this: input_marks and the 'marks'
-- value of prediction_input_kind have been there since 013. What it lacks is
-- the paper total, without which a stored "300" cannot be read back.
-- =============================================================================

BEGIN;

ALTER TABLE prediction_requests
  ADD COLUMN IF NOT EXISTS resolved_max_score NUMERIC(8,3)
    CHECK (resolved_max_score IS NULL OR resolved_max_score > 0);

COMMENT ON COLUMN prediction_requests.resolved_max_score IS
  'Paper total input_marks was out of. Required to replay a marks run; the BITSAT total changed from 450 to 390 in 2022.';

ALTER TABLE prediction_results
  ADD COLUMN IF NOT EXISTS weighted_closing_score NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS toughest_closing_score NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS easiest_closing_score  NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS latest_closing_score   NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS max_score              NUMERIC(10,2),
  -- candidate score - weighted closing score. Positive = ahead of the
  -- historical cut-off, the same sense as rank_margin.
  ADD COLUMN IF NOT EXISTS score_margin           NUMERIC(10,2);

COMMENT ON COLUMN prediction_results.toughest_closing_score IS
  'Strictest year in the window: the HIGHEST cut-off. The rank side calls its equivalent best_closing_rank, which is the LOWEST.';

-- trend_slope is shared. On a rank row it is places per year and negative means
-- tightening; on a score row it is percentage points of the paper per year and
-- POSITIVE means tightening. Whichever measure a row carries says which.
COMMENT ON COLUMN prediction_results.trend_slope IS
  'Rank rows: closing rank per year, negative = tightening. Score rows: percent of paper total per year, positive = tightening.';

-- NUMERIC(12,2) truncates a score slope of -1.3077 to -1.31, which is fine for
-- ranks and lossy for a figure whose whole range is a few points.
ALTER TABLE prediction_results
  ALTER COLUMN trend_slope TYPE NUMERIC(12,4);

COMMIT;
