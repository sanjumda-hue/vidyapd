-- Seed: BITS Pilani, the first institute-scope authority and the first feed
-- that publishes a score instead of a rank.
--
-- BITS runs no counselling authority in the usual sense -- it admits directly
-- off its own BITSAT merit list -- but everything downstream (processes,
-- rounds, dimension labels, the cutoff natural key) hangs off an authority, so
-- it gets one at scope 'institute'.
--
-- The three campuses are seeded by hand rather than left to the importer's
-- create-missing path, which would put all three in one state, type them GFTI
-- and mark them government-owned. They are one deemed university with three
-- campuses in three different states.
BEGIN;

INSERT INTO counselling_authorities (code, name, scope, state_id, official_website, description)
VALUES ('BITS', 'BITS Pilani Admissions', 'institute', NULL,
        'https://admissions.bits-pilani.ac.in/',
        'BITS admits directly on the BITSAT score. There is no external counselling body and no category reservation; a single all-India merit list fills every campus.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO cities (state_id, name)
SELECT s.id, v.city
FROM (VALUES ('RJ', 'Pilani'), ('GA', 'Zuarinagar'), ('TS', 'Hyderabad')) AS v(state_code, city)
JOIN states s ON s.code = v.state_code
ON CONFLICT (state_id, name) DO NOTHING;

-- Names must match the scraper's output exactly; that string is the join key.
INSERT INTO colleges (slug, name, short_name, college_type, ownership, state_id, city_id,
                      website, established_year, is_autonomous, has_hostel, about)
SELECT v.slug, v.name, v.short_name, 'DEEMED', 'private', s.id, c.id,
       'https://www.bits-pilani.ac.in/', v.est, true, true, v.about
FROM (VALUES
  ('bits-pilani-pilani-campus',    'BITS Pilani, Pilani Campus',    'BITS Pilani',    'RJ', 'Pilani',     1964::SMALLINT,
   'The founding campus of Birla Institute of Technology and Science, a deemed university admitting on BITSAT.'),
  ('bits-pilani-goa-campus',       'BITS Pilani, Goa Campus',       'BITS Goa',       'GA', 'Zuarinagar', 2004::SMALLINT,
   'The K K Birla Goa campus of BITS Pilani, admitting on the same all-India BITSAT merit list.'),
  ('bits-pilani-hyderabad-campus', 'BITS Pilani, Hyderabad Campus', 'BITS Hyderabad', 'TS', 'Hyderabad',  2008::SMALLINT,
   'The Hyderabad campus of BITS Pilani, admitting on the same all-India BITSAT merit list.')
) AS v(slug, name, short_name, state_code, city, est, about)
JOIN states s ON s.code = v.state_code
JOIN cities c ON c.state_id = s.id AND c.name = v.city
ON CONFLICT (slug) DO NOTHING;

-- One process per published year. rank_basis 'score' is what stops the
-- predictor treating 306 as a rank of 306.
INSERT INTO counselling_processes (counselling_authority_id, academic_year, code, name,
                                   rank_basis, total_rounds, cutoff_url, is_published)
SELECT a.id, y.yr, 'BITS_' || y.yr, 'BITSAT Admissions ' || y.yr, 'score', 1,
       'https://admissions.bits-pilani.ac.in/FD/BITSAT_cutOffs.html', true
FROM counselling_authorities a
CROSS JOIN (VALUES (2017), (2018), (2019), (2020), (2021),
                   (2022), (2023), (2024), (2025), (2026)) AS y(yr)
WHERE a.code = 'BITS'
ON CONFLICT (counselling_authority_id, academic_year) DO NOTHING;

INSERT INTO counselling_exams (counselling_process_id, exam_id, is_primary, notes)
SELECT cp.id, e.id, true, 'BITS admits on the BITSAT score out of the paper total.'
FROM counselling_processes cp
JOIN counselling_authorities a ON a.id = cp.counselling_authority_id AND a.code = 'BITS'
JOIN exams e ON e.code = 'BITSAT'
ON CONFLICT (counselling_process_id, exam_id) DO NOTHING;

-- BITS runs several iterations but publishes only the final cut-off, so there
-- is exactly one round and it is the closing one.
INSERT INTO counselling_rounds (counselling_process_id, round_no, name, kind,
                                is_final_regular_round, cutoff_published)
SELECT cp.id, 1, 'Final cut-off', 'regular', true, true
FROM counselling_processes cp
JOIN counselling_authorities a ON a.id = cp.counselling_authority_id AND a.code = 'BITS'
ON CONFLICT (counselling_process_id, round_no, kind) DO NOTHING;

INSERT INTO data_sources (code, name, url, kind, tier, adapter_key, data_type,
                          exam_id, counselling_authority_id, poll_cron, notes)
SELECT 'BITS_CUTOFFS', 'BITSAT programme-wise cut-off scores',
       'https://admissions.bits-pilani.ac.in/FD/BITSAT_cutOffs.html',
       -- 'official_counselling', not 'official_institute': the tier ladder is
       -- about who OWNS the figure. An institute's own website is tier 4 when
       -- it is republishing a number some authority allotted on. Here BITS
       -- conducts the exam, runs the admission and is the only publisher --
       -- this page IS the counselling portal for the process.
       'html', 'official_counselling', 'bits', 'cutoff',
       e.id, a.id, '0 */6 * * *',
       'Ten years of history on one page, one <div id="YYYY-YYYY"> per year, shown and hidden client side; ?yr= is ignored server side. Scraped with tools/bitsat-scrape.js, which needs node --use-system-ca because the host serves an incomplete certificate chain.'
FROM exams e, counselling_authorities a
WHERE e.code = 'BITSAT' AND a.code = 'BITS'
ON CONFLICT (code) DO UPDATE SET
  tier  = EXCLUDED.tier,
  url   = EXCLUDED.url,
  notes = EXCLUDED.notes;

COMMIT;

-- Programme names, scoped to BITS.
--
-- Aliased in full ("B.E. Civil", not "Civil") because the resolver's last-ditch
-- longest-contained-alias pass is what would otherwise run, and on strings this
-- short it guesses badly.
--
-- The M.Sc. programmes belong here: at BITS they are four-year FIRST degrees
-- entered straight from school off the same merit list, and they carry the
-- lowest cut-offs in the feed -- the ones a borderline candidate most needs.
BEGIN;

INSERT INTO branch_aliases (branch_id, alias, normalized_alias, counselling_authority_id)
SELECT b.id, v.alias,
       trim(lower(regexp_replace(v.alias, '[^a-zA-Z0-9]+', ' ', 'g'))),
       a.id
FROM (VALUES
  ('B.E. Chemical',                      'CHE'),
  ('B.E. Civil',                         'CE'),
  ('B.E. Computer Science',              'CSE'),
  ('B.E. Electrical and Electronics',    'EEE'),
  ('B.E. Electronics and Communication', 'ECE'),
  ('B.E. Electronics and Computer',      'ECE'),
  ('B.E. Electronics and Instrumentation', 'INSTR'),
  ('B.E. Environmental and Sustainability', 'ENV'),
  ('B.E. Manufacturing',                 'IPE'),
  ('B.E. Mathematics and Computing',     'MATH'),
  ('B.E. Mechanical',                    'ME'),
  -- Pharmaceutical Engineering is an engineering degree run out of the
  -- chemical department, not the pharmacy one.
  ('B.E. Pharmaceutical Engg.',          'CHE'),
  ('B.Pharm.',                           'PHARM'),
  ('M.Sc. Biological Sciences',          'LIFESCI'),
  ('M.Sc. Chemistry',                    'CHEMSCI'),
  ('M.Sc. Economics',                    'ECON'),
  ('M.Sc. Mathematics',                  'MATH'),
  ('M.Sc. Physics',                      'PHY'),
  ('M.Sc. Semiconductor and Nanoscience', 'MSE')
) AS v(alias, branch_code)
JOIN branches b ON b.code = v.branch_code
JOIN counselling_authorities a ON a.code = 'BITS'
ON CONFLICT DO NOTHING;

COMMIT;
