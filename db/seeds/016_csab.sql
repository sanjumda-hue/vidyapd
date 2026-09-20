-- Seed: CSAB counselling processes.
--
-- CSAB runs the special rounds after JoSAA closes, filling NIT+ vacancies from
-- the same JEE (Main) merit list and at the same institutes. That means the
-- college master is already populated, and its labels (OPEN, OBC-NCL, AI, HS,
-- Gender-Neutral) are the JoSAA ones, so no dimension mapping is needed.
BEGIN;

INSERT INTO counselling_processes (counselling_authority_id, academic_year, code, name, rank_basis, is_published)
SELECT a.id, y.yr, 'CSAB_' || y.yr, 'CSAB Special ' || y.yr, 'category_rank', true
FROM counselling_authorities a
CROSS JOIN (VALUES (2023), (2024), (2025), (2026)) AS y(yr)
WHERE a.code = 'CSAB'
ON CONFLICT (counselling_authority_id, academic_year) DO NOTHING;

INSERT INTO counselling_exams (counselling_process_id, exam_id, is_primary, notes)
SELECT cp.id, e.id, true, 'CSAB special rounds allot on the JEE (Main) rank.'
FROM counselling_processes cp
JOIN counselling_authorities a ON a.id = cp.counselling_authority_id AND a.code = 'CSAB'
JOIN exams e ON e.code = 'JEE_MAIN'
ON CONFLICT (counselling_process_id, exam_id) DO NOTHING;

-- Mark these rounds as special so they are distinguishable from JoSAA's.
INSERT INTO counselling_rounds (counselling_process_id, round_no, name, kind, cutoff_published)
SELECT cp.id, r.n, 'CSAB Special Round ' || r.n, 'special', true
FROM counselling_processes cp
JOIN counselling_authorities a ON a.id = cp.counselling_authority_id AND a.code = 'CSAB'
CROSS JOIN (VALUES (1), (2), (3), (4)) AS r(n)
ON CONFLICT (counselling_process_id, round_no, kind) DO NOTHING;

UPDATE data_sources
SET url = 'https://admissions.nic.in/csabspl/Applicant/seatallotmentresult/openingclosingrankarchieve.aspx',
    last_error = NULL,
    notes = 'Same NIC platform and page names as JoSAA, under /csabspl/. Archive covers 2022-2025; the current season is on currentorcr.aspx. Scraped with tools/josaa-scrape.js --page csab.'
WHERE code = 'CSAB_ORCR';

COMMIT;
