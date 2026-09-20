/**
 * Write what a reachability probe found into data_sources.
 *
 * These findings belong in the source master, not in a chat log: the next
 * person to look at CSAB should see "checked on this date, host did not
 * respond" rather than rediscovering it.
 */
const { createRequire } = require('node:module');
const path = require('node:path');
const { Client } = createRequire(path.join(__dirname, '..', 'api', 'package.json'))('pg');

const FINDINGS = [
  ['CSAB_ORCR',
   'Host unreachable on 2026-09-20: TCP 443/80 accept but TLS/HTTP never responds (curl and Chromium both time out). Not a bot block - no 403, no challenge. Retry later.'],
  ['COMEDK_COUNSELLING',
   'Reachable. Publishes engineering cutoffs as wide matrix PDFs (colleges x 74 branch columns, seat categories GM/KKR). Positional extraction works, but the whole 2025 season is only ~595 values and the internal text layout differs between rounds (college code is sometimes its own item, sometimes merged with the name). Low yield, fragile. Prefer hand-collected CSV until a denser source appears.'],
  ['UPTAC_ORCR',
   'The 2025 OR-CR report at admissions.nic.in/UPTAC/.../orcrreport.aspx returns HTTP 500 with or without a session cookie and Referer. UPTAC 2026 has moved off this platform to uptac.samarth.edu.in - re-scope against that host before writing an adapter.'],
  ['MHTCET_CAP',
   'Host cetcell.mahacet.org did not respond on 2026-09-20.'],
];

(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  for (const [code, note] of FINDINGS) {
    const r = await c.query(
      `UPDATE data_sources
       SET last_checked_at = now(),
           last_error = $2,
           notes = coalesce(notes || ' | ', '') || $2
       WHERE code = $1
       RETURNING code`,
      [code, note],
    );
    console.log(r.rowCount ? '  recorded: ' + code : '  NOT FOUND: ' + code);
  }
  await c.end();
})().catch((e) => { console.error(e.message); process.exit(1); });
