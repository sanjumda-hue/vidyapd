-- =============================================================================
-- 016_program_identity.sql
--
-- A programme is identified by the name the authority prints for it at that
-- college -- not by (college, branch, degree).
--
-- The old index assumed one BTech per branch per college. Real JoSAA data
-- breaks that immediately: IIT Bhubaneswar offers both
--
--   Civil Engineering (4 Years, Bachelor of Technology)
--   Civil Engineering (5 Years, Bachelor and Master of Technology (Dual Degree))
--
-- Both classify as branch CE. They have different cutoffs, so they are
-- different programmes and must be different rows. 254 distinct programme
-- names map onto ~28 branches, so this is the normal case, not an edge case.
-- =============================================================================

BEGIN;

DROP INDEX IF EXISTS uq_college_branch_program;

-- Normalised so "Civil Engineering  (4 Years)" and "civil engineering (4 years)"
-- from two different feeds cannot create duplicate programmes.
CREATE UNIQUE INDEX uq_college_program_name
  ON college_branches (college_id, lower(regexp_replace(program_name, '\s+', ' ', 'g')));

-- branch_id stays a classification, and is still how the predictor filters.
CREATE INDEX IF NOT EXISTS idx_college_branches_branch_lookup
  ON college_branches (college_id, branch_id);

COMMENT ON INDEX uq_college_program_name IS
  'Programme identity = the authority printed name at that college.';

COMMIT;
