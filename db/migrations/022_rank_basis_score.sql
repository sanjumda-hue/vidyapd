-- =============================================================================
-- 022_rank_basis_score.sql
-- Allow 'score' as a rank_basis.
--
-- rank_basis records what the printed number actually IS, so that a category
-- rank is never compared against a CRL. BITS prints neither: it prints a BITSAT
-- score out of the paper total. Without a value for that, a BITS process would
-- have to be mislabelled 'category_rank', which is precisely the kind of quiet
-- mismatch the column exists to prevent.
-- =============================================================================

BEGIN;

ALTER TABLE counselling_processes DROP CONSTRAINT counselling_processes_rank_basis_check;
ALTER TABLE counselling_processes ADD CONSTRAINT counselling_processes_rank_basis_check
  CHECK (rank_basis IN ('crl', 'category_rank', 'state_merit', 'percentile', 'score'));

ALTER TABLE cutoff_data DROP CONSTRAINT cutoff_data_rank_basis_check;
ALTER TABLE cutoff_data ADD CONSTRAINT cutoff_data_rank_basis_check
  CHECK (rank_basis IN ('crl', 'category_rank', 'state_merit', 'percentile', 'score'));

COMMENT ON COLUMN cutoff_data.rank_basis IS
  'What the published number is: a CRL, a category rank, a state merit rank, a percentile, or a raw score out of max_score.';

COMMIT;
