-- Seed: CSAB quota labels.
--
-- CSAB carries quotas JoSAA does not, and spells the UT ones differently.
--
-- DASA is the Direct Admission of Students Abroad channel, split into CIWG
-- (Children of Indian Workers in the Gulf) and non-CIWG. It is a separate
-- admission route with its own eligibility, so it gets its own quotas: an
-- ordinary domestic candidate then simply never matches those seats, which is
-- the correct outcome rather than a filtered-out one.
BEGIN;

INSERT INTO quotas (code, name, requires_home_state_match, requires_other_state, description, display_order) VALUES
  ('DASA_CIWG',     'DASA (CIWG)',     false, false, 'Direct Admission of Students Abroad - Children of Indian Workers in the Gulf.', 100),
  ('DASA_NON_CIWG', 'DASA (non-CIWG)', false, false, 'Direct Admission of Students Abroad, general.', 110),
  ('DC',            'DASA Category',   false, false, 'CSAB DASA-linked supernumerary seats.', 120),
  ('AD',            'Additional',      false, false, 'CSAB additional supernumerary seats.', 130)
ON CONFLICT (code) DO NOTHING;

INSERT INTO counselling_dimension_map
  (counselling_process_id, dimension, ref_id, source_label, display_label)
SELECT cp.id, 'quota', q.id, m.label, q.name
FROM (VALUES
  ('DASA-CIWG',            'DASA_CIWG'),
  ('DASA-Non CIWG',        'DASA_NON_CIWG'),
  ('DC',                   'DC'),
  ('AD',                   'AD'),
  ('Jammu & Kashmir (UT)', 'JK'),
  ('Ladakh (UT)',          'LA'),
  ('Home State for Goa',   'GO')
) AS m(label, code)
JOIN quotas q ON q.code = m.code
JOIN counselling_authorities a ON a.code = 'CSAB'
JOIN counselling_processes cp ON cp.counselling_authority_id = a.id
ON CONFLICT (counselling_process_id, dimension, source_label) DO NOTHING;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias)
SELECT b.id, a.alias, lower(regexp_replace(a.alias, '[^a-zA-Z0-9]+', ' ', 'g'))
FROM (VALUES
  ('ECE', 'Electronics System Engineering'),
  ('CSE', 'Cyber Physical Systems'),
  ('CSE', 'Software Engineering')
) AS a(branch_code, alias)
JOIN branches b ON b.code = a.branch_code
ON CONFLICT DO NOTHING;

COMMIT;
