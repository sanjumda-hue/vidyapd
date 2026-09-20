const { createRequire } = require('node:module');
const path = require('node:path');
const { Client } = createRequire(path.join(__dirname, '..', 'api', 'package.json'))('pg');

(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  const r = await c.query(
    `SELECT raw, validation_errors FROM data_import_staging
     WHERE import_job_id = $1 AND status = 'invalid'`,
    [process.argv[2]],
  );
  for (const row of r.rows) {
    const codes = (row.validation_errors || []).map((e) => e.code);
    if (!codes.some((x) => x === 'RANK_ORDER' || x === 'IMPLAUSIBLE_RANK')) continue;
    console.log(
      codes.join(',').padEnd(30),
      'OR=' + String(row.raw.openingRank).padStart(9),
      'CR=' + String(row.raw.closingRank).padStart(9),
      '|', String(row.raw.instituteName).slice(0, 34).padEnd(34),
      '|', String(row.raw.programName).slice(0, 34),
    );
    // The untouched source cells, to tell a parser bug from bad source data.
    const e = row.raw.extra || {};
    console.log('   source cells:', JSON.stringify({ OR: e['Opening Rank'], CR: e['Closing Rank'] }));
  }
  await c.end();
})().catch((e) => { console.error(e.message); process.exit(1); });
