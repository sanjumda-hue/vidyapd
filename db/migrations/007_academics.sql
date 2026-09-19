-- =============================================================================
-- 007_academics.sql
-- Branch master, specializations, and the college x branch program table.
--
-- `college_branches` is the spine of the whole system: cutoffs, seat matrix,
-- fees and placement all key off a program, never off (college, branch) loose
-- pairs. Its extra UNIQUE (id, college_id, branch_id) exists so cutoff_data can
-- safely denormalise college_id/branch_id behind a composite foreign key.
-- =============================================================================

BEGIN;

CREATE TABLE branches (
  id             SMALLSERIAL PRIMARY KEY,
  code           TEXT        NOT NULL UNIQUE,   -- 'CSE', 'ECE', 'ME'
  name           TEXT        NOT NULL,
  stream         TEXT        NOT NULL DEFAULT 'core'
                             CHECK (stream IN ('computing', 'electronics', 'electrical',
                                               'core', 'chemical', 'bio', 'interdisciplinary', 'other')),
  description    TEXT,
  icon           TEXT,
  is_popular     BOOLEAN     NOT NULL DEFAULT false,
  display_order  SMALLINT    NOT NULL DEFAULT 100,
  is_active      BOOLEAN     NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_branches_updated_at
  BEFORE UPDATE ON branches
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_branches_name_trgm ON branches USING gin (name gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- specializations: narrower tracks under a parent branch (design doc section 6).
-- 'AI', 'Data Science' and 'Cyber Security' sit under CSE.
-- -----------------------------------------------------------------------------
CREATE TABLE specializations (
  id             SERIAL      PRIMARY KEY,
  branch_id      SMALLINT    NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  code           TEXT        NOT NULL UNIQUE,
  name           TEXT        NOT NULL,
  description    TEXT,
  is_popular     BOOLEAN     NOT NULL DEFAULT false,
  display_order  SMALLINT    NOT NULL DEFAULT 100,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (branch_id, name)
);

CREATE TRIGGER trg_specializations_updated_at
  BEFORE UPDATE ON specializations
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- -----------------------------------------------------------------------------
-- branch_aliases
-- Authorities print the same program a dozen ways: "Computer Science and
-- Engineering", "Computer Science & Engg.", "COMPUTER SCIENCE ENGINEERING".
-- The importer resolves through this table first, then falls back to trigram
-- similarity, then parks the row for manual review.
-- -----------------------------------------------------------------------------
CREATE TABLE branch_aliases (
  id                       SERIAL      PRIMARY KEY,
  branch_id                SMALLINT    NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  specialization_id        INT         REFERENCES specializations(id) ON DELETE CASCADE,
  alias                    TEXT        NOT NULL,
  normalized_alias         TEXT        NOT NULL,   -- lowercased, punctuation stripped
  counselling_authority_id SMALLINT    REFERENCES counselling_authorities(id) ON DELETE CASCADE,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Expression uniqueness needs an index, not a table constraint: a NULL
-- authority means "applies to every authority" and must still collide.
CREATE UNIQUE INDEX uq_branch_alias
  ON branch_aliases (normalized_alias, COALESCE(counselling_authority_id, 0));

CREATE INDEX idx_branch_aliases_trgm ON branch_aliases USING gin (normalized_alias gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- college_branches: an actual program offered by a college.
-- -----------------------------------------------------------------------------
CREATE TABLE college_branches (
  id                BIGSERIAL     PRIMARY KEY,
  college_id        INT           NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  branch_id         SMALLINT      NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  specialization_id INT           REFERENCES specializations(id) ON DELETE SET NULL,
  campus_id         INT           REFERENCES college_campuses(id) ON DELETE SET NULL,

  program_name      TEXT          NOT NULL,   -- verbatim from the authority
  degree            degree_type   NOT NULL DEFAULT 'BTech',
  duration_years    NUMERIC(3,1)  NOT NULL DEFAULT 4.0 CHECK (duration_years BETWEEN 1 AND 7),
  total_intake      SMALLINT      CHECK (total_intake IS NULL OR total_intake >= 0),

  is_active         BOOLEAN       NOT NULL DEFAULT true,
  started_year      SMALLINT,
  discontinued_year SMALLINT,

  created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),

  -- Lets cutoff_data carry college_id/branch_id and still be referentially safe.
  CONSTRAINT uq_college_branch_identity UNIQUE (id, college_id, branch_id)
);

CREATE TRIGGER trg_college_branches_updated_at
  BEFORE UPDATE ON college_branches
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- COALESCE because a NULL specialization_id would otherwise defeat UNIQUE.
CREATE UNIQUE INDEX uq_college_branch_program
  ON college_branches (college_id, branch_id, COALESCE(specialization_id, 0), degree, COALESCE(campus_id, 0));

CREATE INDEX idx_college_branches_college ON college_branches (college_id) WHERE is_active;
CREATE INDEX idx_college_branches_branch  ON college_branches (branch_id, college_id) WHERE is_active;
CREATE INDEX idx_college_branches_spec    ON college_branches (specialization_id) WHERE specialization_id IS NOT NULL;

COMMIT;
