-- Seed: categories, genders, quotas, seat_types.
-- These four are the vocabulary the whole cutoff table is expressed in, so they
-- must exist before any import runs.
BEGIN;

INSERT INTO categories (code, name, is_open_pool, display_order) VALUES
  ('OPEN',    'Open',    true,  10),
  ('EWS',     'EWS',     false, 20),
  ('OBC_NCL', 'OBC-NCL', false, 30),
  ('SC',      'SC',      false, 40),
  ('ST',      'ST',      false, 50)
ON CONFLICT (code) DO NOTHING;

-- A female candidate competes in BOTH pools; a male candidate only in the
-- neutral pool. This array is what fn_predict_colleges filters on.
INSERT INTO genders (code, name, allowed_applicant_genders, is_supernumerary, display_order) VALUES
  ('GENDER_NEUTRAL', 'Gender-Neutral',
     ARRAY['male','female','other']::applicant_gender[], false, 10),
  ('FEMALE_ONLY',    'Female-Only (including Supernumerary)',
     ARRAY['female']::applicant_gender[],                true,  20)
ON CONFLICT (code) DO NOTHING;

INSERT INTO quotas (code, name, requires_home_state_match, requires_other_state, description, display_order) VALUES
  ('AI', 'All India',            false, false, 'Open to candidates from every state.', 10),
  ('HS', 'Home State',           true,  false, 'Candidate domicile must match the institute state.', 20),
  ('OS', 'Other State',          false, true,  'Reserved for candidates from outside the institute state.', 30),
  ('GO', 'Goa Quota',            false, false, 'Institute-specific quota.', 40),
  ('JK', 'Jammu and Kashmir',    false, false, 'J&K quota seats.', 50),
  ('LA', 'Ladakh',               false, false, 'Ladakh quota seats.', 60),
  ('AP', 'Andhra Pradesh Quota', false, false, 'AP-specific quota at select institutes.', 70)
ON CONFLICT (code) DO NOTHING;

-- seat_types = category x PwD. Derived rather than hand-listed so the
-- UNIQUE (category_id, is_pwd) constraint can never be violated by a typo.
INSERT INTO seat_types (code, name, category_id, is_pwd, display_order)
SELECT
  c.code || CASE WHEN p.is_pwd THEN '_PWD' ELSE '' END,
  c.name || CASE WHEN p.is_pwd THEN ' (PwD)' ELSE '' END,
  c.id,
  p.is_pwd,
  c.display_order + CASE WHEN p.is_pwd THEN 1 ELSE 0 END
FROM categories c
CROSS JOIN (VALUES (false), (true)) AS p(is_pwd)
ON CONFLICT (code) DO NOTHING;

COMMIT;
