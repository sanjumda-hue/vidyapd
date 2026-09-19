-- =============================================================================
-- 013_prediction.sql
-- Tunable weights, request log and result cache for the prediction engine.
--
-- Design doc sections 12-14 and 29. The 40/30/20/10 recency weighting lives in
-- a TABLE, not in code, so the weighting can be re-tuned against last season's
-- actual allotments without a deploy.
-- =============================================================================

BEGIN;

CREATE TABLE prediction_weight_profiles (
  id            SMALLSERIAL PRIMARY KEY,
  code          TEXT        NOT NULL UNIQUE,   -- 'default', 'josaa_tuned'
  name          TEXT        NOT NULL,
  description   TEXT,
  -- Exactly one profile is active per (counselling authority or globally).
  counselling_authority_id SMALLINT REFERENCES counselling_authorities(id) ON DELETE CASCADE,
  is_active     BOOLEAN     NOT NULL DEFAULT false,

  -- Grading thresholds (section 14). Stored per profile so the bands can be
  -- tightened for authorities whose cutoffs swing more year to year.
  strong_match_factor   NUMERIC(4,3) NOT NULL DEFAULT 0.900
                        CHECK (strong_match_factor BETWEEN 0.500 AND 1.000),
  borderline_factor     NUMERIC(4,3) NOT NULL DEFAULT 1.100
                        CHECK (borderline_factor BETWEEN 1.000 AND 2.000),
  -- A program with fewer than this many years of data is never graded 'strong'.
  min_years_for_strong  SMALLINT     NOT NULL DEFAULT 2 CHECK (min_years_for_strong >= 1),

  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_prediction_weight_profiles_updated_at
  BEFORE UPDATE ON prediction_weight_profiles
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_active_weight_profile
  ON prediction_weight_profiles (COALESCE(counselling_authority_id, 0))
  WHERE is_active;

-- -----------------------------------------------------------------------------
-- prediction_year_weights
-- year_offset 0 = most recent year with data, 1 = year before it, and so on.
-- Offsets are relative rather than absolute so the profile survives the roll
-- into a new admission season untouched.
-- -----------------------------------------------------------------------------
CREATE TABLE prediction_year_weights (
  id          SERIAL       PRIMARY KEY,
  profile_id  SMALLINT     NOT NULL REFERENCES prediction_weight_profiles(id) ON DELETE CASCADE,
  year_offset SMALLINT     NOT NULL CHECK (year_offset BETWEEN 0 AND 10),
  weight      NUMERIC(5,4) NOT NULL CHECK (weight >= 0 AND weight <= 1),
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

  UNIQUE (profile_id, year_offset)
);

COMMENT ON TABLE prediction_year_weights IS
  'Recency weights. Seeded 0.40 / 0.30 / 0.20 / 0.10 for offsets 0..3 per design doc section 13.';

-- -----------------------------------------------------------------------------
-- prediction_requests
-- Logged for two reasons: the "what-if" screen (section 29) re-runs the same
-- inputs at shifted ranks, and the admin analytics panel needs to know which
-- exam/rank bands are actually being searched.
-- user_id is nullable because guests can predict without signing in.
-- -----------------------------------------------------------------------------
CREATE TABLE prediction_requests (
  id                  BIGSERIAL             PRIMARY KEY,
  uuid                UUID                  NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  user_id             BIGINT                REFERENCES users(id) ON DELETE SET NULL,
  session_key         TEXT,                 -- anonymous device identifier

  exam_id             SMALLINT              NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  academic_year       SMALLINT              NOT NULL,
  input_kind          prediction_input_kind NOT NULL DEFAULT 'rank',

  input_rank          BIGINT                CHECK (input_rank  IS NULL OR input_rank  > 0),
  input_percentile    NUMERIC(11,8)         CHECK (input_percentile IS NULL OR input_percentile BETWEEN 0 AND 100),
  input_marks         NUMERIC(8,3),
  -- Rank the engine actually used. Differs from input_rank when the student
  -- supplied a percentile; resolved_rank_is_estimated then goes true.
  resolved_rank       BIGINT,
  resolved_rank_is_estimated BOOLEAN        NOT NULL DEFAULT false,

  category_id         SMALLINT              REFERENCES categories(id) ON DELETE SET NULL,
  applicant_gender    applicant_gender,
  is_pwd              BOOLEAN               NOT NULL DEFAULT false,
  home_state_id       SMALLINT              REFERENCES states(id) ON DELETE SET NULL,

  filter_branch_ids   SMALLINT[],
  filter_state_ids    SMALLINT[],
  filter_college_types college_type[],
  filter_max_fee      NUMERIC(12,2),

  weight_profile_id   SMALLINT              REFERENCES prediction_weight_profiles(id) ON DELETE SET NULL,
  -- Set when this run is one step of a what-if sweep, pointing at the original.
  what_if_parent_id   BIGINT                REFERENCES prediction_requests(id) ON DELETE CASCADE,

  result_count        INT                   NOT NULL DEFAULT 0,
  duration_ms         INT,
  created_at          TIMESTAMPTZ           NOT NULL DEFAULT now(),

  CONSTRAINT chk_prediction_input
    CHECK (input_rank IS NOT NULL OR input_percentile IS NOT NULL OR input_marks IS NOT NULL)
);

CREATE INDEX idx_prediction_requests_user ON prediction_requests (user_id, created_at DESC)
  WHERE user_id IS NOT NULL;
CREATE INDEX idx_prediction_requests_exam ON prediction_requests (exam_id, academic_year, created_at DESC);
CREATE INDEX idx_prediction_requests_whatif ON prediction_requests (what_if_parent_id)
  WHERE what_if_parent_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- prediction_results
-- Every number the UI shows is stored, so a student who reopens a saved
-- prediction sees exactly what they saw before -- even after the trend view has
-- been refreshed with a newer round.
-- -----------------------------------------------------------------------------
CREATE TABLE prediction_results (
  id                      BIGSERIAL   PRIMARY KEY,
  prediction_request_id   BIGINT      NOT NULL REFERENCES prediction_requests(id) ON DELETE CASCADE,

  college_branch_id       BIGINT      NOT NULL REFERENCES college_branches(id) ON DELETE CASCADE,
  college_id              INT         NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  branch_id               SMALLINT    NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  -- Authority, not a single year's process: a result is an aggregate over
  -- several years, so there is no one counselling_process it belongs to.
  counselling_authority_id SMALLINT   NOT NULL REFERENCES counselling_authorities(id) ON DELETE CASCADE,

  -- The exact seat the student would be competing for.
  seat_type_id            SMALLINT    NOT NULL REFERENCES seat_types(id) ON DELETE RESTRICT,
  quota_id                SMALLINT    NOT NULL REFERENCES quotas(id)     ON DELETE RESTRICT,
  gender_id               SMALLINT    NOT NULL REFERENCES genders(id)    ON DELETE RESTRICT,

  grade                   match_grade NOT NULL,
  -- 0..100 composite from section 13: recency-weighted rank distance plus the
  -- quota/state/branch-preference bonuses.
  score                   NUMERIC(6,2) NOT NULL CHECK (score BETWEEN 0 AND 100),

  weighted_closing_rank   BIGINT,
  best_closing_rank       BIGINT,
  worst_closing_rank      BIGINT,
  latest_closing_rank     BIGINT,
  -- weighted_closing_rank - student rank. Positive = student is ahead of the
  -- historical cutoff.
  rank_margin             BIGINT,
  years_available         SMALLINT    NOT NULL DEFAULT 0,
  -- regr_slope of closing rank over year. Negative = cutoff tightening.
  trend_slope             NUMERIC(12,2),

  -- {"2026":{"opening":2500,"closing":4200,"round":5}, ...}
  cutoff_history          JSONB,

  display_rank            SMALLINT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (prediction_request_id, college_branch_id, seat_type_id, quota_id, gender_id)
);

CREATE INDEX idx_prediction_results_request
  ON prediction_results (prediction_request_id, display_rank NULLS LAST);
CREATE INDEX idx_prediction_results_grade
  ON prediction_results (prediction_request_id, grade, score DESC);

COMMIT;
