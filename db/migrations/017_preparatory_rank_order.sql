-- =============================================================================
-- 017_preparatory_rank_order.sql
--
-- Preparatory-course seats are ranked on their own list, separate from the
-- main one. JoSAA marks them with a trailing "P":
--
--   Opening Rank = 158    (main list)
--   Closing Rank = 69P    (preparatory list)
--
-- Those two numbers are not comparable, so opening <= closing does not hold
-- and should not be required. The application validator already skips the
-- check for these rows; without the same exemption here the database rejects
-- them and the whole publish fails.
--
-- The constraint still applies in full to every ordinary row.
-- =============================================================================

BEGIN;

ALTER TABLE cutoff_data DROP CONSTRAINT IF EXISTS chk_cutoff_rank_order;

ALTER TABLE cutoff_data ADD CONSTRAINT chk_cutoff_rank_order
  CHECK (
    is_preparatory
    OR opening_rank IS NULL
    OR closing_rank IS NULL
    OR opening_rank <= closing_rank
  );

COMMENT ON CONSTRAINT chk_cutoff_rank_order ON cutoff_data IS
  'Opening must not be worse than closing, except for preparatory seats whose two ranks come from different lists.';

COMMIT;
