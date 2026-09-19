-- =============================================================================
-- 010_rank_engine.sql
-- Exam-level rank statistics and the percentile -> rank mapping.
--
-- Design doc section 15: the percentile-to-rank relationship is specific to an
-- exam, year, session AND category. There is deliberately no formula anywhere
-- in this schema. Official published pairs are stored with is_official = true;
-- anything we derive ourselves is stored with the method that produced it, and
-- the API is required to label those as estimates.
-- =============================================================================

BEGIN;

CREATE TABLE exam_rank_data (
  id                    SERIAL      PRIMARY KEY,
  exam_id               SMALLINT    NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  academic_year         SMALLINT    NOT NULL,
  exam_session_id       INT         REFERENCES exam_sessions(id) ON DELETE CASCADE,
  -- NULL = overall / all categories combined.
  category_id           SMALLINT    REFERENCES categories(id) ON DELETE CASCADE,

  registered_candidates INT         CHECK (registered_candidates IS NULL OR registered_candidates >= 0),
  appeared_candidates   INT         CHECK (appeared_candidates   IS NULL OR appeared_candidates   >= 0),
  qualified_candidates  INT         CHECK (qualified_candidates  IS NULL OR qualified_candidates  >= 0),

  -- Cutoff to qualify for the next stage (e.g. JEE Main percentile needed for
  -- JEE Advanced eligibility).
  qualifying_percentile NUMERIC(11,8) CHECK (qualifying_percentile IS NULL OR qualifying_percentile BETWEEN 0 AND 100),
  qualifying_marks      NUMERIC(8,3),
  max_rank              BIGINT      CHECK (max_rank IS NULL OR max_rank > 0),

  source_id             INT         REFERENCES data_sources(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_appeared_lte_registered
    CHECK (appeared_candidates IS NULL OR registered_candidates IS NULL
           OR appeared_candidates <= registered_candidates)
);

CREATE TRIGGER trg_exam_rank_data_updated_at
  BEFORE UPDATE ON exam_rank_data
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_exam_rank_data ON exam_rank_data (
  exam_id, academic_year, COALESCE(exam_session_id, 0), COALESCE(category_id, 0)
);

COMMENT ON TABLE exam_rank_data IS
  'Per exam-year-session-category totals. appeared_candidates is what makes a percentile -> rank estimate possible at all.';

-- -----------------------------------------------------------------------------
-- percentile_rank_mapping
-- A band, not a point: 99.50 percentile maps to a rank RANGE. Storing a range
-- is what lets the UI honestly say "approximately 6,800 - 7,200" instead of
-- inventing a single number.
-- -----------------------------------------------------------------------------
CREATE TABLE percentile_rank_mapping (
  id                BIGSERIAL     PRIMARY KEY,
  exam_id           SMALLINT      NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  academic_year     SMALLINT      NOT NULL,
  exam_session_id   INT           REFERENCES exam_sessions(id) ON DELETE CASCADE,
  category_id       SMALLINT      REFERENCES categories(id) ON DELETE CASCADE,

  percentile        NUMERIC(11,8) NOT NULL CHECK (percentile BETWEEN 0 AND 100),
  rank_from         BIGINT        NOT NULL CHECK (rank_from > 0),
  rank_to           BIGINT        NOT NULL CHECK (rank_to   > 0),

  -- true  = the authority published this pair.
  -- false = we derived it; estimation_method says how, and every API response
  --         built from it must carry is_estimated: true.
  is_official       BOOLEAN       NOT NULL DEFAULT false,
  estimation_method TEXT          NOT NULL DEFAULT 'official_published'
                                  CHECK (estimation_method IN (
                                    'official_published',
                                    'candidate_count_linear',
                                    'interpolated_between_official',
                                    'prior_year_carry_forward'
                                  )),
  confidence        NUMERIC(3,2)  CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),

  source_id         INT           REFERENCES data_sources(id) ON DELETE SET NULL,
  created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT chk_prm_range CHECK (rank_from <= rank_to),
  CONSTRAINT chk_prm_official_method
    CHECK (is_official = (estimation_method = 'official_published'))
);

CREATE TRIGGER trg_percentile_rank_mapping_updated_at
  BEFORE UPDATE ON percentile_rank_mapping
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_percentile_rank_mapping ON percentile_rank_mapping (
  exam_id, academic_year, COALESCE(exam_session_id, 0), COALESCE(category_id, 0), percentile
);

-- Lookup path: find the two bracketing rows around a student percentile.
CREATE INDEX idx_prm_lookup ON percentile_rank_mapping (
  exam_id, academic_year, COALESCE(category_id, 0), percentile DESC
);

COMMIT;
