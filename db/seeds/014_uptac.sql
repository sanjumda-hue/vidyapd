-- Seed: UPTAC counselling and its compound category codes.
--
-- UPTAC encodes the whole reservation expression in one code: a two- or
-- three-letter category followed by a two-letter sub-quota.
--
--   OP=Open  BC=Backward Class  EWS  SC  ST
--   NO=none  GL=Girls  PH=PwD  AF=Armed Forces  FF=Freedom Fighter
--
-- So BCGL is "Backward Class, girls' seat" and EWSPH is "EWS, PwD seat".
-- That decomposes cleanly onto the three dimensions this schema already has:
--   category prefix -> seat_type,  PH -> the PwD seat type,
--   GL -> gender FEMALE_ONLY,      AF/FF -> their own quotas.
-- Nothing is lost and no dimension is overloaded.
BEGIN;

INSERT INTO quotas (code, name, requires_home_state_match, requires_other_state, description, display_order) VALUES
  ('AF', 'Armed Forces',    false, false, 'Supernumerary seats for wards of armed forces personnel (UPTAC).', 80),
  ('FF', 'Freedom Fighter', false, false, 'Supernumerary seats for wards of freedom fighters (UPTAC).',      90)
ON CONFLICT (code) DO NOTHING;

INSERT INTO counselling_processes (counselling_authority_id, academic_year, code, name, rank_basis, is_published)
SELECT a.id, 2026, 'UPTAC_2026', 'UPTAC 2026', 'state_merit', true
FROM counselling_authorities a WHERE a.code = 'UPTAC'
ON CONFLICT (counselling_authority_id, academic_year) DO NOTHING;

INSERT INTO counselling_exams (counselling_process_id, exam_id, is_primary, notes)
SELECT cp.id, e.id, true, 'UPTAC allots B.Tech seats on the JEE (Main) rank.'
FROM counselling_processes cp
JOIN counselling_authorities a ON a.id = cp.counselling_authority_id AND a.code = 'UPTAC'
JOIN exams e ON e.code = 'JEE_MAIN'
ON CONFLICT (counselling_process_id, exam_id) DO NOTHING;

COMMIT;

-- Decode the 27 compound codes across all three dimensions. The same label
-- appears under more than one dimension on purpose: "BCGL" is both a seat type
-- (OBC-NCL) and a gender pool (female-only).
BEGIN;

-- seat type, from the category prefix; PH selects the PwD variant
INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'seat_type', st.id, c.prefix || s.suffix, st.name
FROM (VALUES ('OP','OPEN'), ('BC','OBC_NCL'), ('EWS','EWS'), ('SC','SC'), ('ST','ST'))
       AS c(prefix, base)
CROSS JOIN (VALUES ('NO'), ('GL'), ('PH'), ('AF'), ('FF')) AS s(suffix)
JOIN seat_types st ON st.code = c.base || CASE WHEN s.suffix = 'PH' THEN '_PWD' ELSE '' END
JOIN counselling_authorities a ON a.code = 'UPTAC'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'seat_type', st.id, 'TFW', st.name
FROM seat_types st
JOIN counselling_authorities a ON a.code = 'UPTAC'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
WHERE st.code = 'TFW'
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

-- gender: GL is a girls' seat, everything else is the neutral pool
INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'gender', g.id, c.prefix || s.suffix, g.name
FROM (VALUES ('OP'), ('BC'), ('EWS'), ('SC'), ('ST')) AS c(prefix)
CROSS JOIN (VALUES ('NO'), ('GL'), ('PH'), ('AF'), ('FF')) AS s(suffix)
JOIN genders g ON g.code = CASE WHEN s.suffix = 'GL' THEN 'FEMALE_ONLY' ELSE 'GENDER_NEUTRAL' END
JOIN counselling_authorities a ON a.code = 'UPTAC'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

-- quota: AF and FF are supernumerary pools, the rest are ordinary home-state
INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'quota', q.id, c.prefix || s.suffix, q.name
FROM (VALUES ('OP'), ('BC'), ('EWS'), ('SC'), ('ST')) AS c(prefix)
CROSS JOIN (VALUES ('NO'), ('GL'), ('PH'), ('AF'), ('FF')) AS s(suffix)
JOIN quotas q ON q.code = CASE s.suffix WHEN 'AF' THEN 'AF' WHEN 'FF' THEN 'FF' ELSE 'HS' END
JOIN counselling_authorities a ON a.code = 'UPTAC'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

COMMIT;

-- The Samarth source is separate from the old NIC one: different host,
-- different platform, and the NIC report now 500s.
BEGIN;

INSERT INTO data_sources (code, name, url, kind, tier, adapter_key, data_type,
                          exam_id, counselling_authority_id, poll_cron, is_active, notes)
SELECT 'UPTAC_SAMARTH', 'UPTAC cut-off matrix (Samarth platform)',
       'https://uptac.samarth.edu.in/index.php/cut-off-matrix/index',
       'html', 'official_counselling', 'uptac_samarth', 'cutoff',
       e.id, a.id, '0 */6 * * *', false,
       'Paginated long-format table, per-page capped at 50 server side (~534 pages for B.Tech). robots.txt allows everything. Compound category codes such as BCGL are decoded through counselling_dimension_map.'
FROM exams e, counselling_authorities a
WHERE e.code = 'JEE_MAIN' AND a.code = 'UPTAC'
ON CONFLICT (code) DO NOTHING;

COMMIT;
