-- Seed: the long tail of JoSAA programme names.
--
-- After the main alias pass 95% of rows resolved; these cover the rest.
-- Deliberately NOT mapped to a catch-all: lumping Applied Geology in with
-- "Other" would make branch filtering lie to students.
BEGIN;

INSERT INTO branches (code, name, stream, is_popular, display_order) VALUES
  ('EARTHSCI', 'Earth Sciences and Geology', 'interdisciplinary', false, 450)
ON CONFLICT (code) DO NOTHING;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  ('MATH',    'Mathematics'),
  ('MATH',    'Computational Mathematics'),
  ('EARTHSCI','Applied Geology'),
  ('EARTHSCI','Geological Technology'),
  ('EARTHSCI','Geophysical Technology'),
  ('EARTHSCI','Earth Sciences'),
  ('IDESIGN', 'Engineering Design'),
  ('IDESIGN', 'Design Engineering'),
  ('IDESIGN', 'Design'),
  ('IDESIGN', 'Bachelor of Design'),
  ('IPE',     'Industrial Engineering and Operations Research'),
  ('IPE',     'Industrial and Systems Engineering'),
  ('ENV',     'Environmental Science and Engineering'),
  ('CHE',     'Chemical Technology'),
  ('CHE',     'Pharmaceutical Engineering & Technology'),
  ('LIFESCI', 'Biological Engineering'),
  ('LIFESCI', 'Bioengineering'),
  ('LIFESCI', 'Biological Science'),
  ('MSE',     'Material Science and Engineering'),
  ('MSE',     'Materials Science and Technology'),
  ('SMARTMFG','Manufacturing Science and Engineering'),
  ('MME',     'Mineral and Metallurgical Engineering'),
  ('MME',     'Metallurgical Engineering'),
  ('VLSI',    'Integrated Circuit Design & Technology'),
  ('VLSI',    'Microelectronics & VLSI'),
  ('ENGMECH', 'Computational Engineering'),
  ('ENGMECH', 'Engineering Science'),
  ('MIN',     'Mining Machinery Engineering'),
  ('CHEMSCI', 'Chemical Sciences'),
  ('CHEMSCI', 'Chemical Science'),
  ('PHY',     'Physical Science'),
  ('AERO',    'Space Science and Engineering'),
  ('AERO',    'Aeronautical Engineering'),
  ('AERO',    'Aviation Engineering'),
  ('AGRI',    'Digital Agriculture'),
  ('AGRI',    'Dairy Engineering'),
  ('ROBO',    'Robotics and AI'),
  ('ECE',     'Electronic Engineering'),
  ('ECE',     'Electronics & Communication Engineering'),
  ('TEXTILE', 'Fashion and Apparel Engineering'),
  ('CSE',     'CSE'),
  ('CE',      'B. Tech in CE. - M. Tech. in Geotechnical Engineering'),
  ('CE',      'B. Tech in CE. - M. Tech. in Structural Engineering'),
  ('OTHER',   'Interdisciplinary Sciences'),
  ('OTHER',   'General Engineering'),
  ('OTHER',   'Animation and VFX'),
  ('OTHER',   'Printing and Packaging Technology')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;
