-- =============================================================================
-- 002_geography.sql
-- States / UTs and cities. Home-state quota logic depends on states.id, so this
-- is the first real master table.
-- =============================================================================

BEGIN;

CREATE TABLE states (
  id          SMALLSERIAL PRIMARY KEY,
  code        TEXT        NOT NULL UNIQUE,  -- 'UP', 'KA', 'MH'
  name        TEXT        NOT NULL UNIQUE,
  kind        TEXT        NOT NULL DEFAULT 'state' CHECK (kind IN ('state', 'ut')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_states_updated_at
  BEFORE UPDATE ON states
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

COMMENT ON TABLE states IS
  'States and union territories. Drives home-state (HS) vs other-state (OS) quota resolution.';

CREATE TABLE cities (
  id          SERIAL      PRIMARY KEY,
  state_id    SMALLINT    NOT NULL REFERENCES states(id) ON DELETE RESTRICT,
  name        TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (state_id, name)
);

CREATE TRIGGER trg_cities_updated_at
  BEFORE UPDATE ON cities
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_cities_name_trgm ON cities USING gin (name gin_trgm_ops);

COMMIT;
