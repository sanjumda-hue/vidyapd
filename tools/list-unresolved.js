const { createRequire } = require('node:module');
const path = require('node:path');
const { Client } = createRequire(path.join(__dirname, '..', 'api', 'package.json'))('pg');

(async () => {
  const jobId = process.argv[2];
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  const r = await c.query(
    `SELECT raw->>'programName' AS prog, count(*)::int rows
     FROM data_import_staging WHERE import_job_id = $1 AND status = 'invalid'
     GROUP BY 1 ORDER BY 2 DESC`,
    [jobId],
  );
  // Strip the trailing "(4 Years, ...)" suffix in JS, not SQL.
  const byBase = new Map();
  for (const row of r.rows) {
    const base = row.prog.replace(/\s*\(.*$/, '').trim();
    byBase.set(base, (byBase.get(base) || 0) + row.rows);
  }
  const sorted = [...byBase.entries()].sort((a, b) => b[1] - a[1]);
  console.log(`distinct base names: ${sorted.length}, rows: ${r.rows.reduce((a, x) => a + x.rows, 0)}`);
  for (const [name, n] of sorted) console.log(String(n).padStart(4), name);
  await c.end();
})().catch((e) => { console.error(e.message); process.exit(1); });
