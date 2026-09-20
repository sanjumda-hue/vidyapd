-- Seed: COMEDK counselling, its regional quota and its branch codes.
--
-- COMEDK abbreviates every branch to a two- or three-letter code, and two of
-- them collide with the conventions everyone else uses:
--
--   CE = Computer Engineering   (elsewhere: Civil)
--   CV = Civil Engineering
--
-- So these aliases are tagged with the COMEDK authority and apply only to its
-- imports; the resolver layers them over the global set.
BEGIN;

-- Kalyana Karnataka regional reservation (Article 371J), published as KKR.
INSERT INTO quotas (code, name, requires_home_state_match, requires_other_state, description, display_order)
VALUES ('KKR', 'Kalyana Karnataka Region', false, false,
        'Article 371J regional reservation, published by COMEDK as KKR.', 140)
ON CONFLICT (code) DO NOTHING;

UPDATE quotas SET home_state_id = (SELECT id FROM states WHERE code = 'KA') WHERE code = 'KKR';

INSERT INTO counselling_processes (counselling_authority_id, academic_year, code, name, rank_basis, is_published)
SELECT a.id, y.yr, 'COMEDK_' || y.yr, 'COMEDK ' || y.yr, 'state_merit', true
FROM counselling_authorities a
CROSS JOIN (VALUES (2025), (2026)) AS y(yr)
WHERE a.code = 'COMEDK'
ON CONFLICT (counselling_authority_id, academic_year) DO NOTHING;

INSERT INTO counselling_exams (counselling_process_id, exam_id, is_primary, notes)
SELECT cp.id, e.id, true, 'COMEDK allots on the COMEDK UGET rank.'
FROM counselling_processes cp
JOIN counselling_authorities a ON a.id = cp.counselling_authority_id AND a.code = 'COMEDK'
JOIN exams e ON e.code = 'COMEDK_UGET'
ON CONFLICT (counselling_process_id, exam_id) DO NOTHING;

-- GM is the general merit pool; KKR is the regional one.
INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'seat_type', st.id, m.label, st.name
FROM (VALUES ('GM', 'OPEN'), ('KKR', 'OPEN')) AS m(label, code)
JOIN seat_types st ON st.code = m.code
JOIN counselling_authorities a ON a.code = 'COMEDK'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'quota', q.id, m.label, q.name
FROM (VALUES ('GM', 'HS'), ('KKR', 'KKR')) AS m(label, code)
JOIN quotas q ON q.code = m.code
JOIN counselling_authorities a ON a.code = 'COMEDK'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

COMMIT;

-- COMEDK branch codes, scoped to COMEDK.
BEGIN;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias, counselling_authority_id)
SELECT b.id, m.code, lower(m.code), a.id
FROM (VALUES
  ('AD','DS'),      ('AE','AERO'),   ('AG','AGRI'),   ('AI','AIML'),
  ('AR','ROBO'),    ('AS','AERO'),   ('AU','AUTO'),   ('BDC','IDESIGN'),
  ('BM','BME'),     ('BT','BT'),     ('CA','CSE'),    ('CB','CSE'),
  ('CBD','DS'),     ('CD','DS'),     ('CE','CSE'),    ('CG','CSE'),
  ('CH','CHE'),     ('CI','CSE'),    ('CIT','IT'),    ('CM','CSE'),
  ('CN','CSE'),     ('CO','IOT'),    ('CS','CSE'),    ('CSB','CSE'),
  ('CSD','CSE'),    ('CV','CE'),     ('CY','CYS'),    ('EC','ECE'),
  ('ECE','EE'),     ('ECV','VLSI'),  ('EE','EEE'),    ('EI','INSTR'),
  ('ET','ECE'),     ('IC','CYS'),    ('IM','IPE'),    ('INT','IT'),
  ('IS','IT'),      ('MD','BME'),    ('ME','ME'),     ('RA','ROBO'),
  ('RI','ROBO'),    ('ROB','ROBO'),  ('UE','ECE'),    ('VL','VLSI'),
  ('VLS','VLSI')
) AS m(code, branch_code)
JOIN branches b ON b.code = m.branch_code
JOIN counselling_authorities a ON a.code = 'COMEDK'
ON CONFLICT DO NOTHING;

COMMIT;
