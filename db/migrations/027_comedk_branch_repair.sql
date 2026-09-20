-- =============================================================================
-- 027_comedk_branch_repair.sql
-- Re-file the COMEDK programmes that an alias-precedence bug put on the wrong
-- branch.
--
-- EntityResolver.warmUp() builds branchByAlias in layers and the last write
-- wins. The canonical branch codes were written LAST, so they overwrote the
-- authority-scoped aliases that were supposed to beat them:
--
--   COMEDK  CE   means Computer Science  -> was filed as Civil Engineering
--   COMEDK  EE   means Electrical & Electronics -> was filed as Electrical Eng.
--   COMEDK  ECE  means Electrical Engineering   -> was filed as Electronics & Comm.
--
-- CV, CS, EC and CH escaped only because we have no branch whose code spells
-- those, so nothing overwrote them. The ordering is fixed in the resolver; this
-- repairs the 20 programmes and 25 cutoff rows already stored.
--
-- Re-importing would NOT have fixed them. resolveProgram() matches an existing
-- college_branches row by (college, printed name) and returns it as-is, so the
-- stored branch_id is never revisited once the row exists.
--
-- None of the affected programmes is referenced by any other authority, so
-- there is no feed whose meaning this changes.
-- =============================================================================

BEGIN;

CREATE TEMP TABLE comedk_rebranch ON COMMIT DROP AS
SELECT cb.id AS college_branch_id,
       cb.college_id,
       cb.branch_id AS old_branch_id,
       al.branch_id AS new_branch_id
FROM college_branches cb
JOIN branch_aliases al
  ON al.normalized_alias = trim(lower(regexp_replace(cb.program_name, '[^a-zA-Z0-9]+', ' ', 'g')))
 AND al.counselling_authority_id = (SELECT id FROM counselling_authorities WHERE code = 'COMEDK')
WHERE cb.branch_id <> al.branch_id;

-- cutoff_data carries a denormalised branch_id and a composite FK back to
-- college_branches (id, college_id, branch_id). The FK is not deferrable, so
-- the parent cannot be updated while children still point at the old triple:
-- drop it, move both sides, put it back.
ALTER TABLE cutoff_data DROP CONSTRAINT fk_cutoff_program;

UPDATE college_branches cb
SET branch_id = r.new_branch_id
FROM comedk_rebranch r
WHERE cb.id = r.college_branch_id;

UPDATE cutoff_data cd
SET branch_id = r.new_branch_id
FROM comedk_rebranch r
WHERE cd.college_branch_id = r.college_branch_id
  AND cd.branch_id = r.old_branch_id;

ALTER TABLE cutoff_data
  ADD CONSTRAINT fk_cutoff_program
  FOREIGN KEY (college_branch_id, college_id, branch_id)
  REFERENCES college_branches (id, college_id, branch_id) ON DELETE CASCADE;

COMMIT;

-- The trend views key on branch_id, so they are stale until rebuilt.
SELECT fn_refresh_cutoff_trend(false);
