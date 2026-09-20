const { createRequire } = require('node:module');
const path = require('node:path');
const { Client } = createRequire(path.join(__dirname, '..', 'api', 'package.json'))('pg');

(async () => {
  const jobId = process.argv[2];
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  const r = await c.query(
    `SELECT raw, validation_errors FROM data_import_staging
     WHERE import_job_id = $1 AND status = 'invalid'`,
    [jobId],
  );
  const byCode = new Map();
  for (const row of r.rows) {
    for (const e of row.validation_errors || []) {
      const k = e.code + ' / ' + e.field;
      byCode.set(k, (byCode.get(k) || 0) + 1);
    }
  }
  console.log('failure reasons across ' + r.rows.length + ' invalid rows:');
  [...byCode.entries()].sort((a, b) => b[1] - a[1])
    .forEach(([k, n]) => console.log(String(n).padStart(5), k));

  console.log();
  console.log('three examples:');
  for (const row of r.rows.slice(0, 3)) {
    console.log('  program :', row.raw.programName);
    console.log('  labels  :', JSON.stringify({ seat: row.raw.seatTypeLabel, quota: row.raw.quotaLabel, gender: row.raw.genderLabel }));
    console.log('  errors  :', (row.validation_errors || []).map((e) => e.code + ':' + e.message).join(' | '));
    console.log();
  }
  await c.end();
})().catch((e) => { console.error(e.message); process.exit(1); });
