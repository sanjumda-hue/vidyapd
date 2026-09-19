-- =============================================================================
-- 004_counselling.sql
-- Counselling authority -> per-year process -> rounds.
--
-- Why this is separate from `exams`: the mapping is many-to-many. JoSAA consumes
-- both JEE Main and JEE Advanced; JEE Main feeds JoSAA, CSAB and several state
-- processes. Cutoffs belong to a counselling round, never to an exam directly.
-- =============================================================================

BEGIN;

CREATE TABLE counselling_authorities (
  id                SMALLSERIAL       PRIMARY KEY,
  code              TEXT              NOT NULL UNIQUE,   -- 'JOSAA', 'CSAB', 'KEA', 'COMEDK'
  name              TEXT              NOT NULL,
  scope             counselling_scope NOT NULL,
  state_id          SMALLINT          REFERENCES states(id) ON DELETE SET NULL,
  official_website  TEXT,
  logo_url          TEXT,
  description       TEXT,
  is_active         BOOLEAN           NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ       NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ       NOT NULL DEFAULT now(),

  CONSTRAINT chk_state_scope CHECK (scope <> 'state' OR state_id IS NOT NULL)
);

CREATE TRIGGER trg_counselling_authorities_updated_at
  BEFORE UPDATE ON counselling_authorities
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- -----------------------------------------------------------------------------
-- counselling_processes: one authority-year. "JoSAA 2026".
-- Every cutoff row and every seat-matrix row hangs off one of these.
-- -----------------------------------------------------------------------------
CREATE TABLE counselling_processes (
  id                        SERIAL      PRIMARY KEY,
  counselling_authority_id  SMALLINT    NOT NULL REFERENCES counselling_authorities(id) ON DELETE RESTRICT,
  academic_year             SMALLINT    NOT NULL,
  code                      TEXT        NOT NULL UNIQUE,   -- 'JOSAA_2026'
  name                      TEXT        NOT NULL,          -- 'JoSAA 2026'

  -- Which rank the authority allots on. JoSAA publishes category ranks for
  -- NIT+ and the JEE Advanced CRL for IITs, so this is per-process, not per-exam.
  rank_basis                TEXT        NOT NULL DEFAULT 'category_rank'
                                        CHECK (rank_basis IN ('crl', 'category_rank', 'state_merit', 'percentile')),
  total_rounds              SMALLINT,
  registration_url          TEXT,
  cutoff_url                TEXT,
  seat_matrix_url           TEXT,
  is_published              BOOLEAN     NOT NULL DEFAULT false,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (counselling_authority_id, academic_year)
);

CREATE TRIGGER trg_counselling_processes_updated_at
  BEFORE UPDATE ON counselling_processes
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_counselling_processes_year ON counselling_processes (academic_year DESC);

-- -----------------------------------------------------------------------------
-- counselling_exams: which exam scores a process accepts, and with what weight.
-- -----------------------------------------------------------------------------
CREATE TABLE counselling_exams (
  id                      SERIAL      PRIMARY KEY,
  counselling_process_id  INT         NOT NULL REFERENCES counselling_processes(id) ON DELETE CASCADE,
  exam_id                 SMALLINT    NOT NULL REFERENCES exams(id) ON DELETE RESTRICT,
  -- JoSAA: JEE Advanced applies only to IIT institutes, JEE Main to the rest.
  applies_to_college_types college_type[],
  is_primary              BOOLEAN     NOT NULL DEFAULT true,
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (counselling_process_id, exam_id)
);

CREATE INDEX idx_counselling_exams_exam ON counselling_exams (exam_id);

-- -----------------------------------------------------------------------------
-- counselling_rounds
-- -----------------------------------------------------------------------------
CREATE TABLE counselling_rounds (
  id                      SERIAL      PRIMARY KEY,
  counselling_process_id  INT         NOT NULL REFERENCES counselling_processes(id) ON DELETE CASCADE,
  round_no                SMALLINT    NOT NULL,
  name                    TEXT        NOT NULL,          -- 'Round 5', 'CSAB Special Round 1'
  kind                    round_kind  NOT NULL DEFAULT 'regular',
  allotment_date          DATE,
  reporting_start         DATE,
  reporting_end           DATE,
  -- The last regular round is what the prediction engine treats as the true
  -- closing rank for a year; earlier rounds are kept for trend display only.
  is_final_regular_round  BOOLEAN     NOT NULL DEFAULT false,
  cutoff_published        BOOLEAN     NOT NULL DEFAULT false,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (counselling_process_id, round_no, kind)
);

CREATE TRIGGER trg_counselling_rounds_updated_at
  BEFORE UPDATE ON counselling_rounds
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- At most one final regular round per process.
CREATE UNIQUE INDEX uq_final_regular_round
  ON counselling_rounds (counselling_process_id)
  WHERE is_final_regular_round;

COMMIT;
