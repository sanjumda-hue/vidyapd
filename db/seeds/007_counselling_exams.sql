-- Seed: which exam each counselling process allots on.
--
-- publish() needs a primary exam per process to stamp on every cutoff row.
-- JoSAA is the interesting case: JEE Advanced governs IIT seats and JEE Main
-- governs everything else, so both are linked and applies_to_college_types
-- says which is which.
BEGIN;

INSERT INTO counselling_exams (counselling_process_id, exam_id, applies_to_college_types, is_primary, notes)
SELECT cp.id, e.id, m.types::college_type[], m.is_primary, m.notes
FROM (VALUES
  ('JOSAA',  'JEE_MAIN',     ARRAY['NIT','IIIT','GFTI'],  true,  'NIT+ seats.'),
  ('JOSAA',  'JEE_ADVANCED', ARRAY['IIT'],                false, 'IIT seats only.'),
  ('CSAB',   'JEE_MAIN',     NULL,                        true,  NULL),
  ('COMEDK', 'COMEDK_UGET',  NULL,                        true,  NULL),
  ('KEA',    'KCET',         NULL,                        true,  NULL),
  ('MAHACET','MHT_CET',      NULL,                        true,  NULL),
  ('UPTAC',  'UPCET',        NULL,                        true,  NULL),
  ('WBJEEB', 'WBJEE',        NULL,                        true,  NULL)
) AS m(authority_code, exam_code, types, is_primary, notes)
JOIN counselling_authorities a ON a.code = m.authority_code
JOIN counselling_processes cp  ON cp.counselling_authority_id = a.id
JOIN exams e                   ON e.code = m.exam_code
ON CONFLICT (counselling_process_id, exam_id) DO NOTHING;

COMMIT;
