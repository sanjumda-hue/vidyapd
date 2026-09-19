#!/usr/bin/env node
/**
 * Minimal forward-only migration runner.
 *
 * Deliberately not a framework: the schema is plain .sql so that partitioning,
 * partial indexes and plpgsql functions can be written exactly as intended.
 * Prisma is introspected FROM this schema (npm run prisma:pull), never the
 * other way round.
 *
 *   node db/migrate.js up      apply pending migrations
 *   node db/migrate.js seed     apply db/seeds/*.sql (idempotent)
 *   node db/migrate.js seed-dev  add invented demo data for local development
 *   node db/migrate.js status  list applied vs pending
 *   node db/migrate.js reset   drop and recreate the public schema, then up+seed
 */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { createRequire } = require('node:module');

// This file lives in db/ but the only node_modules is api/. Node resolves from
// the FILE's directory, not the cwd, so a bare require('pg') fails even when
// the script is launched from api/ via npm.
function loadPg() {
  try {
    return require('pg');
  } catch {
    const apiRequire = createRequire(path.join(__dirname, '..', 'api', 'package.json'));
    return apiRequire('pg');
  }
}
const { Client } = loadPg();

const ROOT = __dirname;
const MIGRATIONS_DIR = path.join(ROOT, 'migrations');
const SEEDS_DIR = path.join(ROOT, 'seeds');
const SEEDS_DEV_DIR = path.join(ROOT, 'seeds-dev');

function readEnv() {
  const url = process.env.DATABASE_URL;
  if (url) return url;

  // Fall back to api/.env so `npm run db:migrate` works without exporting.
  const envPath = path.join(ROOT, '..', 'api', '.env');
  if (fs.existsSync(envPath)) {
    const line = fs
      .readFileSync(envPath, 'utf8')
      .split(/\r?\n/)
      .find((l) => l.startsWith('DATABASE_URL='));
    if (line) return line.slice('DATABASE_URL='.length).trim();
  }
  throw new Error('DATABASE_URL is not set (env or api/.env).');
}

const sqlFiles = (dir) =>
  fs.existsSync(dir)
    ? fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort()
    : [];

const checksum = (text) => crypto.createHash('sha256').update(text).digest('hex').slice(0, 16);

async function ensureTracking(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename    TEXT PRIMARY KEY,
      checksum    TEXT NOT NULL,
      applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);
}

async function up(client) {
  await ensureTracking(client);
  const { rows } = await client.query('SELECT filename, checksum FROM schema_migrations');
  const applied = new Map(rows.map((r) => [r.filename, r.checksum]));

  let count = 0;
  for (const file of sqlFiles(MIGRATIONS_DIR)) {
    const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');
    const sum = checksum(sql);

    if (applied.has(file)) {
      // An edited migration that has already run is a real hazard: the database
      // no longer matches the file anyone reads. Refuse rather than warn.
      if (applied.get(file) !== sum) {
        throw new Error(
          `${file} has changed since it was applied. Write a new migration instead of editing this one.`,
        );
      }
      continue;
    }

    process.stdout.write(`  applying ${file} ... `);
    // Each file carries its own BEGIN/COMMIT.
    await client.query(sql);
    await client.query(
      'INSERT INTO schema_migrations (filename, checksum) VALUES ($1, $2)',
      [file, sum],
    );
    console.log('ok');
    count += 1;
  }
  console.log(count ? `Applied ${count} migration(s).` : 'Already up to date.');
}

async function seed(client) {
  for (const file of sqlFiles(SEEDS_DIR)) {
    process.stdout.write(`  seeding ${file} ... `);
    await client.query(fs.readFileSync(path.join(SEEDS_DIR, file), 'utf8'));
    console.log('ok');
  }
  // Build the trend view once the reference data exists. Not concurrent: the
  // view has never been populated at this point.
  await client.query('SELECT fn_refresh_cutoff_trend(false)');
  console.log('Seed complete.');
}

/**
 * Invented colleges and cutoffs so the app has something to render. Refused in
 * production: these ranks are not real and must never reach a student.
 */
async function seedDev(client) {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('seed-dev is refused when NODE_ENV=production. This data is not real.');
  }
  console.log('Loading DEMO data (invented ranks, colleges suffixed "(DEMO)") ...');
  for (const file of sqlFiles(SEEDS_DEV_DIR)) {
    process.stdout.write(`  seeding ${file} ... `);
    await client.query(fs.readFileSync(path.join(SEEDS_DEV_DIR, file), 'utf8'));
    console.log('ok');
  }
  await client.query('SELECT fn_refresh_cutoff_trend(false)');
  await client.query('SELECT fn_sync_nirf_latest()');

  const { rows } = await client.query('SELECT count(*)::int AS n FROM cutoff_data');
  console.log(`Demo seed complete: ${rows[0].n} cutoff rows.`);
}

async function status(client) {
  await ensureTracking(client);
  const { rows } = await client.query('SELECT filename FROM schema_migrations');
  const applied = new Set(rows.map((r) => r.filename));
  for (const file of sqlFiles(MIGRATIONS_DIR)) {
    console.log(`  ${applied.has(file) ? '[applied]' : '[pending]'} ${file}`);
  }
}

async function reset(client) {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('reset is refused when NODE_ENV=production.');
  }
  console.log('Dropping and recreating schema "public" ...');
  await client.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
  await up(client);
  await seed(client);
}

async function main() {
  const command = process.argv[2] ?? 'up';
  const actions = { up, seed, status, reset, 'seed-dev': seedDev };
  const action = actions[command];
  if (!action) {
    console.error(`Unknown command "${command}". Use: up | seed | seed-dev | status | reset`);
    process.exit(1);
  }

  const client = new Client({ connectionString: readEnv() });
  await client.connect();
  try {
    await action(client);
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error(`\nmigrate: ${err.message}`);
  process.exit(1);
});
