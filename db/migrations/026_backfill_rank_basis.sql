-- =============================================================================
-- 026_backfill_rank_basis.sql
-- Repair rank_basis on rows imported before the publisher started setting it.
--
-- cutoff_data.rank_basis defaults to 'category_rank', and the publisher never
-- overrode it -- it simply let the default stand. That was invisible while
-- every loaded authority really did allot on a category rank, and wrong the
-- moment one did not:
--
--   WBJEEB   15,870 rows  process says state_merit, rows say category_rank
--   UPTAC     9,880 rows  same
--   COMEDK      582 rows  same
--
-- The column exists so that a state merit rank is never compared against a
-- category rank by accident, so leaving 26,332 rows mislabelled defeats the
-- point of having it. The publisher now writes it from the process (BITS forced
-- the issue: its rows are scores), and this fixes what is already stored.
--
-- Everything is derived from counselling_processes, which has been right all
-- along -- no row is guessed at.
-- =============================================================================

BEGIN;

UPDATE cutoff_data cd
SET rank_basis = cp.rank_basis
FROM counselling_processes cp
WHERE cp.id = cd.counselling_process_id
  AND cd.rank_basis IS DISTINCT FROM cp.rank_basis;

COMMIT;
