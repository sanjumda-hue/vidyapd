-- Seed: branch master and popular specializations (design doc section 6).
BEGIN;

INSERT INTO branches (code, name, stream, is_popular, display_order) VALUES
  ('CSE',    'Computer Science and Engineering',      'computing',         true,  10),
  ('IT',     'Information Technology',                'computing',         true,  20),
  ('AIML',   'Artificial Intelligence and Machine Learning', 'computing',  true,  30),
  ('DS',     'Data Science',                          'computing',         true,  40),
  ('CYS',    'Cyber Security',                        'computing',         true,  50),
  ('ECE',    'Electronics and Communication Engineering', 'electronics',   true,  60),
  ('EEE',    'Electrical and Electronics Engineering','electrical',        true,  70),
  ('EE',     'Electrical Engineering',                'electrical',        true,  80),
  ('ME',     'Mechanical Engineering',                'core',              true,  90),
  ('CE',     'Civil Engineering',                     'core',              true, 100),
  ('CHE',    'Chemical Engineering',                  'chemical',          true, 110),
  ('BT',     'Biotechnology',                         'bio',               true, 120),
  ('ROBO',   'Robotics and Automation',               'interdisciplinary', true, 130),
  ('AERO',   'Aerospace Engineering',                 'core',              true, 140),
  ('AUTO',   'Automobile Engineering',                'core',              false,150),
  ('MECHTR', 'Mechatronics Engineering',              'interdisciplinary', false,160),
  ('IPE',    'Industrial and Production Engineering', 'core',              false,170),
  ('MME',    'Metallurgical and Materials Engineering','core',             false,180),
  ('MIN',    'Mining Engineering',                    'core',              false,190),
  ('PE',     'Petroleum Engineering',                 'chemical',          false,200),
  ('BME',    'Biomedical Engineering',                'bio',               false,210),
  ('AGRI',   'Agricultural Engineering',              'core',              false,220),
  ('ENV',    'Environmental Engineering',             'core',              false,230),
  ('ARCH',   'Architecture',                          'other',             false,240),
  ('PLAN',   'Planning',                              'other',             false,250),
  ('MATH',   'Mathematics and Computing',             'interdisciplinary', false,260),
  ('ENGP',   'Engineering Physics',                   'interdisciplinary', false,270),
  ('OTHER',  'Other',                                 'other',             false,999)
ON CONFLICT (code) DO NOTHING;

INSERT INTO specializations (branch_id, code, name, is_popular, display_order)
SELECT b.id, s.code, s.name, s.is_popular, s.display_order
FROM (VALUES
  ('CSE', 'CSE_AI',        'CSE (Artificial Intelligence)',        true,  10),
  ('CSE', 'CSE_DS',        'CSE (Data Science)',                   true,  20),
  ('CSE', 'CSE_CYS',       'CSE (Cyber Security)',                 true,  30),
  ('CSE', 'CSE_AIML',      'CSE (AI and Machine Learning)',        true,  40),
  ('CSE', 'CSE_IOT',       'CSE (Internet of Things)',             false, 50),
  ('CSE', 'CSE_BLOCKCHAIN','CSE (Blockchain Technology)',          false, 60),
  ('CSE', 'CSE_SE',        'CSE (Software Engineering)',           false, 70),
  ('CSE', 'CSE_CLOUD',     'CSE (Cloud Computing)',                false, 80),
  ('ECE', 'ECE_VLSI',      'ECE (VLSI Design)',                    false, 10),
  ('ECE', 'ECE_EMBEDDED',  'ECE (Embedded Systems)',               false, 20),
  ('ME',  'ME_THERMAL',    'Mechanical (Thermal Engineering)',     false, 10),
  ('ME',  'ME_DESIGN',     'Mechanical (Design)',                  false, 20),
  ('CE',  'CE_STRUCT',     'Civil (Structural Engineering)',       false, 10),
  ('BT',  'BT_BIOINFO',    'Biotechnology (Bioinformatics)',       false, 10)
) AS s(branch_code, code, name, is_popular, display_order)
JOIN branches b ON b.code = s.branch_code
ON CONFLICT (code) DO NOTHING;

-- Aliases the importers resolve against before falling back to trigram match.
INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  ('CSE', 'Computer Science and Engineering'),
  ('CSE', 'Computer Science & Engineering'),
  ('CSE', 'Computer Science Engineering'),
  ('CSE', 'Computer Engineering'),
  ('CSE', 'Computer Science and Engg.'),
  ('IT',  'Information Technology'),
  ('ECE', 'Electronics and Communication Engineering'),
  ('ECE', 'Electronics & Communication Engg.'),
  ('ECE', 'Electronics and Communications Engineering'),
  ('EEE', 'Electrical and Electronics Engineering'),
  ('EE',  'Electrical Engineering'),
  ('ME',  'Mechanical Engineering'),
  ('CE',  'Civil Engineering'),
  ('CHE', 'Chemical Engineering'),
  ('MME', 'Metallurgical and Materials Engineering'),
  ('IPE', 'Industrial and Production Engineering'),
  ('MATH','Mathematics and Computing'),
  ('ENGP','Engineering Physics')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;
