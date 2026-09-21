-- =============================================================================
-- 031_mock_tests.sql
-- Mock papers, answer keys, attempts and their scores.
--
-- A student uploads a question paper's answer key, then their own response
-- sheet, and gets back what they scored. The scoring is exam-wise because the
-- marking is: JEE Main gives +4 and takes 1, BITSAT gives +3 and takes 1,
-- COMEDK gives +1 and takes nothing. Scoring a COMEDK paper with JEE Main's
-- rules would invent penalties that do not exist.
--
-- The scheme is stored ON THE PAPER, not looked up at scoring time. An exam
-- changes its marking between years -- JEE Main's numerical section has had
-- three different rules -- and an attempt from 2024 has to keep being scored
-- the way it was scored in 2024, not the way the exam works today.
--
-- Per-question overrides exist because real papers are not uniform: JEE
-- Advanced varies the marks by section within a single paper.
-- =============================================================================

BEGIN;

CREATE TYPE mock_question_kind AS ENUM (
  'mcq_single',   -- one correct option
  'mcq_multi',    -- more than one; all-or-nothing here, no partial credit
  'numerical'     -- a typed value, compared with a tolerance
);

CREATE TABLE mock_papers (
  id              SERIAL       PRIMARY KEY,
  exam_id         SMALLINT     NOT NULL REFERENCES exams(id) ON DELETE RESTRICT,
  code            TEXT         NOT NULL UNIQUE,     -- 'JEE_MAIN_2025_S1_D1'
  title           TEXT         NOT NULL,
  academic_year   SMALLINT,

  -- The scheme this paper is scored with. Defaults for questions that do not
  -- override them.
  marks_correct   NUMERIC(6,2) NOT NULL,
  marks_wrong     NUMERIC(6,2) NOT NULL DEFAULT 0,   -- stored positive, subtracted
  marks_skipped   NUMERIC(6,2) NOT NULL DEFAULT 0,

  /** Difference between two numerical answers still counted as correct. */
  numeric_tolerance NUMERIC(10,4) NOT NULL DEFAULT 0,

  total_questions SMALLINT     NOT NULL CHECK (total_questions > 0),
  max_marks       NUMERIC(8,2) NOT NULL CHECK (max_marks > 0),

  -- Where the key came from, so a wrong key can be traced rather than argued
  -- about.
  source_note     TEXT,
  uploaded_by     BIGINT       REFERENCES users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT chk_mock_penalty_sign CHECK (marks_wrong >= 0)
);

CREATE TRIGGER trg_mock_papers_updated_at
  BEFORE UPDATE ON mock_papers
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_mock_papers_exam ON mock_papers (exam_id, academic_year DESC);

CREATE TABLE mock_paper_questions (
  id              BIGSERIAL          PRIMARY KEY,
  mock_paper_id   INT                NOT NULL REFERENCES mock_papers(id) ON DELETE CASCADE,
  question_no     SMALLINT           NOT NULL CHECK (question_no > 0),
  section         TEXT,                                   -- 'Physics'
  kind            mock_question_kind NOT NULL DEFAULT 'mcq_single',

  -- 'A', 'AC' for multi, '9.8' for numerical. Compared case-insensitively and
  -- with the letters sorted, so "CA" and "ac" both match "AC".
  correct_answer  TEXT               NOT NULL,

  -- NULL means "use the paper's scheme".
  marks_correct   NUMERIC(6,2),
  marks_wrong     NUMERIC(6,2),

  UNIQUE (mock_paper_id, question_no),
  CONSTRAINT chk_mock_q_penalty_sign CHECK (marks_wrong IS NULL OR marks_wrong >= 0)
);

CREATE INDEX idx_mock_questions_paper ON mock_paper_questions (mock_paper_id, question_no);

CREATE TABLE mock_attempts (
  id              BIGSERIAL    PRIMARY KEY,
  uuid            UUID         NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  mock_paper_id   INT          NOT NULL REFERENCES mock_papers(id) ON DELETE CASCADE,
  user_id         BIGINT       REFERENCES users(id) ON DELETE CASCADE,

  score           NUMERIC(8,2) NOT NULL,
  max_marks       NUMERIC(8,2) NOT NULL,
  correct         SMALLINT     NOT NULL DEFAULT 0,
  wrong           SMALLINT     NOT NULL DEFAULT 0,
  skipped         SMALLINT     NOT NULL DEFAULT 0,

  attempted_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_mock_attempts_user ON mock_attempts (user_id, attempted_at DESC);
CREATE INDEX idx_mock_attempts_paper ON mock_attempts (mock_paper_id, score DESC);

CREATE TABLE mock_attempt_answers (
  id              BIGSERIAL    PRIMARY KEY,
  mock_attempt_id BIGINT       NOT NULL REFERENCES mock_attempts(id) ON DELETE CASCADE,
  question_no     SMALLINT     NOT NULL,
  given_answer    TEXT,                       -- NULL = not attempted
  correct_answer  TEXT         NOT NULL,      -- copied, so a later key edit
                                              -- cannot rewrite a past result
  is_correct      BOOLEAN      NOT NULL,
  awarded         NUMERIC(6,2) NOT NULL,

  UNIQUE (mock_attempt_id, question_no)
);

CREATE INDEX idx_mock_answers_attempt ON mock_attempt_answers (mock_attempt_id, question_no);

COMMENT ON TABLE mock_papers IS
  'A question paper and its answer key. Carries the marking scheme it is scored with, because exams change theirs between years.';
COMMENT ON COLUMN mock_attempt_answers.correct_answer IS
  'Copied from the key at scoring time. Fixing a wrong key later must not silently change what an old attempt scored.';

COMMIT;
