#!/usr/bin/env node
/**
 * Runs smoke-test.sql without psql.
 *
 * The Zonky/embedded PostgreSQL build ships only the server binaries, so psql
 * is not available on this machine. This runner understands the one psql
 * meta-command the script uses (\echo) and sends everything else through the
 * pg driver on a single connection, so the BEGIN ... ROLLBACK wrapper holds.
 */
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');

const { Client } = (() => {
  try { return require('pg'); }
  catch { return createRequire(path.join(__dirname, '..', 'api', 'package.json'))('pg'); }
})();

// String.fromCharCode(92) is a backslash. Written this way on purpose.
const PSQL_ECHO = String.fromCharCode(92) + 'echo';

function statements(sql) {
  const out = [];
  let buf = [];
  for (const raw of sql.split(/\r?\n/)) {
    const line = raw.trim();
    if (line.startsWith(PSQL_ECHO)) {
      if (buf.join('').trim()) { out.push({ kind: 'sql', text: buf.join('\n') }); buf = []; }
      out.push({ kind: 'echo', text: line.slice(5).trim().replace(/^'|'$/g, '') });
      continue;
    }
    buf.push(raw);
    if (line.endsWith(';') && !line.startsWith('--')) {
      out.push({ kind: 'sql', text: buf.join('\n') });
      buf = [];
    }
  }
  if (buf.join('').trim()) out.push({ kind: 'sql', text: buf.join('\n') });
  return out;
}

function printRows(rows) {
  if (!rows || rows.length === 0) return;
  const cols = Object.keys(rows[0]);
  const width = (c) => Math.max(c.length, ...rows.map((r) => String(r[c] ?? '').length));
  const w = Object.fromEntries(cols.map((c) => [c, width(c)]));
  console.log('  ' + cols.map((c) => c.padEnd(w[c])).join(' | '));
  console.log('  ' + cols.map((c) => '-'.repeat(w[c])).join('-+-'));
  for (const r of rows) {
    console.log('  ' + cols.map((c) => String(r[c] ?? '').padEnd(w[c])).join(' | '));
  }
  console.log();
}

async function main() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL is not set.');
  const sql = fs.readFileSync(path.join(__dirname, 'smoke-test.sql'), 'utf8');

  const client = new Client({ connectionString: url });
  await client.connect();
  let failures = 0;
  try {
    for (const s of statements(sql)) {
      if (s.kind === 'echo') { console.log('\n' + s.text); continue; }
      if (!s.text.trim()) continue;
      const res = await client.query(s.text);
      if (res.rows?.length) {
        printRows(res.rows);
        for (const row of res.rows) {
          for (const v of Object.values(row)) {
            if (typeof v === 'string' && v.startsWith('FAIL')) failures += 1;
          }
        }
      }
    }
  } finally {
    await client.end();
  }
  console.log(failures === 0 ? '\nSMOKE TEST PASSED' : `\nSMOKE TEST FAILED (${failures} assertion(s))`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((e) => { console.error('\nsmoke-test:', e.message); process.exit(1); });
