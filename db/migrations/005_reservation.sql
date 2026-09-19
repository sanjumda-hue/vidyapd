-- =============================================================================
-- 005_reservation.sql
-- Category / gender / quota / seat-type dimensions.
--
-- Design doc section 9: these are FOUR independent dimensions, not one
-- `category` column. A JoSAA cutoff row is identified by
--   (seat_type, quota, gender) -- e.g. (OBC-NCL-PwD, HS, Female-only).
--
-- `seat_types` is deliberately derived from `categories` + `is_pwd` so the
-- prediction engine can widen from "OBC-NCL-PwD" to "OBC-NCL" to "OPEN"
-- without string parsing.
-- =============================================================================

BEGIN;

CREATE TABLE categories (
  id             SMALLSERIAL PRIMARY KEY,
  code           TEXT        NOT NULL UNIQUE,   -- 'OPEN', 'EWS', 'OBC_NCL', 'SC', 'ST'
  name           TEXT        NOT NULL,
  -- OPEN is the fallback pool every candidate competes in.
  is_open_pool   BOOLEAN     NOT NULL DEFAULT false,
  display_order  SMALLINT    NOT NULL DEFAULT 100,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_categories_open_pool ON categories (is_open_pool) WHERE is_open_pool;

-- -----------------------------------------------------------------------------
-- genders: the SEAT's gender pool, not the applicant's gender.
-- `allowed_applicant_genders` is what makes prediction eligibility a single
-- array containment check instead of branching logic in the API layer.
-- -----------------------------------------------------------------------------
CREATE TABLE genders (
  id                        SMALLSERIAL        PRIMARY KEY,
  code                      TEXT               NOT NULL UNIQUE,  -- 'GENDER_NEUTRAL', 'FEMALE_ONLY'
  name                      TEXT               NOT NULL,
  allowed_applicant_genders applicant_gender[] NOT NULL,
  is_supernumerary          BOOLEAN            NOT NULL DEFAULT false,
  display_order             SMALLINT           NOT NULL DEFAULT 100,
  created_at                TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ        NOT NULL DEFAULT now(),

  CONSTRAINT chk_gender_pool_nonempty CHECK (cardinality(allowed_applicant_genders) > 0)
);

CREATE TRIGGER trg_genders_updated_at
  BEFORE UPDATE ON genders
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- -----------------------------------------------------------------------------
-- quotas: AI / HS / OS / GO / JK / LA ...
-- The two boolean flags below encode the home-state rule so the predictor can
-- filter quotas with a join instead of hardcoding 'HS' anywhere in code.
-- -----------------------------------------------------------------------------
CREATE TABLE quotas (
  id                        SMALLSERIAL PRIMARY KEY,
  code                      TEXT        NOT NULL UNIQUE,  -- 'AI', 'HS', 'OS', 'GO'
  name                      TEXT        NOT NULL,
  requires_home_state_match BOOLEAN     NOT NULL DEFAULT false,  -- HS
  requires_other_state      BOOLEAN     NOT NULL DEFAULT false,  -- OS
  description               TEXT,
  display_order             SMALLINT    NOT NULL DEFAULT 100,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_quota_state_rule CHECK (NOT (requires_home_state_match AND requires_other_state))
);

CREATE TRIGGER trg_quotas_updated_at
  BEFORE UPDATE ON quotas
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- -----------------------------------------------------------------------------
-- seat_types: category x PwD. This is the column JoSAA labels "Seat Type".
-- -----------------------------------------------------------------------------
CREATE TABLE seat_types (
  id             SMALLSERIAL PRIMARY KEY,
  code           TEXT        NOT NULL UNIQUE,   -- 'OPEN', 'OPEN_PWD', 'OBC_NCL_PWD'
  name           TEXT        NOT NULL,          -- 'OBC-NCL (PwD)'
  category_id    SMALLINT    NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  is_pwd         BOOLEAN     NOT NULL DEFAULT false,
  display_order  SMALLINT    NOT NULL DEFAULT 100,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (category_id, is_pwd)
);

CREATE TRIGGER trg_seat_types_updated_at
  BEFORE UPDATE ON seat_types
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- -----------------------------------------------------------------------------
-- counselling_dimension_map
--
-- Design doc section 9, "Important": quota/category names are configurable per
-- counselling authority. KEA prints '3BG' and '2AK'; JoSAA prints 'OBC-NCL' and
-- 'HS'. This table is the single place where an authority's printed label is
-- mapped onto our canonical id -- and it doubles as the scraper's lookup table,
-- so adding a new state counselling means seeding rows here, not writing code.
-- -----------------------------------------------------------------------------
CREATE TABLE counselling_dimension_map (
  id                      SERIAL      PRIMARY KEY,
  counselling_process_id  INT         NOT NULL REFERENCES counselling_processes(id) ON DELETE CASCADE,
  dimension               TEXT        NOT NULL CHECK (dimension IN ('category', 'seat_type', 'quota', 'gender')),
  -- The id inside the table named by `dimension`. Not a real FK because the
  -- target table varies; validated by trigger below.
  ref_id                  SMALLINT    NOT NULL,
  source_label            TEXT        NOT NULL,   -- exactly as the authority prints it
  display_label           TEXT,                   -- what we show students, if different
  display_order           SMALLINT    NOT NULL DEFAULT 100,
  is_active               BOOLEAN     NOT NULL DEFAULT true,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (counselling_process_id, dimension, source_label)
);

CREATE TRIGGER trg_counselling_dimension_map_updated_at
  BEFORE UPDATE ON counselling_dimension_map
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_dimension_map_lookup
  ON counselling_dimension_map (counselling_process_id, dimension, ref_id);

CREATE OR REPLACE FUNCTION app_check_dimension_ref()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
DECLARE
  v_exists BOOLEAN;
BEGIN
  EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE id = $1)',
                 CASE NEW.dimension
                   WHEN 'category'  THEN 'categories'
                   WHEN 'seat_type' THEN 'seat_types'
                   WHEN 'quota'     THEN 'quotas'
                   WHEN 'gender'    THEN 'genders'
                 END)
  INTO v_exists
  USING NEW.ref_id;

  IF NOT v_exists THEN
    RAISE EXCEPTION 'counselling_dimension_map: % id % does not exist', NEW.dimension, NEW.ref_id;
  END IF;

  RETURN NEW;
END;
$fn$;

CREATE TRIGGER trg_dimension_map_ref_check
  BEFORE INSERT OR UPDATE OF dimension, ref_id ON counselling_dimension_map
  FOR EACH ROW EXECUTE FUNCTION app_check_dimension_ref();

COMMIT;
