-- =============================================================================
-- 009_cutoff_and_seats.sql
-- cutoff_data (the 10M+ row core table) and seat_matrix.
--
-- Partitioned BY LIST (academic_year) because every real query filters on a
-- year window, imports replace exactly one year at a time, and dropping an
-- obsolete year should be a DETACH rather than a mass DELETE.
--
-- college_id and branch_id are denormalised here for index-only filtering, but
-- they are NOT free-floating: the composite FK against
-- college_branches (id, college_id, branch_id) makes an inconsistent triple
-- impossible to insert.
-- =============================================================================

BEGIN;

CREATE TABLE cutoff_data (
  id                      BIGSERIAL,
  academic_year           SMALLINT NOT NULL,

  counselling_process_id  INT      NOT NULL REFERENCES counselling_processes(id) ON DELETE RESTRICT,
  counselling_round_id    INT      NOT NULL REFERENCES counselling_rounds(id)    ON DELETE RESTRICT,
  round_no                SMALLINT NOT NULL,
  exam_id                 SMALLINT NOT NULL REFERENCES exams(id) ON DELETE RESTRICT,

  college_branch_id       BIGINT   NOT NULL,
  college_id              INT      NOT NULL,
  branch_id               SMALLINT NOT NULL,

  seat_type_id            SMALLINT NOT NULL REFERENCES seat_types(id) ON DELETE RESTRICT,
  category_id             SMALLINT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  quota_id                SMALLINT NOT NULL REFERENCES quotas(id)     ON DELETE RESTRICT,
  gender_id               SMALLINT NOT NULL REFERENCES genders(id)    ON DELETE RESTRICT,

  -- Rank-based authorities (JoSAA, CSAB, most state CETs).
  opening_rank            BIGINT,
  closing_rank            BIGINT,
  -- Percentile-based authorities (MHT-CET) and score-based ones (BITSAT).
  opening_percentile      NUMERIC(11,8),
  closing_percentile      NUMERIC(11,8),
  opening_score           NUMERIC(10,4),
  closing_score           NUMERIC(10,4),

  -- What the printed rank actually is, so we never compare a category rank
  -- against a CRL by accident.
  rank_basis              TEXT     NOT NULL DEFAULT 'category_rank'
                                   CHECK (rank_basis IN ('crl', 'category_rank', 'state_merit', 'percentile')),
  seats_offered           SMALLINT,
  is_preparatory          BOOLEAN  NOT NULL DEFAULT false,  -- IIT preparatory-course seats

  source_id               INT      REFERENCES data_sources(id)     ON DELETE SET NULL,
  import_job_id           BIGINT   REFERENCES data_import_jobs(id) ON DELETE SET NULL,
  is_verified             BOOLEAN  NOT NULL DEFAULT false,

  imported_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- A partitioned table's PK must contain the partition key.
  PRIMARY KEY (academic_year, id),

  CONSTRAINT fk_cutoff_program
    FOREIGN KEY (college_branch_id, college_id, branch_id)
    REFERENCES college_branches (id, college_id, branch_id) ON DELETE CASCADE,

  CONSTRAINT chk_cutoff_rank_order
    CHECK (opening_rank IS NULL OR closing_rank IS NULL OR opening_rank <= closing_rank),
  -- Percentile runs the other way: the closing percentile is the lower one.
  CONSTRAINT chk_cutoff_percentile_order
    CHECK (opening_percentile IS NULL OR closing_percentile IS NULL OR opening_percentile >= closing_percentile),
  CONSTRAINT chk_cutoff_positive_rank
    CHECK ((opening_rank IS NULL OR opening_rank > 0) AND (closing_rank IS NULL OR closing_rank > 0)),
  CONSTRAINT chk_cutoff_has_measure
    CHECK (closing_rank IS NOT NULL OR closing_percentile IS NOT NULL OR closing_score IS NOT NULL),
  CONSTRAINT chk_cutoff_year
    CHECK (academic_year BETWEEN 2000 AND 2100)
) PARTITION BY LIST (academic_year);

CREATE TRIGGER trg_cutoff_data_updated_at
  BEFORE UPDATE ON cutoff_data
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

-- Partitions. 2019..2032 covers the four-year history the product ships with
-- plus a decade of headroom; app_ensure_cutoff_partition() below creates more.
DO $part$
DECLARE
  y INT;
BEGIN
  FOR y IN 2019..2032 LOOP
    EXECUTE format(
      'CREATE TABLE IF NOT EXISTS cutoff_data_y%s PARTITION OF cutoff_data FOR VALUES IN (%s)',
      y, y);
  END LOOP;
END;
$part$;

-- Anything outside the known years lands here instead of erroring the import.
CREATE TABLE IF NOT EXISTS cutoff_data_default PARTITION OF cutoff_data DEFAULT;

CREATE OR REPLACE FUNCTION app_ensure_cutoff_partition(p_year INT)
RETURNS void
LANGUAGE plpgsql
AS $fn$
BEGIN
  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS cutoff_data_y%s PARTITION OF cutoff_data FOR VALUES IN (%s)',
    p_year, p_year);
END;
$fn$;

COMMENT ON FUNCTION app_ensure_cutoff_partition(INT) IS
  'Called by the importer before loading a new academic year.';

-- -----------------------------------------------------------------------------
-- Indexes. All of them must include academic_year to be creatable on the
-- partitioned parent, which is fine because every query scopes by year anyway.
-- -----------------------------------------------------------------------------

-- Natural key. This is the ON CONFLICT target for idempotent re-imports.
CREATE UNIQUE INDEX uq_cutoff_natural ON cutoff_data (
  academic_year, counselling_process_id, round_no, college_branch_id,
  seat_type_id, quota_id, gender_id
);

-- "Show me this college's CSE cutoff history" -- the college detail screen.
CREATE INDEX idx_cutoff_by_college ON cutoff_data (
  college_id, branch_id, seat_type_id, quota_id, gender_id, academic_year DESC, round_no DESC
);

-- Trend refresh and program detail.
CREATE INDEX idx_cutoff_by_program ON cutoff_data (
  college_branch_id, seat_type_id, quota_id, gender_id, academic_year DESC, round_no DESC
);

-- Raw rank sweep, used when the materialised trend view is stale or bypassed.
CREATE INDEX idx_cutoff_closing_rank ON cutoff_data (
  counselling_process_id, seat_type_id, quota_id, gender_id, closing_rank
) WHERE closing_rank IS NOT NULL;

-- Rollback of a bad import.
CREATE INDEX idx_cutoff_import_job ON cutoff_data (import_job_id) WHERE import_job_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- Keep category_id consistent with seat_type_id. The importer writes both
-- because queries filter on either, and a mismatch would silently corrupt
-- every prediction for that category.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_sync_cutoff_category()
RETURNS trigger
LANGUAGE plpgsql
AS $fn$
BEGIN
  SELECT st.category_id INTO NEW.category_id
  FROM seat_types st
  WHERE st.id = NEW.seat_type_id;

  IF NEW.category_id IS NULL THEN
    RAISE EXCEPTION 'cutoff_data: unknown seat_type_id %', NEW.seat_type_id;
  END IF;

  RETURN NEW;
END;
$fn$;

CREATE TRIGGER trg_cutoff_sync_category
  BEFORE INSERT OR UPDATE OF seat_type_id ON cutoff_data
  FOR EACH ROW EXECUTE FUNCTION app_sync_cutoff_category();

-- -----------------------------------------------------------------------------
-- seat_matrix: seats offered per program per dimension, per year.
-- Kept separate from cutoff_data because the matrix is published before
-- counselling starts, while cutoffs only exist after each round.
-- -----------------------------------------------------------------------------
CREATE TABLE seat_matrix (
  id                     BIGSERIAL   PRIMARY KEY,
  academic_year          SMALLINT    NOT NULL CHECK (academic_year BETWEEN 2000 AND 2100),
  counselling_process_id INT         NOT NULL REFERENCES counselling_processes(id) ON DELETE CASCADE,
  counselling_round_id   INT         REFERENCES counselling_rounds(id) ON DELETE SET NULL,

  college_branch_id      BIGINT      NOT NULL REFERENCES college_branches(id) ON DELETE CASCADE,
  seat_type_id           SMALLINT    NOT NULL REFERENCES seat_types(id) ON DELETE RESTRICT,
  quota_id               SMALLINT    NOT NULL REFERENCES quotas(id)     ON DELETE RESTRICT,
  gender_id              SMALLINT    NOT NULL REFERENCES genders(id)    ON DELETE RESTRICT,

  total_seats            SMALLINT    NOT NULL CHECK (total_seats >= 0),
  filled_seats           SMALLINT    CHECK (filled_seats IS NULL OR filled_seats >= 0),

  source_id              INT         REFERENCES data_sources(id)     ON DELETE SET NULL,
  import_job_id          BIGINT      REFERENCES data_import_jobs(id) ON DELETE SET NULL,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_seat_matrix_filled CHECK (filled_seats IS NULL OR filled_seats <= total_seats)
);

CREATE TRIGGER trg_seat_matrix_updated_at
  BEFORE UPDATE ON seat_matrix
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_seat_matrix_natural ON seat_matrix (
  academic_year, counselling_process_id, COALESCE(counselling_round_id, 0),
  college_branch_id, seat_type_id, quota_id, gender_id
);

CREATE INDEX idx_seat_matrix_program ON seat_matrix (college_branch_id, academic_year DESC);

COMMIT;
