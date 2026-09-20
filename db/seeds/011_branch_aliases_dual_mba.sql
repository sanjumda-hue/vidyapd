-- Seed: the last ~0.2% of JoSAA programme names.
--
-- These are B.Tech + MBA dual degrees, where the engineering discipline sits
-- in the first bracket and the rest of the string is about the management half:
--
--   B.Tech (Artificial Intelligence and Data Science) - MBA in Digital
--     Business Management (IIM Bodh Gaya) (5 Years, ...)
--
-- The resolver already pulls the bracketed discipline out; these rows failed
-- only because that particular discipline had no alias. One entry is a typo in
-- the official feed ("Elctrical") -- aliasing it is the honest fix, since
-- correcting the source is not an option.
BEGIN;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  ('DS',   'Artificial Intelligence and Data Science'),
  ('EE',   'Elctrical Engineering'),          -- sic: typo in the JoSAA feed
  ('EE',   'Electrical Engineering - MBA'),
  ('CSE',  'Computer Science and Engineering - MBA'),
  ('IT',   'Integrated B. Tech.(IT) and MBA'),
  ('ECE',  'Electronics and Communication Engineering - MBA'),
  ('ME',   'Mechanical Engineering - MBA'),
  ('CE',   'Civil Engineering - MBA')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;

-- 2026 introduced disciplines that did not exist in the 2023-2025 feeds.
BEGIN;

INSERT INTO branches (code, name, stream, is_popular, display_order) VALUES
  ('IOT',     'Internet of Things',              'computing',         false, 460),
  ('QUANTUM', 'Quantum Science and Engineering', 'interdisciplinary', false, 470),
  ('MARINE',  'Maritime and Ocean Engineering',  'core',              false, 480)
ON CONFLICT (code) DO NOTHING;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  ('IOT',     'Internet of Things'),
  ('IOT',     'Digital Manufacturing and IoT'),
  ('QUANTUM', 'Quantum Science and Engineering'),
  ('MARINE',  'Maritime Engineering'),
  ('MARINE',  'Ocean Engineering and Naval Architecture'),
  ('AIML',    'Intelligent Systems'),
  ('ENGMECH', 'Unified Engineering'),
  ('ENGMECH', 'Mechanics and Computing'),
  ('EARTHSCI','Geological Engineering')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;
