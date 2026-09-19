-- =============================================================================
-- 011_college_facts.sql
-- Fees, placements and hostel data -- the columns the comparison screen
-- (design doc section 16) puts side by side.
--
-- All three are year-scoped. Fees and placement figures change annually and a
-- comparison that silently mixes 2023 fees with 2026 fees is worse than no
-- comparison at all.
-- =============================================================================

BEGIN;

CREATE TABLE college_fees (
  id                 BIGSERIAL     PRIMARY KEY,
  college_id         INT           NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  -- NULL = applies to every program at the college.
  college_branch_id  BIGINT        REFERENCES college_branches(id) ON DELETE CASCADE,
  academic_year      SMALLINT      NOT NULL,
  -- Fees differ by quota at private/deemed colleges (government vs management seat).
  quota_id           SMALLINT      REFERENCES quotas(id) ON DELETE SET NULL,
  category_id        SMALLINT      REFERENCES categories(id) ON DELETE SET NULL,

  tuition_fee_annual    NUMERIC(12,2) CHECK (tuition_fee_annual    IS NULL OR tuition_fee_annual    >= 0),
  hostel_fee_annual     NUMERIC(12,2) CHECK (hostel_fee_annual     IS NULL OR hostel_fee_annual     >= 0),
  mess_fee_annual       NUMERIC(12,2) CHECK (mess_fee_annual       IS NULL OR mess_fee_annual       >= 0),
  other_fee_annual      NUMERIC(12,2) CHECK (other_fee_annual      IS NULL OR other_fee_annual      >= 0),
  one_time_fee          NUMERIC(12,2) CHECK (one_time_fee          IS NULL OR one_time_fee          >= 0),
  caution_deposit       NUMERIC(12,2),
  total_course_fee      NUMERIC(12,2),
  currency              CHAR(3)       NOT NULL DEFAULT 'INR',

  source_id          INT           REFERENCES data_sources(id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_college_fees_updated_at
  BEFORE UPDATE ON college_fees
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_college_fees ON college_fees (
  college_id, COALESCE(college_branch_id, 0), academic_year,
  COALESCE(quota_id, 0), COALESCE(category_id, 0)
);

CREATE INDEX idx_college_fees_lookup ON college_fees (college_id, academic_year DESC);

-- -----------------------------------------------------------------------------
-- placement_data
-- -----------------------------------------------------------------------------
CREATE TABLE placement_data (
  id                    BIGSERIAL     PRIMARY KEY,
  college_id            INT           NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  college_branch_id     BIGINT        REFERENCES college_branches(id) ON DELETE CASCADE,
  academic_year         SMALLINT      NOT NULL,

  students_eligible     INT           CHECK (students_eligible IS NULL OR students_eligible >= 0),
  students_placed       INT           CHECK (students_placed   IS NULL OR students_placed   >= 0),
  placement_percentage  NUMERIC(5,2)  CHECK (placement_percentage IS NULL OR placement_percentage BETWEEN 0 AND 100),

  highest_package       NUMERIC(14,2),
  average_package       NUMERIC(14,2),
  median_package        NUMERIC(14,2),
  lowest_package        NUMERIC(14,2),
  currency              CHAR(3)       NOT NULL DEFAULT 'INR',

  total_recruiters      INT,
  top_recruiters        TEXT[],

  source_id             INT           REFERENCES data_sources(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT chk_placed_lte_eligible
    CHECK (students_placed IS NULL OR students_eligible IS NULL OR students_placed <= students_eligible),
  CONSTRAINT chk_package_order
    CHECK (average_package IS NULL OR highest_package IS NULL OR average_package <= highest_package)
);

CREATE TRIGGER trg_placement_data_updated_at
  BEFORE UPDATE ON placement_data
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_placement_data
  ON placement_data (college_id, COALESCE(college_branch_id, 0), academic_year);

CREATE INDEX idx_placement_lookup ON placement_data (college_id, academic_year DESC);

-- -----------------------------------------------------------------------------
-- hostel_data
-- -----------------------------------------------------------------------------
CREATE TABLE hostel_data (
  id                 BIGSERIAL     PRIMARY KEY,
  college_id         INT           NOT NULL REFERENCES colleges(id) ON DELETE CASCADE,
  campus_id          INT           REFERENCES college_campuses(id) ON DELETE CASCADE,
  academic_year      SMALLINT      NOT NULL,

  hostel_for         TEXT          NOT NULL DEFAULT 'all'
                                   CHECK (hostel_for IN ('all', 'boys', 'girls')),
  total_capacity     INT           CHECK (total_capacity IS NULL OR total_capacity >= 0),
  is_guaranteed_first_year BOOLEAN,
  room_types         TEXT[],       -- {single, double, triple}
  annual_fee_min     NUMERIC(12,2),
  annual_fee_max     NUMERIC(12,2),
  mess_type          TEXT          CHECK (mess_type IS NULL OR mess_type IN ('veg', 'non_veg', 'both')),
  amenities          TEXT[],
  notes              TEXT,

  source_id          INT           REFERENCES data_sources(id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now(),

  CONSTRAINT chk_hostel_fee_range
    CHECK (annual_fee_max IS NULL OR annual_fee_min IS NULL OR annual_fee_max >= annual_fee_min)
);

CREATE TRIGGER trg_hostel_data_updated_at
  BEFORE UPDATE ON hostel_data
  FOR EACH ROW EXECUTE FUNCTION app_set_updated_at();

CREATE UNIQUE INDEX uq_hostel_data
  ON hostel_data (college_id, COALESCE(campus_id, 0), academic_year, hostel_for);

COMMIT;
