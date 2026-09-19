-- =============================================================================
-- 008_data_pipeline.sql
-- Source registry, import jobs, staging area and the change audit log.
--
-- Design doc sections 21-25. The hard rule encoded here: scraped rows land in
-- data_import_staging, get validated row-by-row, and only reach a live table
-- after a job moves to status 'approved'. Nothing writes to cutoff_data
-- directly except the publish step of an import job.
-- =============================================================================

BEGIN;

CREATE TABLE data_sources (
  id                       SERIAL      PRIMARY KEY,
  code                     TEXT        NOT NULL UNIQUE,   -- JOSAA_ORCR
  name                     TEXT        NOT NULL,
  url                      TEXT        NOT NULL,
  kind                     source_kind NOT NULL,
  tier                     source_tier NOT NULL,

  -- Which adapter class handles this source. Matches the registry key in
  -- api/src/ingestion/adapters -- e.g. josaa, comedk, uptac.
  adapter_key              TEXT        NOT NULL,
  -- What this source yields: cutoff, seat_matrix, schedule, college,
  -- fees, placement, percentile_rank.
  data_type                TEXT        NOT NULL,

  exam_id                  SMALLINT    REFERENCES exams(id) ON DELETE SET NULL,
  counselling_authority_id SMALLINT    REFERENCES counselling_authorities(id) ON DELETE SET NULL,
  counselling_process_id   INT         REFERENCES counselling_processes(id) ON DELETE SET NULL,

  -- Cron expression for the scheduler (section 23 defaults to every 6 hours).
  poll_cron                TEXT        NOT NULL DEFAULT '0 */6 * * *',
  -- Hash of the last fetched payload; identical hash means skip the parse.
  last_content_hash        TEXT,
  last_checked_at          TIMESTAMPTZ,
  last_success_at          TIMESTAMPTZ,
  last_error               TEXT,
  consecutive_failures     SMALLINT    NOT NULL DEFAULT 0,

  -- A tier-1 source may be trusted to publish without a human; everything
  -- below official_counselling should leave this false.
  auto_publish_allowed     BOOLEAN     NOT NULL DEFAULT false,
  is_active                BOOLEAN     NOT NULL DEFAULT true,

  notes                    TEXT,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT chk_autopublish_tier
    CHECK (NOT auto_publish_allowed OR tier IN ('official_authority', 'official_counselling'))
);

CREATE TRIGGER trg_data_sources_updated_at
  BEFORE UPDATE ON data_sources
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_data_sources_due ON data_sources (last_checked_at NULLS FIRST) WHERE is_active;
CREATE INDEX idx_data_sources_adapter ON data_sources (adapter_key, data_type);

-- Deferred FKs from earlier migrations.
ALTER TABLE exam_schedules
  ADD CONSTRAINT fk_exam_schedules_source
  FOREIGN KEY (source_id) REFERENCES data_sources(id) ON DELETE SET NULL;

ALTER TABLE college_accreditations
  ADD CONSTRAINT fk_college_accreditations_source
  FOREIGN KEY (source_id) REFERENCES data_sources(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- data_import_jobs: one run of one adapter against one source.
-- -----------------------------------------------------------------------------
CREATE TABLE data_import_jobs (
  id                      BIGSERIAL     PRIMARY KEY,
  source_id               INT           NOT NULL REFERENCES data_sources(id) ON DELETE RESTRICT,
  counselling_process_id  INT           REFERENCES counselling_processes(id) ON DELETE SET NULL,
  counselling_round_id    INT           REFERENCES counselling_rounds(id) ON DELETE SET NULL,
  academic_year           SMALLINT,

  status                  import_status NOT NULL DEFAULT 'queued',
  trigger_kind            TEXT          NOT NULL DEFAULT 'scheduler'
                                        CHECK (trigger_kind IN ('scheduler', 'manual', 'webhook', 'backfill')),

  artifact_url            TEXT,          -- the PDF/xlsx we actually downloaded
  artifact_path           TEXT,          -- object-storage key of the archived copy
  content_hash            TEXT,

  rows_parsed             INT           NOT NULL DEFAULT 0,
  rows_valid              INT           NOT NULL DEFAULT 0,
  rows_invalid            INT           NOT NULL DEFAULT 0,
  rows_duplicate          INT           NOT NULL DEFAULT 0,
  rows_inserted           INT           NOT NULL DEFAULT 0,
  rows_updated            INT           NOT NULL DEFAULT 0,

  error_summary           TEXT,
  validation_report       JSONB,

  started_at              TIMESTAMPTZ,
  finished_at             TIMESTAMPTZ,
  reviewed_by             BIGINT,        -- FK added in 012_users.sql
  reviewed_at             TIMESTAMPTZ,
  review_note             TEXT,
  published_at            TIMESTAMPTZ,

  created_at              TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_data_import_jobs_updated_at
  BEFORE UPDATE ON data_import_jobs
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE INDEX idx_import_jobs_status  ON data_import_jobs (status, created_at DESC);
CREATE INDEX idx_import_jobs_source  ON data_import_jobs (source_id, created_at DESC);
CREATE INDEX idx_import_jobs_pending ON data_import_jobs (created_at DESC) WHERE status = 'pending_review';

-- Do not re-ingest an artifact we have already published byte-for-byte.
CREATE UNIQUE INDEX uq_import_job_content
  ON data_import_jobs (source_id, content_hash)
  WHERE content_hash IS NOT NULL AND status = 'published';

-- -----------------------------------------------------------------------------
-- data_import_staging
-- Raw extracted rows. The raw column keeps the untouched source record so a
-- parser bug can be fixed and replayed without re-downloading; normalized holds
-- resolved foreign keys after the mapping pass.
-- -----------------------------------------------------------------------------
CREATE TABLE data_import_staging (
  id                BIGSERIAL          PRIMARY KEY,
  import_job_id     BIGINT             NOT NULL REFERENCES data_import_jobs(id) ON DELETE CASCADE,
  row_no            INT                NOT NULL,
  target_table      TEXT               NOT NULL,   -- cutoff_data, seat_matrix, ...

  raw               JSONB              NOT NULL,
  normalized        JSONB,

  status            staging_row_status NOT NULL DEFAULT 'pending',
  -- Array of {code, field, message}; surfaced verbatim in the admin panel.
  validation_errors JSONB,
  target_row_id     BIGINT,            -- id written into the live table

  created_at        TIMESTAMPTZ        NOT NULL DEFAULT now(),

  UNIQUE (import_job_id, row_no)
);

CREATE INDEX idx_staging_job_status ON data_import_staging (import_job_id, status);
CREATE INDEX idx_staging_invalid    ON data_import_staging (import_job_id) WHERE status = 'invalid';

-- -----------------------------------------------------------------------------
-- data_change_logs: append-only audit of every write to a curated table.
-- Cutoff data is the product; silently changing it is the worst failure mode,
-- so every mutation is recorded with old and new values.
-- -----------------------------------------------------------------------------
CREATE TABLE data_change_logs (
  id             BIGSERIAL     PRIMARY KEY,
  table_name     TEXT          NOT NULL,
  row_id         BIGINT        NOT NULL,
  action         change_action NOT NULL,
  changed_fields TEXT[],
  old_values     JSONB,
  new_values     JSONB,
  import_job_id  BIGINT        REFERENCES data_import_jobs(id) ON DELETE SET NULL,
  actor_user_id  BIGINT,       -- FK added in 012_users.sql; NULL means automated
  actor_kind     TEXT          NOT NULL DEFAULT 'system'
                               CHECK (actor_kind IN ('system', 'admin', 'importer')),
  created_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX idx_change_logs_row  ON data_change_logs (table_name, row_id, created_at DESC);
CREATE INDEX idx_change_logs_job  ON data_change_logs (import_job_id) WHERE import_job_id IS NOT NULL;
CREATE INDEX idx_change_logs_time ON data_change_logs (created_at DESC);

COMMIT;
