-- Seed: source master (design doc section 18).
--
-- URLs verified reachable on 2026-09-19. `is_active = false` everywhere on
-- purpose: a source only goes active once its adapter is written and tested.
-- Manual CSV/XLSX imports do NOT need is_active -- they only need the row to
-- exist, so the import job has provenance to point at.
--
-- auto_publish_allowed stays false for all of them. The CHECK constraint on
-- data_sources already forbids it below tier 2, but even JoSAA gets a human.
BEGIN;

INSERT INTO data_sources (code, name, url, kind, tier, adapter_key, data_type,
                          exam_id, counselling_authority_id, poll_cron, is_active, notes)
SELECT d.code, d.name, d.url, d.kind::source_kind, d.tier::source_tier,
       d.adapter_key, d.data_type, e.id, a.id, d.cron, false, d.notes
FROM (VALUES
  ('JOSAA_ORCR', 'JoSAA Opening/Closing Ranks (current year)',
   'https://josaa.admissions.nic.in/Applicant/seatallotmentresult/currentorcr.aspx',
   'html', 'official_counselling', 'josaa', 'cutoff', 'JEE_MAIN', 'JOSAA', '0 */6 * * *',
   'ASP.NET postback form, no export. Round-wise. Use Playwright.'),

  ('JOSAA_ORCR_ARCHIVE', 'JoSAA Opening/Closing Ranks (2016-2025 archive)',
   'https://josaa.admissions.nic.in/applicant/seatmatrix/openingclosingrankarchieve.aspx',
   'html', 'official_counselling', 'josaa', 'cutoff', 'JEE_MAIN', 'JOSAA', '0 4 1 * *',
   'Ten years of history. Backfill source; poll monthly, not 6-hourly.'),

  ('JOSAA_SEAT_MATRIX', 'JoSAA seat matrix',
   'https://josaa.admissions.nic.in/applicant/seatmatrix/seatmatrixinfo.aspx',
   'html', 'official_counselling', 'josaa', 'seat_matrix', 'JEE_MAIN', 'JOSAA', '0 */6 * * *',
   'Also the cheapest way to bootstrap the college master.'),

  ('CSAB_ORCR', 'CSAB special round cutoffs',
   'https://csab.nic.in/', 'html', 'official_counselling', 'csab', 'cutoff',
   'JEE_MAIN', 'CSAB', '0 */6 * * *', 'Runs after JoSAA closes.'),

  ('NTA_JEE_MAIN', 'NTA JEE Main notices, result and percentile data',
   'https://jeemain.nta.nic.in/', 'html', 'official_authority', 'nta', 'schedule',
   'JEE_MAIN', NULL, '0 */6 * * *',
   'Exam dates, qualifying cutoffs, candidate counts, percentile-to-rank.'),

  ('COMEDK_COUNSELLING', 'COMEDK counselling documents',
   'https://www.comedk.org/counselling-document-2026',
   'pdf', 'official_counselling', 'comedk', 'cutoff', 'COMEDK_UGET', 'COMEDK', '0 */6 * * *',
   'PDF/XLSX links off an index page. Serves no robots.txt - check terms.'),

  ('UPTAC_ORCR', 'UPTAC B.Tech opening/closing ranks',
   'https://uptac.admissions.nic.in/', 'html', 'official_counselling', 'uptac', 'cutoff',
   'UPCET', 'UPTAC', '0 */6 * * *', NULL),

  ('MHTCET_CAP', 'Maharashtra CET Cell CAP round cutoffs',
   'https://cetcell.mahacet.org/', 'pdf', 'official_counselling', 'mhtcet', 'cutoff',
   'MHT_CET', 'MAHACET', '0 */6 * * *', 'Percentile-based, not rank-based.'),

  ('KEA_KCET', 'KEA KCET counselling cutoffs',
   'https://cetonline.karnataka.gov.in/', 'pdf', 'official_counselling', 'kea', 'cutoff',
   'KCET', 'KEA', '0 */6 * * *', 'Prints local category codes like 3BG, 2AK.'),

  ('WBJEEB_ORCR', 'WBJEEB counselling cutoffs',
   'https://wbjeeb.nic.in/', 'html', 'official_counselling', 'wbjeeb', 'cutoff',
   'WBJEE', 'WBJEEB', '0 */6 * * *', NULL),

  ('NIRF_ENGINEERING', 'NIRF engineering rankings',
   'https://www.nirfindia.org/', 'pdf', 'official_authority', 'nirf', 'college',
   NULL, NULL, '0 3 * * 1', 'Annual. Was under maintenance on 2026-09-19.'),

  ('AICTE_APPROVED', 'AICTE approved institutes and intake',
   'https://facilities.aicte-india.org/dashboard/pages/angulardashboard.php',
   'html', 'official_authority', 'aicte', 'college', NULL, NULL, '0 3 * * 1',
   'College master and sanctioned intake.')
) AS d(code, name, url, kind, tier, adapter_key, data_type, exam_code, authority_code, cron, notes)
LEFT JOIN exams e ON e.code = d.exam_code
LEFT JOIN counselling_authorities a ON a.code = d.authority_code
ON CONFLICT (code) DO NOTHING;

COMMIT;
