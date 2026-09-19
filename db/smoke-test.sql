-- =============================================================================
-- smoke-test.sql
--
-- Proves the engine end to end on synthetic data:
--   2 colleges, 3 programs, 4 years of cutoffs, then a prediction.
-- Everything is created inside a transaction that is ROLLED BACK, so this is
-- safe to run against a seeded database without leaving anything behind.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f db/smoke-test.sql
-- =============================================================================

BEGIN;

\echo '--- 1. reference data present? ---'
SELECT
  (SELECT count(*) FROM states)     AS states,
  (SELECT count(*) FROM categories) AS categories,
  (SELECT count(*) FROM seat_types) AS seat_types,
  (SELECT count(*) FROM quotas)     AS quotas,
  (SELECT count(*) FROM genders)    AS genders,
  (SELECT count(*) FROM branches)   AS branches,
  (SELECT count(*) FROM exams)      AS exams;

\echo '--- 2. counselling process + rounds ---'
INSERT INTO counselling_processes (counselling_authority_id, academic_year, code, name, rank_basis)
SELECT a.id, y.yr, 'JOSAA_' || y.yr, 'JoSAA ' || y.yr, 'category_rank'
FROM counselling_authorities a
CROSS JOIN (VALUES (2023), (2024), (2025), (2026)) AS y(yr)
WHERE a.code = 'JOSAA';

INSERT INTO counselling_rounds (counselling_process_id, round_no, name, is_final_regular_round, cutoff_published)
SELECT cp.id, 5, 'Round 5', true, true
FROM counselling_processes cp
WHERE cp.code LIKE 'JOSAA_%';

\echo '--- 3. two colleges, three programs ---'
INSERT INTO colleges (slug, name, short_name, college_type, ownership, state_id)
SELECT 'nit-test-up', 'NIT Test (Uttar Pradesh)', 'NIT-UP', 'NIT', 'government', s.id
FROM states s WHERE s.code = 'UP';

INSERT INTO colleges (slug, name, short_name, college_type, ownership, state_id)
SELECT 'iiit-test-ka', 'IIIT Test (Karnataka)', 'IIIT-KA', 'IIIT', 'public_private_partnership', s.id
FROM states s WHERE s.code = 'KA';

INSERT INTO college_branches (college_id, branch_id, program_name, degree, total_intake)
SELECT c.id, b.id, b.name || ' (4 Years, Bachelor of Technology)', 'BTech', 120
FROM colleges c
JOIN branches b ON b.code IN ('CSE', 'ECE')
WHERE c.slug = 'nit-test-up';

INSERT INTO college_branches (college_id, branch_id, program_name, degree, total_intake)
SELECT c.id, b.id, b.name || ' (4 Years, Bachelor of Technology)', 'BTech', 60
FROM colleges c
JOIN branches b ON b.code = 'CSE'
WHERE c.slug = 'iiit-test-ka';

\echo '--- 4. four years of cutoffs (OBC-NCL / Home State / Gender-Neutral) ---'
-- NIT-UP CSE tightens year on year: 51000 -> 46500 -> 48000 -> 44000.
INSERT INTO cutoff_data (
  academic_year, counselling_process_id, counselling_round_id, round_no, exam_id,
  college_branch_id, college_id, branch_id,
  seat_type_id, category_id, quota_id, gender_id,
  opening_rank, closing_rank, rank_basis
)
SELECT
  cp.academic_year, cp.id, cr.id, cr.round_no, e.id,
  cb.id, cb.college_id, cb.branch_id,
  st.id, st.category_id, q.id, g.id,
  d.closing - 5000, d.closing, 'category_rank'
FROM (VALUES
  ('nit-test-up',  'CSE', 2023, 51000), ('nit-test-up',  'CSE', 2024, 46500),
  ('nit-test-up',  'CSE', 2025, 48000), ('nit-test-up',  'CSE', 2026, 44000),
  ('nit-test-up',  'ECE', 2023, 78000), ('nit-test-up',  'ECE', 2024, 74000),
  ('nit-test-up',  'ECE', 2025, 76000), ('nit-test-up',  'ECE', 2026, 72000),
  ('iiit-test-ka', 'CSE', 2025, 30000), ('iiit-test-ka', 'CSE', 2026, 28000)
) AS d(slug, branch_code, yr, closing)
JOIN colleges col          ON col.slug = d.slug
JOIN branches b            ON b.code = d.branch_code
JOIN college_branches cb   ON cb.college_id = col.id AND cb.branch_id = b.id
JOIN counselling_processes cp ON cp.code = 'JOSAA_' || d.yr
JOIN counselling_rounds cr ON cr.counselling_process_id = cp.id
JOIN exams e               ON e.code = 'JEE_MAIN'
JOIN seat_types st         ON st.code = 'OBC_NCL'
JOIN quotas q              ON q.code = 'HS'
JOIN genders g             ON g.code = 'GENDER_NEUTRAL';

\echo '--- 5. category_id auto-synced from seat_type_id? ---'
SELECT CASE WHEN count(*) = 0 THEN 'PASS' ELSE 'FAIL: ' || count(*) || ' mismatched rows' END AS category_sync
FROM cutoff_data c JOIN seat_types st ON st.id = c.seat_type_id
WHERE c.category_id <> st.category_id;

\echo '--- 6. refresh the trend view ---'
SELECT fn_refresh_cutoff_trend(false);

SELECT cb.program_name, col.short_name,
       t.closing_y0, t.closing_y1, t.closing_y2, t.closing_y3,
       t.best_closing_rank, t.worst_closing_rank, t.years_available,
       round(t.trend_slope) AS trend_slope
FROM mv_program_cutoff_trend t
JOIN college_branches cb ON cb.id = t.college_branch_id
JOIN colleges col ON col.id = t.college_id
ORDER BY col.short_name, cb.program_name;

\echo '--- 7. weighted rank: expect 46400 for NIT-UP CSE (40/30/20/10) ---'
SELECT CASE
         WHEN fn_weighted_rank(44000, 48000, 46500, 51000, NULL, 0.4, 0.3, 0.2, 0.1, 0.0) = 46400
         THEN 'PASS'
         ELSE 'FAIL: got ' || fn_weighted_rank(44000, 48000, 46500, 51000, NULL, 0.4, 0.3, 0.2, 0.1, 0.0)
       END AS weighted_rank;

\echo '--- 8. predict: OBC-NCL male from UP, rank 45821 ---'
SELECT col.short_name, b.code AS branch, p.grade, p.score,
       p.weighted_closing_rank, p.rank_margin, p.years_available
FROM fn_predict_colleges(
       (SELECT id FROM exams WHERE code = 'JEE_MAIN'),
       45821::BIGINT,
       (SELECT id FROM categories WHERE code = 'OBC_NCL'),
       'male'::applicant_gender,
       false,
       (SELECT id FROM states WHERE code = 'UP')
     ) p
JOIN colleges col ON col.id = p.college_id
JOIN branches b   ON b.id = p.branch_id
ORDER BY p.score DESC;

\echo '--- 9. expectations ---'
-- NIT-UP CSE   : weighted 46400, rank 45821 is inside it  -> historical_match
-- NIT-UP ECE   : weighted ~74050, rank well ahead of it   -> strong_historical_match
-- IIIT-KA CSE  : Karnataka college, HS quota, UP student   -> MUST NOT appear
SELECT CASE
         WHEN EXISTS (
           SELECT 1 FROM fn_predict_colleges(
             (SELECT id FROM exams WHERE code = 'JEE_MAIN'), 45821::BIGINT,
             (SELECT id FROM categories WHERE code = 'OBC_NCL'),
             'male'::applicant_gender, false,
             (SELECT id FROM states WHERE code = 'UP')) p
           JOIN colleges c ON c.id = p.college_id
           WHERE c.slug = 'iiit-test-ka')
         THEN 'FAIL: home-state quota leaked an out-of-state college'
         ELSE 'PASS: HS quota correctly excluded the Karnataka college'
       END AS home_state_rule;

ROLLBACK;
