-- Seed: exam master and counselling authorities.
--
-- Dates are NOT seeded here. Every date in this system must arrive through an
-- import job with a data_source behind it, so the app can always tell a student
-- where a date came from and when it was last checked.
BEGIN;

INSERT INTO exams (code, name, short_name, level, conducting_authority, official_website,
                   home_state_id, primary_score_type, has_rank, has_percentile, has_marks,
                   is_multi_session, display_order)
SELECT e.code, e.name, e.short_name, e.level::exam_level, e.authority, e.website,
       s.id, e.score_type::score_type, e.has_rank, e.has_percentile, e.has_marks,
       e.multi_session, e.display_order
FROM (VALUES
  ('JEE_MAIN', 'Joint Entrance Examination (Main)', 'JEE Main', 'national',
   'National Testing Agency', 'https://jeemain.nta.nic.in', NULL, 'rank', true, true, true, true, 10),
  ('JEE_ADVANCED', 'Joint Entrance Examination (Advanced)', 'JEE Adv', 'national',
   'IIT (rotating organising institute)', 'https://jeeadv.ac.in', NULL, 'rank', true, false, true, false, 20),
  ('BITSAT', 'BITS Admission Test', 'BITSAT', 'deemed',
   'BITS Pilani', 'https://www.bitsadmission.com', NULL, 'marks', false, false, true, true, 30),
  ('VITEEE', 'VIT Engineering Entrance Examination', 'VITEEE', 'university',
   'Vellore Institute of Technology', 'https://viteee.vit.ac.in', NULL, 'rank', true, false, true, false, 40),
  ('SRMJEEE', 'SRM Joint Engineering Entrance Exam', 'SRMJEEE', 'university',
   'SRM Institute of Science and Technology', 'https://www.srmist.edu.in', NULL, 'rank', true, false, true, true, 50)
  ,('COMEDK_UGET', 'COMEDK Undergraduate Entrance Test', 'COMEDK', 'state',
   'Karnataka Professional Colleges Foundation', 'https://www.comedk.org', 'KA', 'rank', true, false, true, false, 60),
  ('MHT_CET', 'Maharashtra Common Entrance Test', 'MHT-CET', 'state',
   'State CET Cell, Maharashtra', 'https://cetcell.mahacet.org', 'MH', 'percentile', true, true, true, false, 70),
  ('KCET', 'Karnataka Common Entrance Test', 'KCET', 'state',
   'Karnataka Examinations Authority', 'https://cetonline.karnataka.gov.in', 'KA', 'rank', true, false, true, false, 80),
  ('WBJEE', 'West Bengal Joint Entrance Examination', 'WBJEE', 'state',
   'West Bengal Joint Entrance Examinations Board', 'https://wbjeeb.nic.in', 'WB', 'rank', true, false, true, false, 90),
  ('UPCET', 'Uttar Pradesh Combined Entrance Test', 'UPCET', 'state',
   'AKTU / UPTAC', 'https://uptac.admissions.nic.in', 'UP', 'rank', true, false, true, false, 100),
  ('OJEE', 'Odisha Joint Entrance Examination', 'OJEE', 'state',
   'OJEE Board', 'https://ojee.nic.in', 'OD', 'rank', true, false, true, false, 110),
  ('BCECE', 'Bihar Combined Entrance Competitive Exam', 'BCECE', 'state',
   'BCECE Board', 'https://bceceboard.bihar.gov.in', 'BR', 'rank', true, false, true, false, 120),
  ('GUJCET', 'Gujarat Common Entrance Test', 'GUJCET', 'state',
   'Gujarat Secondary and Higher Secondary Education Board', 'https://gseb.org', 'GJ', 'rank', true, false, true, false, 130)
  ,('AP_EAPCET', 'AP Engineering, Agriculture and Pharmacy CET', 'AP EAPCET', 'state',
   'APSCHE', 'https://cets.apsche.ap.gov.in', 'AP', 'rank', true, false, true, false, 140),
  ('TS_EAMCET', 'TS Engineering, Agriculture and Medical CET', 'TS EAMCET', 'state',
   'TSCHE', 'https://eapcet.tsche.ac.in', 'TS', 'rank', true, false, true, false, 150),
  ('KEAM', 'Kerala Engineering Architecture Medical', 'KEAM', 'state',
   'Commissioner for Entrance Examinations, Kerala', 'https://cee.kerala.gov.in', 'KL', 'rank', true, false, true, false, 160),
  ('TNEA', 'Tamil Nadu Engineering Admissions', 'TNEA', 'state',
   'Directorate of Technical Education, Tamil Nadu', 'https://www.tneaonline.org', 'TN', 'rank', true, false, true, false, 170)
) AS e(code, name, short_name, level, authority, website, state_code, score_type,
       has_rank, has_percentile, has_marks, multi_session, display_order)
LEFT JOIN states s ON s.code = e.state_code
ON CONFLICT (code) DO NOTHING;

INSERT INTO counselling_authorities (code, name, scope, state_id, official_website, description)
SELECT a.code, a.name, a.scope::counselling_scope, s.id, a.website, a.description
FROM (VALUES
  ('JOSAA', 'Joint Seat Allocation Authority', 'national', NULL,
   'https://josaa.nic.in', 'Allocates seats across IITs, NITs, IIITs and GFTIs.'),
  ('CSAB', 'Central Seat Allocation Board', 'national', NULL,
   'https://csab.nic.in', 'Special rounds after JoSAA for NIT+ vacancies.'),
  ('COMEDK', 'Karnataka Professional Colleges Foundation', 'state', 'KA',
   'https://www.comedk.org', 'Private engineering counselling in Karnataka.'),
  ('KEA', 'Karnataka Examinations Authority', 'state', 'KA',
   'https://cetonline.karnataka.gov.in', 'KCET counselling.'),
  ('MAHACET', 'State CET Cell, Maharashtra', 'state', 'MH',
   'https://cetcell.mahacet.org', 'MHT-CET based engineering admissions.'),
  ('UPTAC', 'UP Technical Admission Counselling', 'state', 'UP',
   'https://uptac.admissions.nic.in', 'AKTU-affiliated college counselling.'),
  ('WBJEEB', 'West Bengal Joint Entrance Examinations Board', 'state', 'WB',
   'https://wbjeeb.nic.in', 'WBJEE counselling.'),
  ('ACPC', 'Admission Committee for Professional Courses', 'state', 'GJ',
   'https://jacpcldce.ac.in', 'Gujarat engineering admissions.'),
  ('DOTE_TN', 'Directorate of Technical Education, Tamil Nadu', 'state', 'TN',
   'https://www.tneaonline.org', 'Tamil Nadu engineering admissions.'),
  ('APSCHE', 'Andhra Pradesh State Council of Higher Education', 'state', 'AP',
   'https://cets.apsche.ap.gov.in', 'AP EAPCET counselling.')
) AS a(code, name, scope, state_code, website, description)
LEFT JOIN states s ON s.code = a.state_code
ON CONFLICT (code) DO NOTHING;

COMMIT;
