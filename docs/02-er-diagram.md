# ER Diagram and Table Relationships

43 tables, 2 views, 1 materialised view. Source of truth: [`db/migrations/`](../db/migrations/).

The schema is built around one idea: **a cutoff belongs to a counselling round,
not to an exam**. Everything else follows from that.

---

## 1. Domain map

```
GEOGRAPHY          EXAMS                    COUNSELLING
┌─────────┐        ┌──────────────┐         ┌────────────────────────┐
│ states  │◄───────│ exams        │────────►│ counselling_exams      │
│ cities  │        │ exam_sessions│         │ counselling_authorities│
└────┬────┘        │ exam_schedules         │ counselling_processes  │
     │             └──────────────┘         │ counselling_rounds     │
     │                                      │ counselling_dimension_map
     │                                      └───────────┬────────────┘
     ▼                                                  │
COLLEGES                  ACADEMICS                     │
┌───────────────────────┐ ┌──────────────────┐          │
│ colleges              │ │ branches         │          │
│ college_campuses      │ │ specializations  │          │
│ college_accreditations│ │ branch_aliases   │          │
│ college_institute_codes└─┤ college_branches │◄─────────┘
└───────────┬───────────┘ └────────┬─────────┘
            │                      │
            │      ┌───────────────┴───────────────┐
            │      ▼                               ▼
            │  ┌──────────────┐            ┌──────────────┐
            │  │ cutoff_data  │            │ seat_matrix  │
            │  │ (partitioned)│            └──────────────┘
            │  └──────┬───────┘
            │         │  RESERVATION DIMENSIONS
            │         ├─► categories
            │         ├─► seat_types  (category x PwD)
            │         ├─► quotas      (AI / HS / OS / GO)
            │         └─► genders     (neutral / female-only)
            ▼
    college_fees, placement_data, hostel_data
```

---

## 2. The four reservation dimensions

Design doc section 9. These are **not** one `category` column.

| Table        | What it answers                    | Example values                     |
| ------------ | ---------------------------------- | ---------------------------------- |
| `categories` | Social category                    | OPEN, EWS, OBC-NCL, SC, ST         |
| `seat_types` | Category x PwD (JoSAA "Seat Type") | OPEN, OPEN-PwD, OBC-NCL-PwD        |
| `quotas`     | State eligibility                  | AI, HS, OS, GO, JK, LA             |
| `genders`    | Seat gender pool                   | Gender-Neutral, Female-Only        |

`seat_types` is **derived**: `seat_types(category_id, is_pwd)` with
`UNIQUE (category_id, is_pwd)`. That is what lets the predictor widen from
`OBC-NCL-PwD` to `OBC-NCL` to `OPEN` by walking foreign keys instead of parsing
strings.

`genders.allowed_applicant_genders` is an array, so eligibility is one
containment check: a female candidate matches both pools, a male candidate only
the neutral one.

`quotas.requires_home_state_match` / `requires_other_state` encode the HS/OS
rule as data. No code anywhere hardcodes the string `'HS'`.

### Per-authority labels

`counselling_dimension_map` maps an authority's printed label onto our canonical
id: KEA prints `3BG`, JoSAA prints `OBC-NCL`. Adding a state counselling is a
seed-row job, not a code change. A trigger validates that `ref_id` exists in the
table named by `dimension`.

---

## 3. `cutoff_data` — the core table

```
cutoff_data  (PARTITION BY LIST (academic_year))
├── PK (academic_year, id)             -- partition key must be in the PK
├── counselling_process_id  ──► counselling_processes
├── counselling_round_id    ──► counselling_rounds
├── exam_id                 ──► exams
├── (college_branch_id, college_id, branch_id) ──► college_branches (composite FK)
├── seat_type_id ──► seat_types      category_id ──► categories (trigger-synced)
├── quota_id     ──► quotas          gender_id   ──► genders
├── opening_rank / closing_rank
├── opening_percentile / closing_percentile      -- MHT-CET and similar
├── opening_score / closing_score                -- BITSAT and similar
└── source_id, import_job_id, is_verified        -- provenance
```

Three decisions worth knowing:

**Partitioned by year.** Every query filters on a year window, imports replace
exactly one year, and retiring an old year is a `DETACH PARTITION` instead of a
mass `DELETE`. `app_ensure_cutoff_partition(year)` creates a new one; a DEFAULT
partition catches anything unexpected so an import cannot hard-fail on an
unseen year.

**`college_id` and `branch_id` are denormalised — safely.** They are not loose
copies. `college_branches` carries `UNIQUE (id, college_id, branch_id)` and
`cutoff_data` has a composite FK against it, so an inconsistent triple cannot be
inserted. You get index-only filtering by college without a join, and the
database still guarantees consistency.

**`category_id` is trigger-maintained** from `seat_type_id`. Both columns exist
because queries filter on either; a mismatch would silently corrupt every
prediction for that category, so it is not left to application code.

### Natural key

```sql
UNIQUE (academic_year, counselling_process_id, round_no,
        college_branch_id, seat_type_id, quota_id, gender_id)
```

This is the `ON CONFLICT` target, which is what makes re-importing the same
round idempotent.

---

## 4. Prediction path

```
cutoff_data (millions of rows)
     │  last round per year, 5 most recent years
     ▼
mv_program_cutoff_trend      one row per (authority, exam, program, seat_type, quota, gender)
     │  closing_y0..closing_y4, best/worst/latest, years_available, trend_slope, cutoff_history
     ▼
fn_predict_colleges(...)     applies prediction_year_weights at QUERY time
     │                       + eligibility (seat types, genders, HS/OS quotas)
     ▼
fn_grade_match(...)          strong / historical / borderline / outside
     ▼
prediction_requests ──1:N──► prediction_results     (snapshot, so a saved
                                                     prediction never changes)
```

Weights live in `prediction_year_weights` (40/30/20/10 by default), **not** in
the view and not in code, so re-tuning against last season's actual allotments
is a row update rather than a deploy. `ref_year` is computed per counselling
authority, because one authority may publish months before another.

---

## 5. Ingestion path

```
data_sources          one row per official URL + adapter_key + tier
     │
     ▼
data_import_jobs      status: queued → running → parsed → pending_review
     │                        → approved → published
     ▼
data_import_staging   raw JSONB + normalized JSONB + per-row validation_errors
     │                (only rows with status='valid' are eligible)
     ▼
cutoff_data / seat_matrix / exam_schedules / ...
     │
     ▼
data_change_logs      append-only old/new values for every curated write
```

Nothing writes to a live table except the publish step of an approved job.
`data_sources.auto_publish_allowed` is constrained so only tier-1 and tier-2
official sources can even be considered for unattended publishing.

---

## 6. Full table list

| Group        | Tables |
| ------------ | ------ |
| Geography    | `states`, `cities` |
| Exams        | `exams`, `exam_sessions`, `exam_schedules` |
| Counselling  | `counselling_authorities`, `counselling_processes`, `counselling_exams`, `counselling_rounds`, `counselling_dimension_map` |
| Reservation  | `categories`, `genders`, `quotas`, `seat_types` |
| Colleges     | `colleges`, `college_institute_codes`, `college_campuses`, `college_accreditations` |
| Academics    | `branches`, `specializations`, `branch_aliases`, `college_branches` |
| Core data    | `cutoff_data`, `seat_matrix` |
| Rank engine  | `exam_rank_data`, `percentile_rank_mapping` |
| College facts| `college_fees`, `placement_data`, `hostel_data` |
| Ingestion    | `data_sources`, `data_import_jobs`, `data_import_staging`, `data_change_logs` |
| Users        | `users`, `user_profiles`, `user_exam_scores`, `user_shortlists`, `notification_subscriptions`, `notifications` |
| Prediction   | `prediction_weight_profiles`, `prediction_year_weights`, `prediction_requests`, `prediction_results` |
| Derived      | `v_exam_calendar`, `v_program_summary`, `mv_program_cutoff_trend` |
