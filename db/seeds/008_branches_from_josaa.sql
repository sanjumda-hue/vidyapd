-- Seed: branches and aliases derived from the real JoSAA programme list.
--
-- JoSAA 2025 prints 254 distinct programme names. The original 28-branch master
-- covered about 60% of the rows; the rest were parked as unresolved. These are
-- the disciplines that were actually missing, plus aliases for the names that
-- map onto branches we already had.
--
-- The resolver strips the "(4 Years, Bachelor of Technology)" suffix before
-- matching, so every alias below is the bare programme name.
BEGIN;

INSERT INTO branches (code, name, stream, is_popular, display_order) VALUES
  ('MSE',      'Materials Science and Engineering',   'core',              false, 300),
  ('ENERGY',   'Energy Engineering',                  'core',              false, 310),
  ('INSTR',    'Instrumentation and Control Engineering', 'electronics',   false, 320),
  ('TEXTILE',  'Textile Technology',                  'core',              false, 330),
  ('CERAMIC',  'Ceramic Engineering',                 'core',              false, 340),
  ('FOODTECH', 'Food Engineering and Technology',     'chemical',          false, 350),
  ('IDESIGN',  'Industrial Design',                   'interdisciplinary', false, 360),
  ('ENGMECH',  'Engineering and Computational Mechanics', 'interdisciplinary', false, 370),
  ('VLSI',     'VLSI Design and Technology',          'electronics',       false, 380),
  ('PHY',      'Physics',                             'interdisciplinary', false, 400),
  ('CHEMSCI',  'Chemistry',                           'interdisciplinary', false, 410),
  ('LIFESCI',  'Life Science',                        'bio',               false, 420),
  ('ECON',     'Economics',                           'other',             false, 430),
  ('SMARTMFG', 'Smart Manufacturing',                 'core',              false, 440)
ON CONFLICT (code) DO NOTHING;

COMMIT;
