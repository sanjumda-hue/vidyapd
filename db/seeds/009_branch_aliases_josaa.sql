-- Seed: alias every JoSAA programme name onto a branch.
BEGIN;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  -- computing
  ('CSE',  'Computer Science and Business'),
  ('CSE',  'Computer Science and Artificial Intelligence'),
  ('CSE',  'Computer Science and Engineering (Artificial Intelligence)'),
  ('CSE',  'Computer Science'),
  ('IT',   'Integrated B. Tech.(IT) and M. Tech (IT)'),
  ('IT',   'Information Technology-Business Informatics'),
  ('AIML', 'Artificial Intelligence'),
  ('AIML', 'Artificial Intelligence and Machine Learning'),
  ('DS',   'Artificial Intelligence and Data Engineering'),
  ('DS',   'Artificial Intelligence and Data Analytics'),
  ('DS',   'Data Science and Engineering'),
  ('MATH', 'Mathematics & Computing'),
  ('MATH', 'Mathematics and Computing'),
  ('MATH', 'Mathematics and Scientific Computing'),
  -- electronics and electrical
  ('ECE',  'Electronics Engineering'),
  ('ECE',  'Electronics and Telecommunication Engineering'),
  ('ECE',  'Electronics and Electrical Communication Engineering'),
  ('ECE',  'Electronics and Communication Engineering (Design and Manufacturing)'),
  ('ECE',  'Industrial Internet of Things'),
  ('VLSI', 'Electronics and VLSI Engineering'),
  ('VLSI', 'Microelectronics & VLSI Engineering'),
  ('VLSI', 'Electronics Engineering (VLSI Design and Technology)'),
  ('VLSI', 'VLSI Design and Technology'),
  ('INSTR','Electronics and Instrumentation Engineering'),
  ('INSTR','Instrumentation Engineering'),
  ('INSTR','Instrumentation and Control Engineering'),
  ('EEE',  'Electrical and Electronics Engineering'),
  ('EE',   'Electrical Engineering (Power and Automation)'),
  -- mechanical, production, materials
  ('IPE',  'Production and Industrial Engineering'),
  ('IPE',  'Production Engineering'),
  ('IPE',  'Industrial and Production Engineering'),
  ('MECHTR','Mechatronics and Automation Engineering'),
  ('ROBO', 'ROBOTICS & AUTOMATION'),
  ('ROBO', 'Robotics and Automation'),
  ('MSE',  'Materials Engineering'),
  ('MSE',  'Materials Science and Engineering'),
  ('MME',  'Metallurgy and Materials Engineering'),
  ('MME',  'Metallurgical Engineering and Materials Science'),
  ('MME',  'Materials Science and Metallurgical Engineering'),
  ('MME',  'Metallurgical and Materials Engineering'),
  ('ENGMECH','Engineering and Computational Mechanics'),
  ('ENGMECH','Computational Engineering and Mechanics'),
  ('ENGMECH','B. Tech. and M. Tech. in Engineering and Computational Mechanics (Dual Degree)'),
  ('SMARTMFG','Smart Manufacturing'),
  ('IDESIGN','Industrial Design'),
  -- civil, chemical, energy
  ('CE',   'Civil and Infrastructure Engineering'),
  ('CHE',  'Industrial Chemistry'),
  ('CHE',  'Chemical Science and Technology'),
  ('ENERGY','Energy Engineering'),
  ('ENERGY','SUSTAINABLE ENERGY TECHNOLOGIES'),
  ('ENERGY','Energy and Electrical Vehicle Engineering'),
  ('ENERGY','Energy Science and Engineering'),
  -- bio, food, textile, ceramic
  ('BT',   'Bio Technology'),
  ('BT',   'Biotechnology and Biochemical Engineering'),
  ('BME',  'Bio Medical Engineering'),
  ('BME',  'Bio Engineering'),
  ('LIFESCI','Life Science'),
  ('LIFESCI','Biosciences and Bioengineering'),
  ('LIFESCI','Biological Sciences and Bioengineering'),
  ('FOODTECH','Food Technology'),
  ('FOODTECH','Food Process Engineering'),
  ('FOODTECH','Food Engineering and Technology'),
  ('AGRI', 'Agricultural and Food Engineering'),
  ('TEXTILE','Textile Technology'),
  ('TEXTILE','Handloom and Textile Technology'),
  ('CERAMIC','Ceramic Engineering'),
  -- sciences
  ('PHY',  'Physics'),
  ('PHY',  'Engineering Physics'),
  ('CHEMSCI','Chemistry'),
  ('ECON', 'Economics')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;
