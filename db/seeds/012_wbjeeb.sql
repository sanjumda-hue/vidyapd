-- Seed: WBJEEB counselling, and the dimensions its feed uses.
--
-- Two things about West Bengal that JoSAA does not have:
--
--  1. Tuition Fee Waiver is a real, separately-ranked seat pool with its own
--     cutoff -- about 13% of WBJEEB rows. It is not a social category, but it
--     behaves exactly like one here (its own pool, its own closing rank), so
--     it is modelled as a category rather than bolted on elsewhere.
--  2. One counselling allots on TWO exams: WBJEE ranks and JEE (Main) ranks,
--     in the column WBJEEB labels "Seat Type". Those are different rank
--     series, so the importer is told which exam each file belongs to.
BEGIN;

INSERT INTO categories (code, name, is_open_pool, display_order) VALUES
  ('TFW', 'Tuition Fee Waiver', false, 60)
ON CONFLICT (code) DO NOTHING;

INSERT INTO seat_types (code, name, category_id, is_pwd, display_order)
SELECT 'TFW', 'Tuition Fee Waiver', c.id, false, 60
FROM categories c WHERE c.code = 'TFW'
ON CONFLICT (code) DO NOTHING;

-- One process per year. WBJEEB ranks on a state merit list.
INSERT INTO counselling_processes (counselling_authority_id, academic_year, code, name, rank_basis, is_published)
SELECT a.id, y.yr, 'WBJEEB_' || y.yr, 'WBJEEB ' || y.yr, 'state_merit', true
FROM counselling_authorities a
CROSS JOIN (VALUES (2023), (2024), (2025), (2026)) AS y(yr)
WHERE a.code = 'WBJEEB'
ON CONFLICT (counselling_authority_id, academic_year) DO NOTHING;

INSERT INTO counselling_exams (counselling_process_id, exam_id, is_primary, notes)
SELECT cp.id, e.id, m.is_primary, m.notes
FROM (VALUES
  ('WBJEE',    true,  'Seats allotted on the WBJEE state rank.'),
  ('JEE_MAIN', false, 'Seats allotted on the JEE (Main) rank, in the same counselling.')
) AS m(exam_code, is_primary, notes)
JOIN exams e ON e.code = m.exam_code
JOIN counselling_authorities a ON a.code = 'WBJEEB'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, exam_id) DO NOTHING;

COMMIT;

-- Label mapping. Most WBJEEB labels already match a canonical code or name
-- ("Open", "SC", "Open (PwD)"); these are the ones that do not.
BEGIN;

INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'seat_type', st.id, m.label, st.name
FROM (VALUES
  ('OBC',                'OBC_NCL'),
  ('OBC (PwD)',          'OBC_NCL_PWD'),
  ('Tuition Fee Waiver', 'TFW')
) AS m(label, code)
JOIN seat_types st ON st.code = m.code
JOIN counselling_authorities a ON a.code = 'WBJEEB'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'quota', q.id, m.label, q.name
FROM (VALUES
  ('All India',  'AI'),
  ('Home State', 'HS')
) AS m(label, code)
JOIN quotas q ON q.code = m.code
JOIN counselling_authorities a ON a.code = 'WBJEEB'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

INSERT INTO data_sources (code, name, url, kind, tier, adapter_key, data_type,
                          exam_id, counselling_authority_id, poll_cron, is_active, notes)
SELECT 'WBJEEB_ORCR', 'WBJEEB opening/closing ranks (2021-2026)',
       'https://wbjeeb.nic.in/ewbjee/', 'html', 'official_counselling', 'wbjeeb', 'cutoff',
       e.id, a.id, '0 */6 * * *', false,
       'Whole year as one long-format HTML table, no form driving needed. 2022 and earlier use a different column layout.'
FROM exams e, counselling_authorities a
WHERE e.code = 'WBJEE' AND a.code = 'WBJEEB'
ON CONFLICT (code) DO NOTHING;

COMMIT;
