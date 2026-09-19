-- =============================================================================
-- DEVELOPMENT DATA ONLY -- NOT REAL CUTOFFS.
--
-- Every college here is named "... (DEMO)" on purpose. These numbers are made
-- up so the app has something to render; they must never be mistaken for
-- published ranks. Never load this into production:
--
--   node db/migrate.js seed-dev        (refuses when NODE_ENV=production)
-- =============================================================================

BEGIN;

INSERT INTO counselling_processes (counselling_authority_id, academic_year, code, name, rank_basis, is_published)
SELECT a.id, y.yr, 'JOSAA_' || y.yr, 'JoSAA ' || y.yr, 'category_rank', true
FROM counselling_authorities a
CROSS JOIN (VALUES (2023), (2024), (2025), (2026)) AS y(yr)
WHERE a.code = 'JOSAA'
ON CONFLICT (counselling_authority_id, academic_year) DO NOTHING;

INSERT INTO counselling_rounds (counselling_process_id, round_no, name, is_final_regular_round, cutoff_published)
SELECT cp.id, 5, 'Round 5', true, true
FROM counselling_processes cp
WHERE cp.code LIKE 'JOSAA_20%'
ON CONFLICT (counselling_process_id, round_no, kind) DO NOTHING;

INSERT INTO colleges (slug, name, short_name, college_type, ownership, state_id, established_year, has_hostel, nirf_rank_latest, nirf_year_latest)
SELECT d.slug, d.name, d.short_name, d.ctype::college_type, d.own::ownership_type, s.id, d.est, true, d.nirf, 2026
FROM (VALUES
  ('demo-iit-up',   'Institute of Technology Demo, Kanpur (DEMO)', 'IIT Demo UP',  'IIT',        'government', 1959,  4),
  ('demo-nit-up',   'National Institute Demo, Allahabad (DEMO)',   'NIT Demo UP',  'NIT',        'government', 1961, 42),
  ('demo-nit-ka',   'National Institute Demo, Surathkal (DEMO)',   'NIT Demo KA',  'NIT',        'government', 1960, 17),
  ('demo-iiit-mh',  'IIIT Demo, Pune (DEMO)',                      'IIIT Demo MH', 'IIIT',       'public_private_partnership', 2016, 88),
  ('demo-govt-dl',  'Delhi Technical Demo College (DEMO)',         'DTC Demo',     'STATE_GOVT', 'government', 1941, 58),
  ('demo-priv-ka',  'Bangalore Private Demo Institute (DEMO)',     'BPDI Demo',    'PRIVATE',    'private',    1979, 96)
) AS d(slug, name, short_name, ctype, own, est, nirf)
JOIN states s ON s.code = CASE d.slug
  WHEN 'demo-iit-up'  THEN 'UP' WHEN 'demo-nit-up' THEN 'UP'
  WHEN 'demo-nit-ka'  THEN 'KA' WHEN 'demo-iiit-mh' THEN 'MH'
  WHEN 'demo-govt-dl' THEN 'DL' ELSE 'KA' END
ON CONFLICT (slug) DO NOTHING;

INSERT INTO college_branches (college_id, branch_id, program_name, degree, total_intake)
SELECT c.id, b.id, b.name || ' (4 Years, Bachelor of Technology)', 'BTech', 90
FROM colleges c
CROSS JOIN branches b
WHERE c.slug LIKE 'demo-%'
  AND b.code IN ('CSE', 'IT', 'ECE', 'EE', 'ME', 'CE')
ON CONFLICT DO NOTHING;

COMMIT;
