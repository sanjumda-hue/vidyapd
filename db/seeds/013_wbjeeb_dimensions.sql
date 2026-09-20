-- Seed: West Bengal's OBC-A / OBC-B split, and the programmes its feed names.
--
-- West Bengal reserves separately for OBC-A and OBC-B. They are two pools with
-- two closing ranks, so they are two categories -- collapsing them into
-- OBC-NCL would merge different cutoffs and mislead every OBC candidate in the
-- state. Together they are ~1,500 rows per import.
BEGIN;

INSERT INTO categories (code, name, is_open_pool, display_order) VALUES
  ('OBC_A', 'OBC-A (West Bengal)', false, 31),
  ('OBC_B', 'OBC-B (West Bengal)', false, 32)
ON CONFLICT (code) DO NOTHING;

INSERT INTO seat_types (code, name, category_id, is_pwd, display_order)
SELECT c.code || CASE WHEN p.is_pwd THEN '_PWD' ELSE '' END,
       c.name || CASE WHEN p.is_pwd THEN ' (PwD)' ELSE '' END,
       c.id, p.is_pwd, c.display_order + CASE WHEN p.is_pwd THEN 1 ELSE 0 END
FROM categories c
CROSS JOIN (VALUES (false), (true)) AS p(is_pwd)
WHERE c.code IN ('OBC_A', 'OBC_B')
ON CONFLICT (code) DO NOTHING;

INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'seat_type', st.id, m.label, st.name
FROM (VALUES
  ('OBC - A',       'OBC_A'),
  ('OBC - B',       'OBC_B'),
  ('OBC - A (PwD)', 'OBC_A_PWD'),
  ('OBC - B (PwD)', 'OBC_B_PWD')
) AS m(label, code)
JOIN seat_types st ON st.code = m.code
JOIN counselling_authorities a ON a.code = 'WBJEEB'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

COMMIT;

-- Programmes that appear in the WBJEEB feed and nowhere in JoSAA.
BEGIN;

INSERT INTO branches (code, name, stream, is_popular, display_order) VALUES
  ('PHARM',   'Pharmacy',                     'bio',               false, 490),
  ('POLYMER', 'Polymer Science and Technology','chemical',         false, 500),
  ('LEATHER', 'Leather Technology',           'chemical',          false, 510),
  ('OPTICS',  'Optics and Optoelectronics',   'interdisciplinary', false, 520)
ON CONFLICT (code) DO NOTHING;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  ('PHARM',   'B.Pharm/Pharmaceutical Technology'),
  ('PHARM',   'Pharmaceutical Technology'),
  ('ECE',     'Electronics & Tele-Communication Engineering'),
  ('ECE',     '5G'),
  ('EE',      'Power Engineering'),
  ('CE',      'Construction Engineering'),
  ('INSTR',   'Instrumentation & Electronics'),
  ('TEXTILE', 'Jute & Fibre Technology'),
  ('TEXTILE', 'Apparel & Production Management'),
  ('POLYMER', 'Polymer Science & Technology'),
  ('LEATHER', 'Leather Technology'),
  ('ARCH',    'Architectural Engineering'),
  ('ARCH',    'B.ARCH'),
  ('ARCH',    'B ARCH'),
  ('OPTICS',  'Optics & Optoelectronics'),
  ('OTHER',   'PRINTING ENGINEERING'),
  ('OTHER',   'PRINTING & PACKAGING TECHNOLOGY'),
  ('FOODTECH','Dairy Technology'),
  ('IPE',     'INDUSTRIAL ENGINEERING'),
  ('VLSI',    'Semiconductor Technology'),
  ('CSE',     'CLOUD COMPUTING'),
  ('CSE',     'VIRTUAL REALITY'),
  ('CSE',     'AUGMENTED REALITY')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;
