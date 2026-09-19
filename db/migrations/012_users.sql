-- =============================================================================
-- 012_users.sql
-- Accounts, the student profile (design doc section 30), saved exam scores
-- (section 31 multi-exam prediction), shortlists and notifications.
-- =============================================================================

BEGIN;

CREATE TABLE users (
  id             BIGSERIAL   PRIMARY KEY,
  uuid           UUID        NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  email          CITEXT,
  phone          TEXT,
  password_hash  TEXT,       -- NULL for OTP-only or social logins
  role           user_role   NOT NULL DEFAULT 'student',

  full_name      TEXT,
  avatar_url     TEXT,

  email_verified_at TIMESTAMPTZ,
  phone_verified_at TIMESTAMPTZ,
  last_login_at     TIMESTAMPTZ,

  is_active      BOOLEAN     NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_user_identifier CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_users_email ON users (email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX uq_users_phone ON users (phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_role ON users (role) WHERE is_active;

-- Deferred FKs from 008_data_pipeline.sql.
ALTER TABLE data_import_jobs
  ADD CONSTRAINT fk_import_jobs_reviewer
  FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE data_change_logs
  ADD CONSTRAINT fk_change_logs_actor
  FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- user_profiles: the one-time form that makes every later prediction a
-- one-tap action instead of a re-entry of eight fields.
-- -----------------------------------------------------------------------------
CREATE TABLE user_profiles (
  user_id             BIGINT           PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

  gender              applicant_gender,
  category_id         SMALLINT         REFERENCES categories(id) ON DELETE SET NULL,
  is_pwd              BOOLEAN          NOT NULL DEFAULT false,
  home_state_id       SMALLINT         REFERENCES states(id) ON DELETE SET NULL,
  domicile_state_id   SMALLINT         REFERENCES states(id) ON DELETE SET NULL,

  class_12_board      TEXT,
  class_12_percentage NUMERIC(5,2)     CHECK (class_12_percentage IS NULL OR class_12_percentage BETWEEN 0 AND 100),
  pcm_percentage      NUMERIC(5,2)     CHECK (pcm_percentage      IS NULL OR pcm_percentage      BETWEEN 0 AND 100),
  passing_year        SMALLINT,

  preferred_state_ids SMALLINT[],
  preferred_branch_ids SMALLINT[],
  preferred_college_types college_type[],
  max_annual_budget   NUMERIC(12,2)    CHECK (max_annual_budget IS NULL OR max_annual_budget >= 0),
  hostel_required     BOOLEAN,

  created_at          TIMESTAMPTZ      NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ      NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- -----------------------------------------------------------------------------
-- user_exam_scores
-- One row per exam the student actually sat. Section 31 compares options across
-- all of them at once, so rank AND percentile are both allowed and the engine
-- converts whichever is missing.
-- -----------------------------------------------------------------------------
CREATE TABLE user_exam_scores (
  id                  BIGSERIAL     PRIMARY KEY,
  user_id             BIGINT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exam_id             SMALLINT      NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  academic_year       SMALLINT      NOT NULL,
  exam_session_id     INT           REFERENCES exam_sessions(id) ON DELETE SET NULL,

  roll_number         TEXT,
  crl_rank            BIGINT        CHECK (crl_rank      IS NULL OR crl_rank      > 0),
  category_rank       BIGINT        CHECK (category_rank IS NULL OR category_rank > 0),
  state_rank          BIGINT        CHECK (state_rank    IS NULL OR state_rank    > 0),
  percentile          NUMERIC(11,8) CHECK (percentile    IS NULL OR percentile BETWEEN 0 AND 100),
  marks               NUMERIC(8,3),

  -- Set when the student entered a percentile and we derived the rank; the UI
  -- shows a "derived" badge so nobody mistakes it for an official rank.
  is_rank_derived     BOOLEAN       NOT NULL DEFAULT false,

  created_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT chk_score_present
    CHECK (crl_rank IS NOT NULL OR category_rank IS NOT NULL
           OR state_rank IS NOT NULL OR percentile IS NOT NULL OR marks IS NOT NULL)
);

CREATE TRIGGER trg_user_exam_scores_updated_at
  BEFORE UPDATE ON user_exam_scores
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_user_exam_score
  ON user_exam_scores (user_id, exam_id, academic_year, COALESCE(exam_session_id, 0));

CREATE INDEX idx_user_exam_scores_user ON user_exam_scores (user_id, academic_year DESC);

-- -----------------------------------------------------------------------------
-- user_shortlists
-- -----------------------------------------------------------------------------
CREATE TABLE user_shortlists (
  id                 BIGSERIAL   PRIMARY KEY,
  user_id            BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  college_branch_id  BIGINT      NOT NULL REFERENCES college_branches(id) ON DELETE CASCADE,
  -- Student-assigned preference order, mirroring a choice-filling list.
  preference_order   SMALLINT,
  note               TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (user_id, college_branch_id)
);

CREATE TRIGGER trg_user_shortlists_updated_at
  BEFORE UPDATE ON user_shortlists
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_shortlists_user ON user_shortlists (user_id, preference_order NULLS LAST);

-- -----------------------------------------------------------------------------
-- notification_subscriptions: which exams a student wants reminders for.
-- -----------------------------------------------------------------------------
CREATE TABLE notification_subscriptions (
  id           BIGSERIAL   PRIMARY KEY,
  user_id      BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exam_id      SMALLINT    REFERENCES exams(id) ON DELETE CASCADE,
  college_id   INT         REFERENCES colleges(id) ON DELETE CASCADE,
  event_types  exam_event_type[],
  lead_days    SMALLINT    NOT NULL DEFAULT 3 CHECK (lead_days BETWEEN 0 AND 60),
  channels     notification_channel[] NOT NULL DEFAULT ARRAY['in_app', 'push']::notification_channel[],
  is_active    BOOLEAN     NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_subscription_target CHECK (exam_id IS NOT NULL OR college_id IS NOT NULL)
);

CREATE TRIGGER trg_notification_subscriptions_updated_at
  BEFORE UPDATE ON notification_subscriptions
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_notification_subscription
  ON notification_subscriptions (user_id, COALESCE(exam_id, 0), COALESCE(college_id, 0));

-- -----------------------------------------------------------------------------
-- notifications: delivered messages. user_id NULL = broadcast.
-- -----------------------------------------------------------------------------
CREATE TABLE notifications (
  id            BIGSERIAL            PRIMARY KEY,
  user_id       BIGINT               REFERENCES users(id) ON DELETE CASCADE,
  channel       notification_channel NOT NULL DEFAULT 'in_app',

  title         TEXT                 NOT NULL,
  body          TEXT                 NOT NULL,
  -- Deep link target, e.g. {"screen":"exam_detail","examId":1}
  payload       JSONB,

  exam_id       SMALLINT             REFERENCES exams(id) ON DELETE CASCADE,
  schedule_id   BIGINT               REFERENCES exam_schedules(id) ON DELETE CASCADE,

  scheduled_for TIMESTAMPTZ,
  sent_at       TIMESTAMPTZ,
  read_at       TIMESTAMPTZ,
  failed_reason TEXT,

  created_at    TIMESTAMPTZ          NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_inbox
  ON notifications (user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX idx_notifications_unread
  ON notifications (user_id) WHERE read_at IS NULL AND user_id IS NOT NULL;
CREATE INDEX idx_notifications_due
  ON notifications (scheduled_for) WHERE sent_at IS NULL;

-- Do not send the same reminder for the same event twice.
CREATE UNIQUE INDEX uq_notification_dedupe
  ON notifications (user_id, schedule_id, channel)
  WHERE schedule_id IS NOT NULL AND user_id IS NOT NULL;

COMMIT;
