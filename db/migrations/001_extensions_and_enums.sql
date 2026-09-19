-- =============================================================================
-- 001_extensions_and_enums.sql
-- Extensions, shared enum types and generic helper functions.
-- Everything else in db/migrations depends on this file.
-- =============================================================================

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- fuzzy college/branch search
CREATE EXTENSION IF NOT EXISTS btree_gin;  -- composite gin indexes
CREATE EXTENSION IF NOT EXISTS citext;     -- case-insensitive email column

-- -----------------------------------------------------------------------------
-- Generic updated_at trigger. Attached to every mutable table.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- Exam domain
-- -----------------------------------------------------------------------------
CREATE TYPE exam_level AS ENUM (
  'national',    -- JEE Main, JEE Advanced
  'state',       -- MHT-CET, KCET, WBJEE, UPTAC-feeder
  'university',  -- VITEEE, SRMJEEE
  'deemed'       -- BITSAT and similar deemed-university tests
);

CREATE TYPE score_type AS ENUM ('rank', 'percentile', 'marks', 'composite');

CREATE TYPE exam_event_type AS ENUM (
  'notification',
  'application_start',
  'application_end',
  'fee_payment_end',
  'correction_window',
  'admit_card',
  'exam',
  'answer_key',
  'objection_window',
  'result',
  'counselling_registration',
  'counselling_choice_filling',
  'seat_allotment',
  'reporting',
  'counselling_end'
);

-- -----------------------------------------------------------------------------
-- Counselling domain
-- -----------------------------------------------------------------------------
CREATE TYPE counselling_scope AS ENUM ('national', 'state', 'institute');

CREATE TYPE round_kind AS ENUM ('regular', 'special', 'spot', 'mop_up', 'stray_vacancy');

-- -----------------------------------------------------------------------------
-- College domain
-- -----------------------------------------------------------------------------
CREATE TYPE college_type AS ENUM (
  'IIT', 'NIT', 'IIIT', 'GFTI',
  'STATE_GOVT', 'GOVT_AIDED', 'PRIVATE', 'DEEMED', 'AUTONOMOUS'
);

CREATE TYPE ownership_type AS ENUM (
  'government', 'government_aided', 'private', 'public_private_partnership'
);

CREATE TYPE degree_type AS ENUM ('BTech', 'BE', 'BArch', 'BPlan', 'Dual', 'Integrated');

CREATE TYPE accreditation_kind AS ENUM ('NIRF', 'NAAC', 'NBA', 'AICTE', 'UGC', 'ABET');

-- -----------------------------------------------------------------------------
-- Data ingestion domain
-- -----------------------------------------------------------------------------
CREATE TYPE source_kind AS ENUM ('api', 'html', 'pdf', 'xlsx', 'csv', 'manual');

-- Section 21 of the design doc: source priority ladder. Lower ordinal = higher trust.
CREATE TYPE source_tier AS ENUM (
  'official_authority',    -- 1. NTA, JoSAA
  'official_counselling',  -- 2. counselling portal
  'official_pdf',          -- 3. official notice / brochure PDF
  'official_institute',    -- 4. institute's own website
  'secondary'              -- 5. everything else, never auto-published
);

CREATE TYPE import_status AS ENUM (
  'queued',
  'running',
  'parsed',
  'validation_failed',
  'pending_review',   -- waiting for admin approval (section 23)
  'approved',
  'rejected',
  'published',
  'failed'
);

CREATE TYPE staging_row_status AS ENUM (
  'pending', 'valid', 'invalid', 'duplicate', 'imported', 'discarded'
);

CREATE TYPE change_action AS ENUM ('insert', 'update', 'delete');

-- -----------------------------------------------------------------------------
-- Prediction domain
-- -----------------------------------------------------------------------------
-- Section 14: deliberately no "guaranteed admission" value exists in this enum.
CREATE TYPE match_grade AS ENUM (
  'strong_historical_match',
  'historical_match',
  'borderline',
  'outside_historical_range'
);

CREATE TYPE prediction_input_kind AS ENUM ('rank', 'percentile', 'marks');

-- -----------------------------------------------------------------------------
-- User domain
-- -----------------------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('student', 'reviewer', 'data_editor', 'admin');

CREATE TYPE applicant_gender AS ENUM ('male', 'female', 'other');

CREATE TYPE notification_channel AS ENUM ('in_app', 'push', 'email');

COMMIT;
