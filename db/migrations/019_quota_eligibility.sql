-- =============================================================================
-- 019_quota_eligibility.sql
--
-- Two kinds of quota the schema could not express, both of which were being
-- offered to candidates who cannot use them:
--
--   Goa Quota, Jammu & Kashmir, Ladakh
--       open only to residents of that one state. requires_home_state_match
--       cannot say this: it means "the candidate's state equals the COLLEGE's
--       state", which is not the same thing -- NIT Goa's Goa Quota was being
--       offered to a candidate from Uttar Pradesh.
--
--   DASA (CIWG / non-CIWG), Armed Forces, Freedom Fighter, and CSAB's DC / AD
--       open only to candidates who qualify under a separate scheme and
--       declare it. A domestic candidate should not see them at all.
--
-- Both are eligibility facts about the QUOTA, so they belong here rather than
-- as special cases inside the prediction function.
-- =============================================================================

BEGIN;

ALTER TABLE quotas
  ADD COLUMN IF NOT EXISTS home_state_id SMALLINT REFERENCES states(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS requires_declaration BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN quotas.home_state_id IS
  'Restricts the quota to residents of this one state, independent of where the college is.';
COMMENT ON COLUMN quotas.requires_declaration IS
  'The candidate must qualify under a separate scheme. Excluded from prediction unless explicitly asked for.';

UPDATE quotas SET home_state_id = (SELECT id FROM states WHERE code = 'GA') WHERE code = 'GO';
UPDATE quotas SET home_state_id = (SELECT id FROM states WHERE code = 'JK') WHERE code = 'JK';
UPDATE quotas SET home_state_id = (SELECT id FROM states WHERE code = 'LA') WHERE code = 'LA';
UPDATE quotas SET home_state_id = (SELECT id FROM states WHERE code = 'AP') WHERE code = 'AP';

UPDATE quotas SET requires_declaration = true
WHERE code IN ('AF', 'FF', 'DASA_CIWG', 'DASA_NON_CIWG', 'DC', 'AD');

COMMIT;
