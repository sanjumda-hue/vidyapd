-- =============================================================================
-- 006_colleges.sql
-- College master, campuses and accreditations/rankings.
-- =============================================================================

BEGIN;

CREATE TABLE colleges (
  id                    SERIAL         PRIMARY KEY,
  slug                  TEXT           NOT NULL UNIQUE,  -- 'iit-bombay'
  name                  TEXT           NOT NULL,
  short_name            TEXT,                            -- 'IIT Bombay'
  -- Codes assigned by outside bodies. Kept nullable because coverage is patchy,
  -- but they are the join key when matching a scraped row to an existing college.
  aicte_code            TEXT,
  aishe_code            TEXT,

  college_type          college_type   NOT NULL,
  ownership             ownership_type NOT NULL,
  affiliated_university TEXT,

  state_id              SMALLINT       NOT NULL REFERENCES states(id) ON DELETE RESTRICT,
  city_id               INT            REFERENCES cities(id) ON DELETE SET NULL,
  address               TEXT,
  pincode               TEXT,
  latitude              NUMERIC(9,6),
  longitude             NUMERIC(9,6),

  website               TEXT,
  email                 TEXT,
  phone                 TEXT,

  established_year      SMALLINT       CHECK (established_year IS NULL OR established_year BETWEEN 1800 AND 2100),
  is_autonomous         BOOLEAN        NOT NULL DEFAULT false,
  has_hostel            BOOLEAN,
  about                 TEXT,
  logo_url              TEXT,
  banner_url            TEXT,

  -- Denormalised copy of the newest NIRF engineering rank, maintained by
  -- 014_views_and_functions.sql. Full history lives in college_accreditations.
  nirf_rank_latest      SMALLINT,
  nirf_year_latest      SMALLINT,

  is_active             BOOLEAN        NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_colleges_updated_at
  BEFORE UPDATE ON colleges
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_colleges_aicte ON colleges (aicte_code) WHERE aicte_code IS NOT NULL;
CREATE UNIQUE INDEX uq_colleges_aishe ON colleges (aishe_code) WHERE aishe_code IS NOT NULL;

CREATE INDEX idx_colleges_state_type ON colleges (state_id, college_type) WHERE is_active;
CREATE INDEX idx_colleges_type       ON colleges (college_type)           WHERE is_active;
CREATE INDEX idx_colleges_nirf       ON colleges (nirf_rank_latest)       WHERE nirf_rank_latest IS NOT NULL;
CREATE INDEX idx_colleges_name_trgm  ON colleges USING gin (name gin_trgm_ops);

COMMENT ON TABLE colleges IS
  'One row per institute. Multi-campus institutes (e.g. BITS, VIT) get one row here plus rows in college_campuses.';

-- -----------------------------------------------------------------------------
-- college_institute_codes
-- Each counselling authority uses its own institute code for the same college.
-- Without this the importer cannot resolve "Institute 107" to a college row.
-- -----------------------------------------------------------------------------
CREATE TABLE college_institute_codes (
  id                       SERIAL      PRIMARY KEY,
  college_id               INT         NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  counselling_authority_id SMALLINT    NOT NULL REFERENCES counselling_authorities(id) ON DELETE CASCADE,
  institute_code           TEXT        NOT NULL,
  institute_name_as_printed TEXT,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (counselling_authority_id, institute_code)
);

CREATE INDEX idx_college_institute_codes_college ON college_institute_codes (college_id);

-- -----------------------------------------------------------------------------
-- college_campuses
-- -----------------------------------------------------------------------------
CREATE TABLE college_campuses (
  id          SERIAL      PRIMARY KEY,
  college_id  INT         NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  state_id    SMALLINT    NOT NULL REFERENCES states(id) ON DELETE RESTRICT,
  city_id     INT         REFERENCES cities(id) ON DELETE SET NULL,
  address     TEXT,
  is_main     BOOLEAN     NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (college_id, name)
);

CREATE TRIGGER trg_college_campuses_updated_at
  BEFORE UPDATE ON college_campuses
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_campus_main ON college_campuses (college_id) WHERE is_main;

-- -----------------------------------------------------------------------------
-- college_accreditations
-- Year-scoped, so NIRF 2024 vs NIRF 2026 are separate rows rather than an
-- overwritten column. Covers NAAC/NBA grades through the same shape.
-- -----------------------------------------------------------------------------
CREATE TABLE college_accreditations (
  id          BIGSERIAL          PRIMARY KEY,
  college_id  INT                NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  kind        accreditation_kind NOT NULL,
  category    TEXT,                            -- NIRF category: 'Engineering', 'Overall'
  academic_year SMALLINT         NOT NULL,
  rank_value  SMALLINT,                        -- NIRF rank
  grade       TEXT,                            -- NAAC 'A++'
  score       NUMERIC(6,2),
  valid_from  DATE,
  valid_to    DATE,
  source_id   INT,                             -- FK added in 008_data_pipeline.sql
  created_at  TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ        NOT NULL DEFAULT now(),

  CONSTRAINT chk_accreditation_value CHECK (rank_value IS NOT NULL OR grade IS NOT NULL OR score IS NOT NULL)
);

CREATE TRIGGER trg_college_accreditations_updated_at
  BEFORE UPDATE ON college_accreditations
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_college_accreditation
  ON college_accreditations (college_id, kind, academic_year, COALESCE(category, ''));

CREATE INDEX idx_accreditation_nirf
  ON college_accreditations (academic_year DESC, rank_value)
  WHERE kind = 'NIRF';

COMMIT;
