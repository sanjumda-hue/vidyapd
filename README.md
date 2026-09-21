# B.Tech Admission Predictor

> Explore Exams • Compare Colleges • Predict Branches

Backend for an entrance-exam, college and historical-cutoff platform with a
rank/percentile prediction engine.

**Status:** running end to end on real data from **six admission
authorities** — 328,367 cutoff rows:

| Authority | Years | Rows | Measure |
| --------- | ----- | ---- | ------- |
| JoSAA     | 2023-2026, all 22 rounds | 257,016 | rank |
|  ├ IITs   | attributed to JEE Advanced | 68,863 | rank |
| CSAB      | 2023-2026 special rounds | 44,617 | rank |
| WBJEEB    | 2023-2026 | 15,870 | rank |
| UPTAC     | 2026 | 9,880 | rank |
| COMEDK    | 2025 | 582 | rank |
| BITS      | 2017-2026 | 402 | **score** |

BITS is the odd one out: it runs no counselling body, admits directly off the
BITSAT merit list, and publishes a cut-off **score** rather than a rank. That
has its own engine — see [docs/04-prediction-engine.md](docs/04-prediction-engine.md#marks-input).

The app has prediction, college search and detail, side-by-side comparison,
sign-in and a saved shortlist.

---

## Layout

```
dev.ps1           bring the local stack up/down -- start here each day
db/
  migrations/     27 forward-only .sql files -- the source of truth
  seeds/          reference data (states, categories, quotas, branches, exams)
  migrate.js      runner: up | seed | seed-dev | status | reset
  pg-local.ps1    start/stop the portable PostgreSQL (dev.ps1 calls this)
  smoke-test.sql  end-to-end check on synthetic data (rolled back)
  smoke-test.js   runs it without psql
tools/
  josaa-scrape.js JoSAA OR-CR archive -> CSV per round
  wbjee-scrape.js WBJEEB OR-CR -> CSV per year and exam
  uptac-scrape.js UPTAC (Samarth) cut-off matrix -> CSV
  comedk-parse.js COMEDK matrix PDF -> CSV (positional extraction)
  bitsat-scrape.js BITSAT cut-off scores, ten years on one page -> CSV per year
  seeds-dev/      invented demo data (never production)
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

### Every day, after the one-time setup below

```powershell
.\dev.ps1 up        # PostgreSQL, then the API, then checks the API answers
.\dev.ps1 status
.\dev.ps1 down
```

```bash
cd app && flutter run -d chrome
```

`dev.ps1` runs the API from its build. To work on the API itself, run it in
watch mode instead so edits under `api/src` reload:

```bash
cd api && npm run dev
```

The portable Postgres has no Windows service, so nothing survives a reboot. If
the app says **"Cannot reach the server. Is the API running on
http://localhost:3000/api/v1?"**, that is what happened — `.\dev.ps1 up` is the
whole fix. It is safe to re-run; anything already listening is left alone, and
the API is rebuilt only when `api/src` is newer than `api/dist`.

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

Start and stop it with the helper (there is no service, so this is needed
after every reboot):

```powershell
.\db\pg-local.ps1 start
.\db\pg-local.ps1 status
.\db\pg-local.ps1 stop
.\db\pg-local.ps1 log      # last 40 lines of the server log
```

Use the script rather than calling `pg_ctl` from a terminal you will close.
When postgres is a child of a shell that later exits, Windows can tear down the
context its backends need; the next connection then dies with `0xC0000142`
(DLL init failed), and that takes the **whole cluster** down, not just that
connection. This has already happened once. The script launches it detached.
Recovery is clean if it does crash — the WAL replays on the next start.

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

### 4b. Importing real cutoff data

Scraping is the slow path. An authority's own download, saved by hand once,
gets real data in today — and it goes through the exact same pipeline an
adapter will, so nothing downstream changes when the scraper lands.

```bash
cd api
npm run import:cutoffs -- --file ../data/josaa-2026-r5.csv                           --source JOSAA_ORCR --year 2026 --round 5
```

Columns are matched loosely, so `Closing Rank`, `CLOSING RANK` and
`Closing  Rank` all work. See [`data/josaa-sample-template.csv`](data/josaa-sample-template.csv)
for the expected shape.

| Flag | When |
| ---- | ---- |
| `--create-missing` | First import, when the college master is empty. Refused for sources below tier 2. |
| `--publish` | Skip review. Only for a source you trust and a file you have read. |

Without `--publish` the job stops at `pending_review`:

```bash
curl -X POST localhost:3000/api/v1/admin/imports/<id>/approve
curl -X POST localhost:3000/api/v1/admin/imports/<id>/publish
```

`GET /admin/imports/<id>` returns the validation failures and a sample of
resolved rows, so a reviewer can see what the importer actually decided.

**On ambiguous institute names.** The resolver will not guess. Indian institute
names share a long prefix — `IIT Delhi` vs `IIT Bombay` scores **0.690** on
trigram similarity, `NIT Calicut` vs `NIT Silchar` scores **0.673** — so a
plain threshold merges different colleges. An early version did exactly that
and moved Delhi's Mechanical programme onto Bombay. A fuzzy match now needs
similarity ≥ 0.92 *and* a ≥ 0.08 margin over the runner-up; anything else is
parked and reported with both candidates named. You resolve it once:

```sql
INSERT INTO college_institute_codes
  (college_id, counselling_authority_id, institute_code, institute_name_as_printed)
VALUES (<id>, <authority>, 'IITD-JOSAA', 'Indian Institute of Technology Delhi');
```

Re-running the same file is idempotent — it upserts on the natural key.

**`--create-missing` leaves colleges on a fallback state.** The feed carries no
state, and `colleges.state_id` decides home-state quota eligibility, so a
bootstrapped college will offer HS seats to the wrong students until someone
corrects it. The import warns per college; fix them before trusting HS results.

### 4b-ii. Importing a whole directory

```bash
cd api
npm run import:all -- --dir ../data
```

Imports every `josaa-<year>-r<round>.csv` in one process — one Nest context and
one connection pool for the batch instead of paying startup 22 times. Files for
the current year use the `JOSAA_ORCR` source, older years `JOSAA_ORCR_ARCHIVE`.
Re-running is safe: publish upserts on the natural key.

### 4c. Scraping JoSAA directly

`tools/josaa-scrape.js` drives the official OR-CR archive form and writes one
CSV per round:

```bash
node tools/josaa-scrape.js --year 2025 --rounds 1-6 --out ./data

# CSAB runs the special rounds after JoSAA, on the same platform and the same
# page names under /csabspl/ -- same scraper, different --page profile.
node tools/josaa-scrape.js --page csab --year 2025 --rounds 1-3 --out ./data/csab
node tools/josaa-scrape.js --page csab_current --year 2026 --rounds 1-4 --out ./data/csab
```

Every dropdown has an **ALL** option, so one round is a single page load — a
whole year costs six requests. There is a 6-second delay between them.

Two things about that page are worth knowing before you touch it:

- The selects carry `class="chosen-select"`, so the jQuery Chosen plugin hides
  the native element. `page.selectOption()` times out on something that is
  never visible. The script sets `__EVENTTARGET` and submits the form instead,
  which is exactly what the page's own `__doPostBack` does.
- **The user agent must start with `Mozilla/`.** Measured against the live
  site: Chrome, Firefox, Googlebot and a bare `Mozilla/5.0` all receive the
  `__EVENTTARGET` field; `curl/8.5.0` and a plain named-bot string do not. That
  is ASP.NET's legacy `browserCaps` deciding the client cannot run JavaScript
  and serving a downlevel page — progressive enhancement from 2005, not a bot
  block (a real one would not serve Googlebot). We are Chromium, so the Chrome
  token is accurate; the script appends an identifying suffix for the logs.

`josaa.nic.in/robots.txt` disallows only `/wp-admin/`, and
`josaa.admissions.nic.in` serves no robots.txt at all.

### 4d. Scraping WBJEEB

```bash
node tools/wbjee-scrape.js --out ./data/wbjee
cd api && npm run import:all -- --dir ../data/wbjee
```

Easier than JoSAA: the report page returns a whole year as one long-format HTML
table (5-7 MB, all rounds), so there is no form to drive. The `enc` tokens for
2021-2026 are the static links on the WBJEEB eServices page.

Three things West Bengal does differently, all handled in `db/seeds/012` and
`013`:

- **Two exams, one counselling.** WBJEEB fills seats from both the WBJEE rank
  and the JEE (Main) rank — the column it labels "Seat Type". Those are
  different rank series, so the scraper writes one file per channel and the
  importer takes an `examCode` to say which is which.
- **OBC-A and OBC-B.** West Bengal reserves separately for the two, with
  separate closing ranks, so they are separate categories. Collapsing them into
  OBC-NCL would merge different cutoffs.
- **Tuition Fee Waiver** is its own ranked seat pool, about 13% of rows, and is
  modelled as a category for the same reason.

WBJEEB's "Category" column is what JoSAA calls seat type; the scraper emits it
under the JoSAA name so the shared parser handles both feeds.

### 4e. Scraping UPTAC (Samarth)

```bash
node tools/uptac-scrape.js --out ./data/uptac
cd api && npm run import:all -- --dir ../data/uptac
```

UPTAC left admissions.nic.in for 2026 and the old OR-CR report now returns 500;
the data is on the Samarth platform instead. `robots.txt` there is `Disallow:`
with nothing after it, so everything is permitted. `per-page` is capped at 50
server side, so a full B.Tech pull is ~534 pages at a 1.5s delay.

Two things the scraper drops on the way out, because they are not cutoffs:

- **Rows with no rank.** UPTAC publishes the full grid of every institute x
  branch x category and fills in a rank only where a seat was actually
  allotted; 58% of rows are empty.
- **Non-JEE channels.** The same counselling also fills from CUET-UG and board
  merit, which are different rank series and would need their own exams.

**UPTAC packs three dimensions into one code.** `BCGL` is a Backward Class
girls' seat, `EWSAF` an EWS armed-forces seat: a category prefix
(OP/BC/EWS/SC/ST) plus a sub-quota (NO/GL/PH/AF/FF). Those map onto the three
dimensions the schema already has — prefix to seat type, `PH` to the PwD
variant, `GL` to gender, `AF`/`FF` to quotas — so `db/seeds/014` maps the same
label under three dimensions in `counselling_dimension_map`, and the resolver
prefers the compound code over any dedicated column. UPTAC's own "Seat Gender"
column says "Co-Education", which describes the institute rather than the seat.

### 4f. Parsing COMEDK

```bash
node tools/comedk-parse.js --file data/comedk/comedk-2025-all.pdf                            --year 2025 --round 6 --out data/comedk
cd api && npm run import:all -- --dir ../data/comedk
```

COMEDK publishes a **wide matrix PDF**: rows are (college, seat category),
columns are ~74 branch codes, and the page is split horizontally into groups of
about seven columns. Plain text extraction destroys that — the cells arrive as
a stream with no idea which column they came from — so the parser reads each
item's x/y position via pdfjs and rebuilds the grid: header items matching
`XX-Name` give the column origins, and every numeric cell on a row is assigned
to the nearest column at or left of it.

Two quirks worth knowing:

- **College names wrap onto their own lines above the code row**, so the parser
  carries the nearest fragment forward and remembers it per college code.
- **COMEDK's `CE` means Computer Engineering, and `CV` means Civil** — the
  opposite of everyone else's `CE`. Its aliases are therefore tagged with the
  COMEDK authority in `branch_aliases`, and the resolver layers authority
  aliases over the global ones.

A full season is only ~580 cutoff cells, so this is low-yield next to JoSAA.

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

## Tests

```bash
cd api && npm test          # pipeline unit tests, no database needed
cd app && flutter test test/api_contract_test.dart --tags integration
```

Two suites, deliberately split by what they need.

**`api` — 50 unit tests** over the parser, the validator and the resolver. These
three turn an authority's printed labels into rows, and every data bug this
project has had lived in one of them: decimal ranks read 10x too large,
scientific notation read as `1`, preparatory ranks mixed into the general list,
COMEDK's `CE` meaning Computer Science where everyone else means Civil, a
compound seat code losing 3,527 girls' seats. Each of those is a named test. No
database, no network, runs in seconds.

**`app` — 14 contract tests** that POST to a running API and parse the responses
with the app's own models. A field renamed on the server is the likeliest way
this app breaks and `flutter analyze` cannot see it; these can. They need the
API up and the database populated.

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

- **Five of 17 seeded exams have cutoffs** — JEE Main, JEE Advanced (the IIT
  half of JoSAA), WBJEE, COMEDK UGET and BITSAT. VITEEE and SRMJEEE cannot
  follow: neither VIT nor SRM publishes branch-wise closing ranks, and VIT says
  so outright. The remaining state bodies (KCET, TNEA, MHT-CET, AP/TS EAMCET)
  do publish, and are simply not wired up yet. The rest are marked "no data yet" in the predict form, and picking one
  gives an empty state that says so by name. `/reference/bootstrap` reports this
  per exam as `hasCutoffData`, read from the two trend views the predictor
  queries, so the flag cannot drift from reality.
- **Six admission bodies are wired up.** JoSAA, CSAB, WBJEEB, UPTAC, COMEDK and
  BITS work. The findings on the rest are in `data_sources.last_error`:
  - **KEA (KCET)** — the UGCET 2026 page carries 462 PDFs and not one cutoff
    or last-rank table. What reads as "Engineering" is
    `PROF_CODE_E_vacant_seat_*.pdf`, a vacant-seat listing in Kannada. KEA does
    not publish an aggregated cutoff at all; deriving one would mean parsing
    per-candidate allotment results, a different problem that also involves
    personal data. Not pursued.
  - **MHT-CET** — `cetcell.mahacet.org` did not respond.
- WBJEEB 2022 and earlier use a different column layout and are not imported;
  2023-2026 are.
- UPTAC on Samarth exposes only the current season, so there is one year of it.
  The 2021-2025 data is on the old NIC report, which returns HTTP 500.
- 146 UPTAC rows (1.5%) do not resolve, mostly one-off programme names.
- BITS publishes only the final cut-off, not per-iteration ones, so every BITSAT
  row is round 1 and there is no round-by-round movement to show.
- **Percentile input is switched off.** `percentile_rank_mapping` and
  `exam_rank_data` are both empty, so `fn_percentile_to_rank` has nothing to
  work with and JEE Main's Percentile toggle 400'd on every submission. The form
  now reads `hasPercentileData` from `/reference/bootstrap`, which is true only
  when the conversion can actually run, so the toggle stays hidden until data
  exists. To switch it on, load ONE row into `exam_rank_data` per exam-year with
  `exam_session_id = NULL`, `category_id = NULL` and `appeared_candidates` set
  to the **unique candidates in the merit list** — not a single session's
  attendance. JEE Main ranks are computed across both sessions on unique
  candidates (~14.7 lakh), while Session 1 alone saw ~13.0 lakh, and using the
  session figure would skew every estimate by about 13% while the function
  advertises a 3% band.
- The scheduled adapters are still skeletons: `JosaaAdapter.parseCutoffs()`
  throws and `ComedkAdapter` cannot discover document links, so their
  `data_sources` rows stay `is_active = false`. Data currently arrives through
  the `tools/*-scrape.js` scripts plus `npm run import:all`, which is the same
  pipeline.
- **176 rows across all current imports do not resolve** (0.05%): UPTAC 146,
  JoSAA 29, CSAB 1 -- mostly one-off programme names and one typo in the source
  feed ("Elctrical Engineering"). They are parked as invalid, never guessed at.
  `data_import_staging` also holds ~9,200 invalid rows from superseded jobs
  that were re-imported after a mapping fix; those are stale, not gaps.
- `db/seeds-dev` (invented `(DEMO)` colleges) still exists for working without
  real data. It is not loaded now, and `seed-dev` refuses when
  `NODE_ENV=production`.
- API modules with routes: `prediction`, `cutoffs`, `exams`, `reference`,
  `colleges` (list, detail, compare), `shortlist`, `auth`, `admin`. Still empty
  controller/service shells: `branches`, `compare`, `users`, `notifications`,
  `calendar`, `counselling` — and the matching app tiles say so.
- **Ownership and NIRF rating are not filterable, because they hold nothing.**
  580 of 583 colleges read "government" and 3 read "private" — the importer
  defaults the column and no source has ever set it — and
  `college_accreditations` has no NIRF rows at all. The college list filters on
  type, state, exam and branch, which are real.
- **`college_type` is IIT/NIT/IIIT plus a junk drawer.** The resolver types
  anything it cannot recognise by name as GFTI, so 482 colleges are in that
  bucket, private ones included. The UI shows it as "Other" rather than
  claiming they are Government Funded Technical Institutes.
- **The app requires a sign-in; the API does not.** The Flutter router redirects
  every route to `/sign-in` until `/auth/me` accepts a stored token, and sends
  you back there on sign-out. That gates the UI, not the data: `POST /prediction`
  still answers an anonymous caller and leaves `user_id` null on
  `prediction_requests`. Closing that gap means guards on the API routes.
- The app has no Android build config beyond the Flutter default, and no
  offline cache — every screen needs the API.

## Build order

1. **Foundation** — schema, masters. *(done)*
2. **Data** — import pipeline runner, first working adapter, backfill 4 years.
3. **Student app** — dashboard, calendar, college/branch/cutoff search, compare.
4. **Prediction** — rank, percentile and marks input, what-if. *(done)*
5. **Production** — admin approval UI, notifications, analytics, deployment.
