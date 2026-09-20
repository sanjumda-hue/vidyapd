-- Seed: UPTAC gender label and the programmes unique to its feed.
--
-- "Co-Education" is the literal value in UPTAC's Seat Gender column and means
-- the seat is not gender-restricted. Mapping it directly is better than
-- relying on the compound-category fallback, which does not cover codes
-- outside the category x sub-quota grid (TFW, for one).
BEGIN;

INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'gender', g.id, m.label, g.name
FROM (VALUES ('Co-Education', 'GENDER_NEUTRAL'), ('Girls', 'FEMALE_ONLY')) AS m(label, code)
JOIN genders g ON g.code = m.code
JOIN counselling_authorities a ON a.code = 'UPTAC'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

-- TFW carries no category prefix, so it needs its own quota row too.
INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'quota', q.id, 'TFW', q.name
FROM quotas q
JOIN counselling_authorities a ON a.code = 'UPTAC'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
WHERE q.code = 'HS'
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

INSERT INTO branches (code, name, stream, is_popular, display_order) VALUES
  ('PLASTIC', 'Plastic Engineering', 'chemical', false, 530)
ON CONFLICT (code) DO NOTHING;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  ('CSE',      'Electrical & Computer Engg.'),
  ('CSE',      'Computer Science'),
  ('ECE',      'Electronics and Communication'),
  ('SMARTMFG', 'Manufacturing Technology'),
  ('PLASTIC',  'Plastic Engineering'),
  ('TEXTILE',  'Carpet & Textile Technology'),
  ('ROBO',     'Automation and Robotics'),
  ('FOODTECH', 'Food Engineering & Technology'),
  ('AIML',     'Artificial Intelligence And Machine Learning')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;
