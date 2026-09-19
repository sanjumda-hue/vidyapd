-- =============================================================================
-- 003_exams.sql
-- Exam master, per-year sessions and the event calendar that powers the
-- "Exam Calendar" screen (design doc section 5).
-- =============================================================================

BEGIN;

CREATE TABLE exams (
  id                    SMALLSERIAL PRIMARY KEY,
  code                  TEXT        NOT NULL UNIQUE,   -- 'JEE_MAIN', 'COMEDK_UGET'
  name                  TEXT        NOT NULL,
  short_name            TEXT,
  level                 exam_level  NOT NULL,
  conducting_authority  TEXT        NOT NULL,          -- 'National Testing Agency'
  official_website      TEXT,
  -- NULL for national exams; set for state CETs so the app can group by state.
  home_state_id         SMALLINT    REFERENCES states(id) ON DELETE SET NULL,

  primary_score_type    score_type  NOT NULL DEFAULT 'rank',
  has_rank              BOOLEAN     NOT NULL DEFAULT true,
  has_percentile        BOOLEAN     NOT NULL DEFAULT false,
  has_marks             BOOLEAN     NOT NULL DEFAULT true,
  is_multi_session      BOOLEAN     NOT NULL DEFAULT false,

  eligibility_summary   TEXT,
  description           TEXT,
  logo_url              TEXT,
  display_order         SMALLINT    NOT NULL DEFAULT 100,
  is_active             BOOLEAN     NOT NULL DEFAULT true,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_exams_updated_at
  BEFORE UPDATE ON exams
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_exams_level        ON exams (level) WHERE is_active;
CREATE INDEX idx_exams_home_state   ON exams (home_state_id) WHERE is_active;
CREATE INDEX idx_exams_name_trgm    ON exams USING gin (name gin_trgm_ops);

COMMENT ON COLUMN exams.primary_score_type IS
  'Which measure the counselling authority actually ranks on. JEE Main = rank (derived from percentile), MHT-CET = percentile.';

-- -----------------------------------------------------------------------------
-- exam_sessions
-- JEE Main runs 2 sessions per year; percentile -> rank normalisation is
-- session-specific, so the rank engine keys off this table.
-- -----------------------------------------------------------------------------
CREATE TABLE exam_sessions (
  id             SERIAL      PRIMARY KEY,
  exam_id        SMALLINT    NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  academic_year  SMALLINT    NOT NULL,       -- admission year, e.g. 2026
  session_no     SMALLINT    NOT NULL DEFAULT 1,
  name           TEXT,                       -- 'Session 1 (January)'
  exam_date_from DATE,
  exam_date_to   DATE,
  result_date    DATE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (exam_id, academic_year, session_no),
  CONSTRAINT chk_session_dates CHECK (exam_date_to IS NULL OR exam_date_from IS NULL OR exam_date_to >= exam_date_from)
);

CREATE TRIGGER trg_exam_sessions_updated_at
  BEFORE UPDATE ON exam_sessions
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_exam_sessions_year ON exam_sessions (academic_year, exam_id);

-- -----------------------------------------------------------------------------
-- exam_schedules
-- One row per calendar event. `is_tentative` matters: most dates are announced
-- as "expected" months before the official notification lands.
-- -----------------------------------------------------------------------------
CREATE TABLE exam_schedules (
  id               BIGSERIAL       PRIMARY KEY,
  exam_id          SMALLINT        NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  exam_session_id  INT             REFERENCES exam_sessions(id) ON DELETE CASCADE,
  academic_year    SMALLINT        NOT NULL,

  event_type       exam_event_type NOT NULL,
  event_name       TEXT            NOT NULL,
  start_date       DATE,
  end_date         DATE,
  start_at         TIMESTAMPTZ,    -- when the authority publishes an exact time
  end_at           TIMESTAMPTZ,

  is_tentative     BOOLEAN         NOT NULL DEFAULT true,
  detail_url       TEXT,
  notes            TEXT,

  source_id        INT,            -- FK added in 008_data_pipeline.sql
  created_at       TIMESTAMPTZ     NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ     NOT NULL DEFAULT now(),

  CONSTRAINT chk_schedule_dates CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
  CONSTRAINT chk_schedule_has_date CHECK (start_date IS NOT NULL OR start_at IS NOT NULL)
);

CREATE TRIGGER trg_exam_schedules_updated_at
  BEFORE UPDATE ON exam_schedules
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- One logical event per exam/session/year. Re-imports update rather than duplicate.
CREATE UNIQUE INDEX uq_exam_schedule_event
  ON exam_schedules (exam_id, academic_year, event_type, COALESCE(exam_session_id, 0));

-- Drives the month-grid calendar query: "all events overlapping [from, to]".
CREATE INDEX idx_exam_schedules_window ON exam_schedules (start_date, end_date);
CREATE INDEX idx_exam_schedules_year   ON exam_schedules (academic_year, exam_id, event_type);

COMMIT;
