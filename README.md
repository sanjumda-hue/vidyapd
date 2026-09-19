# B.Tech Admission Predictor

> Explore Exams • Compare Colleges • Predict Branches

Backend for an entrance-exam, college and historical-cutoff platform with a
rank/percentile prediction engine.

**Status:** schema, prediction engine and API are **running and verified** against
PostgreSQL 17.11 — 14 migrations applied, seeds loaded, smoke test green, API
answering on `localhost:3000`. The ingestion adapters are wired end to end but
their page selectors are not filled in yet, so there is no real cutoff data yet
— see [Known gaps](#known-gaps).

---

## Layout

```
db/
  migrations/     14 forward-only .sql files -- the source of truth
  seeds/          reference data (states, categories, quotas, branches, exams)
  migrate.js      runner: up | seed | status | reset
  smoke-test.sql  end-to-end check on synthetic data (rolled back)
  smoke-test.js   runs it without psql
api/
  prisma/         introspected client schema (never `prisma migrate`)
  src/
    config/       env loading + Joi validation (fails at boot, not first request)
    common/       response envelope, exception filter, pagination
    database/     PrismaService
    cache/        Redis, with an in-memory fallback when REDIS_URL is empty
    modules/      one folder per domain; prediction/ and cutoffs/ are implemented
    ingestion/    per-authority adapters, validator, 6-hourly poller
app/                Flutter client (web + Android)
  lib/src/
    core/           api client, theme, router
    features/       home, prediction, exams, reference, shared
  test/             API contract tests against a live server
  run-web.ps1       serves the app on :5000
docs/
  02-er-diagram.md        tables, relationships, why the shape is what it is
  04-prediction-engine.md the algorithm, end to end
  05-api-reference.md     endpoint list and the prediction response contract
```

## Getting started

Requires **PostgreSQL 14+** (partitioned-table row triggers) and **Node 20+**.
Redis is optional — leave `REDIS_URL` empty and the API uses an in-memory cache.

### 1. PostgreSQL

The normal route is the EDB installer:

```powershell
winget install PostgreSQL.PostgreSQL.17
createdb -U postgres btech_predictor
```

**If that fails with a 403**, EnterpriseDB is blocking the download (it does
this for some networks and regions). Use the portable build instead — no admin
rights, no Windows service, no registry:

```bash
# PostgreSQL binaries, published on Maven Central by the Zonky project
V=17.11.0
curl -sL -o pg.jar "https://repo1.maven.org/maven2/io/zonky/test/postgres/embedded-postgres-binaries-windows-amd64/$V/embedded-postgres-binaries-windows-amd64-$V.jar"
unzip -o -q pg.jar -d jar
mkdir -p ~/pgsql/17 && tar -xJf jar/postgres-windows-x86_64.txz -C ~/pgsql/17

# one-time cluster init
printf 'postgres' > ~/pgsql/.pw
~/pgsql/17/bin/initdb -D ~/pgsql/data -U postgres --pwfile=$HOME/pgsql/.pw   --auth-local=trust --auth-host=scram-sha-256 -E UTF8 --locale=C
rm ~/pgsql/.pw
```

Start and stop it (there is no service, so this is needed after every reboot):

```bash
~/pgsql/17/bin/pg_ctl -D ~/pgsql/data -l ~/pgsql/server.log -o "-p 5432" start
~/pgsql/17/bin/pg_ctl -D ~/pgsql/data stop
```

This build ships only the server binaries — no `psql`, no `createdb`. Create the
database with Node instead:

```bash
cd api && node -e "const{Client}=require('pg');(async()=>{const c=new Client('postgresql://postgres:postgres@127.0.0.1:5432/postgres');await c.connect();await c.query('CREATE DATABASE btech_predictor');await c.end();})()"
```

### 2. Schema

```bash
cd api
cp .env.example .env          # set DATABASE_URL and JWT_SECRET
npm install

cd ..
node db/migrate.js up         # apply schema
node db/migrate.js seed       # reference data
node db/migrate.js status     # what is applied vs pending
```

### 3. API

```bash
cd api
npm run prisma:pull           # generate the typed client from the live schema
npm run start:dev
```

`prisma:pull` is **required before the API typechecks**. `prisma/schema.prisma`
ships with no models on purpose — they are introspected from the migrated
database. Until you run it, `tsc` reports every `this.prisma.<model>` access as
missing. Verified: with models present the API compiles with zero errors.

### 4. Smoke test

Proves the whole chain on synthetic data — 2 colleges, 4 years of cutoffs, a
prediction — inside a transaction that is rolled back, so nothing is left behind:

```bash
node db/smoke-test.js
```

It asserts three things that are easy to break silently: the `category_id`
trigger stays in sync with `seat_type_id`, the recency weighting produces exactly
46,400 for the worked example, and the home-state quota does **not** leak an
out-of-state college into the results.

### 5. Run it in Chrome

Two processes. Both must be up.

```powershell
# terminal 1 - API
cd api; node dist/main.js        # or: npm run start:dev

# terminal 2 - Flutter web
cd app; .
un-web.ps1            # serves on http://localhost:5000
```

Then open **http://localhost:5000** in Chrome.

`run-web.ps1` uses `-d web-server` rather than `-d chrome`. `-d chrome` launches
its own Chrome and waits for a debug service to attach, which does not reliably
connect on this machine; `-d web-server` just serves the app and lets you open
any browser. Hot reload still works — press `r` in the terminal.

The port is pinned to 5000 because it has to match `CORS_ORIGINS` in `api/.env`.
If you change one, change the other, or the browser will block every request.

The API itself is also browsable:

| URL | What it is |
| --- | ---------- |
| `http://localhost:5000` | The app |
| `http://localhost:3000/docs` | Swagger UI |
| `http://localhost:3000/api/v1/...` | Raw JSON |

### 6. What the app does today

- **Home** — dashboard tiles. Live ones are marked; the rest open a screen that
  names the backend work still missing.
- **Predict My College** — the full flow. Exam, rank or percentile, category,
  gender, PwD, home state, branch filters. Results are cards with the grade
  badge, weighted closing rank, margin, historical range and a year-by-year
  breakdown you can expand.
- **Entrance Exams** — the seeded exams, grouped by level.

Point releases at a different API without touching code:

```bash
flutter build web --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

## Key design decisions

**SQL is the source of truth, Prisma is introspected from it.** The schema needs
LIST partitioning, partial and expression indexes, composite foreign keys and
plpgsql functions. Prisma cannot express those, so `prisma db pull` runs *after*
migrations and `prisma migrate` is never used.

**A cutoff belongs to a counselling round, not an exam.** JoSAA consumes both
JEE Main and JEE Advanced; JEE Main feeds JoSAA, CSAB and several state
processes. Modelling it the other way collapses under the first real dataset.

**Category, seat type, quota and gender are four separate dimensions.** Folding
them into one `category` column makes a JoSAA row unrepresentable.

**One adapter per counselling authority.** A single shared scraper breaks the
whole product the first time one portal changes its markup. Each authority gets
a class registered under a key in `data_sources.adapter_key`; a failure is
contained to that authority.

**Nothing auto-publishes by default.** Scraped rows land in
`data_import_staging`, are validated row by row, and reach a live table only
after a job is approved. Only tier-1/tier-2 official sources may be flagged
`auto_publish_allowed` at all.

**The engine reports historical matches, never guarantees.** The `match_grade`
enum has no value that claims admission, and every response carries a
disclaimer.

## Known gaps

These are scaffolds, not finished work:

- **No real cutoff data.** What the app shows comes from `db/seeds-dev`, which
  invents ranks for colleges suffixed `(DEMO)`. The app renders a red banner
  over any screen that shows them. `seed-dev` refuses to run when
  `NODE_ENV=production`.
- `JosaaAdapter.parseCutoffs()` throws; `ComedkAdapter` cannot discover document
  links. Their `data_sources` rows must stay `is_active = false`.
- The staging -> validate -> publish **runner** does not exist. The validator
  (`api/src/ingestion/pipeline/cutoff-validator.ts`) does.
- API modules with routes: `prediction`, `cutoffs`, `exams`, `reference`.
  Everything else (`colleges`, `branches`, `compare`, `shortlist`, `auth`,
  `users`, `notifications`, `admin`, `calendar`, `counselling`) is an empty
  controller/service shell, and the matching app tiles say so.
- No authentication. Predictions run as a guest; `user_id` is null on every
  `prediction_requests` row.
- The app has no Android build config beyond the Flutter default, and no
  offline cache — every screen needs the API.

## Build order

1. **Foundation** — schema, masters. *(done)*
2. **Data** — import pipeline runner, first working adapter, backfill 4 years.
3. **Student app** — dashboard, calendar, college/branch/cutoff search, compare.
4. **Prediction** — rank and percentile input, what-if. *(engine done, screens pending)*
5. **Production** — admin approval UI, notifications, analytics, deployment.
