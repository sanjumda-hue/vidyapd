-- =============================================================================
-- 030_apply_college_states.sql
-- Put the JoSAA colleges in the states they are actually in.
--
-- See db/seeds/020_josaa_college_states.sql for how they ended up in Delhi:
-- the resolver fills state_id from the counselling authority's own state, and
-- JoSAA is national, so the fallback took the first row of `states` for all
-- 144 colleges it created.
--
-- The cost was not cosmetic. fn_predict_colleges decides home-state quota
-- eligibility by comparing the candidate's state to the COLLEGE's state, so
-- 70,527 HS-quota rows sat behind the wrong door: Delhi candidates were shown
-- home-state seats at SVNIT Surat and NIT Durgapur, and the Gujarat and Bengal
-- students those seats belong to were not.
--
-- Fails loudly rather than skipping. If a name in the seed matches nothing --
-- because a feed renamed a college, say -- this raises instead of leaving that
-- college quietly in Delhi, which is the failure mode being fixed.
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_unmatched TEXT;
  v_moved     INT;
BEGIN
  SELECT string_agg(k.college_name, E'\n  ')
    INTO v_unmatched
  FROM college_state_corrections k
  WHERE NOT EXISTS (SELECT 1 FROM colleges c WHERE c.name = k.college_name);

  IF v_unmatched IS NOT NULL THEN
    RAISE EXCEPTION 'college_state_corrections names no college in the master:%s%s',
      E'\n  ', v_unmatched;
  END IF;

  UPDATE colleges c
  SET state_id = s.id
  FROM college_state_corrections k
  JOIN states s ON s.code = k.state_code
  WHERE c.name = k.college_name
    AND c.state_id IS DISTINCT FROM s.id;

  GET DIAGNOSTICS v_moved = ROW_COUNT;
  RAISE NOTICE 'college states corrected: %', v_moved;
END
$$;

COMMIT;
