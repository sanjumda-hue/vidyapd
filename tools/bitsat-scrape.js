/**
 * Download BITSAT cut-off scores and write one CSV per academic year.
 *
 *   node --use-system-ca tools/bitsat-scrape.js --out ./data/bitsat
 *
 * The flag is not optional: admissions.bits-pilani.ac.in serves an incomplete
 * certificate chain, so Node's bundled CA bundle cannot build a path to the
 * root and fetch fails with "unable to verify the first certificate". The
 * platform trust store has the intermediate. Offline alternative:
 *
 *   curl -sL -o bits.html https://admissions.bits-pilani.ac.in/FD/BITSAT_cutOffs.html
 *   node tools/bitsat-scrape.js --file bits.html --out ./data/bitsat
 *
 * BITS admits on its own test and publishes MARKS, not ranks -- the whole ten
 * years of history sits in a single page, split into <div id="2017-2018"> ...
 * <div id="2026-2027"> sections that the site shows and hides client side.
 * The ?yr= parameter is ignored by the server, so one fetch is everything.
 *
 * Each year has one table per campus, headed "Degree programme at X Campus",
 * with the cut-off score and the paper's maximum marks. The maximum matters:
 * it was 450 up to 2021 and 390 after, so a raw score is not comparable across
 * that boundary and the figure is carried through rather than dropped.
 */
const fs = require('node:fs');
const path = require('node:path');

const URL_ =
  'https://admissions.bits-pilani.ac.in/FD/BITSAT_cutOffs.html';
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';

const arg = (n, d) => {
  const i = process.argv.indexOf('--' + n);
  return i === -1 ? d : process.argv[i + 1];
};

// Written with RegExp() so the backslashes survive this toolchain intact.
const CELL_RE = new RegExp('<t[dh][\\s\\S]*?</t[dh]>', 'gi');
const CAMPUS_IN_HEADER = new RegExp('at\\s+([\\w ]+?)\\s+Campus', 'i');
const CAMPUS_COLUMN = new RegExp('^campus$', 'i');
const NUMERIC = new RegExp('^\\d+$');

/**
 * Campus names vary across years ("K K Birla Goa", "Goa", "Hyderabad").
 * One spelling each, or a campus becomes three different colleges.
 */
function normaliseCampus(raw) {
  const n = raw.toLowerCase();
  if (n.includes('goa')) return 'Goa';
  if (n.includes('hyderabad')) return 'Hyderabad';
  if (n.includes('pilani')) return 'Pilani';
  if (n.includes('dubai')) return 'Dubai';
  return raw.trim();
}

/**
 * The same programme is printed differently across years and campuses:
 *
 *   Pilani 2017   "B.E. Electrical & Electronics"
 *   Goa 2017      "B.E. Electrical and Electronics"
 *   Goa 2020+     "B.E. Electrical & Electronics"
 *   2017-2019     "B.Pharm."        2020+  "B. Pharm"
 *
 * Programme identity is the printed name, so leaving these as-is splits Goa's
 * EEE cut-off history in two at 2020 and hides the trend. One spelling each.
 */
function normaliseProgramme(raw) {
  const n = raw
    .replace(/&/g, ' and ')
    .replace(/\s+/g, ' ')
    .trim();
  if (/^b\.?\s?pharm/i.test(n)) return 'B.Pharm.';
  return n;
}

const strip = (s) =>
  s
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/\s+/g, ' ')
    .trim();

const csvCell = (v) => {
  const s = String(v ?? '');
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};

/** Split the page into {year, html} sections by their container id. */
function yearSections(html) {
  const out = [];
  const re = /<div[^>]*id=["'](20\d\d-20?\d\d)["'][^>]*>/gi;
  const marks = [...html.matchAll(re)].map((m) => ({ year: m[1], at: m.index }));
  for (let i = 0; i < marks.length; i++) {
    const end = i + 1 < marks.length ? marks[i + 1].at : html.length;
    out.push({ year: marks[i].year, html: html.slice(marks[i].at, end) });
  }
  return out;
}

async function main() {
  const outDir = arg('out', path.join(__dirname, '..', 'data', 'bitsat'));
  fs.mkdirSync(outDir, { recursive: true });

  // --file lets this run against a page already on disk. Node's fetch fails
  // on this host's TLS while curl succeeds, so the documented path is to
  // download once with curl and parse locally.
  const local = arg('file');
  let html;
  if (local) {
    html = fs.readFileSync(local, 'utf8');
    console.log(`read ${(html.length / 1e6).toFixed(2)} MB from ${local}`);
  } else {
    const res = await fetch(URL_, { headers: { 'User-Agent': UA } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    html = await res.text();
    console.log(`fetched ${(html.length / 1e6).toFixed(2)} MB`);
  }

  const sections = yearSections(html);
  console.log(`${sections.length} academic-year sections`);

  const written = [];
  for (const { year, html: block } of sections) {
    // The admission year is the first half of "2025-2026".
    const admissionYear = Number.parseInt(year.slice(0, 4), 10);
    const rows = [];

    for (const table of block.match(/<table[\s\S]*?<\/table>/gi) ?? []) {
      const trs = table.match(/<tr[\s\S]*?<\/tr>/gi) ?? [];
      if (trs.length < 2) continue;

      // Two layouts across the years:
      //   up to 2019  "Degree programme at Pilani Campus | Cut-off score | max"
      //               -- the campus is named in the header
      //   2020 on     "Campus | Program | Cut-off Score | max"
      //               -- the campus is a column
      const cells = (tr) => (tr.match(CELL_RE) ?? []).map(strip);

      // The real header is sometimes the second row, under a title row.
      const headerIdx = trs.findIndex((tr) => {
        const h = cells(tr);
        return CAMPUS_IN_HEADER.test(h[0] ?? '') || CAMPUS_COLUMN.test(h[0] ?? '');
      });
      if (headerIdx === -1) continue;

      const header = cells(trs[headerIdx]);
      const headerCampus = CAMPUS_IN_HEADER.exec(header[0] ?? '')?.[1];
      const campusIsColumn = CAMPUS_COLUMN.test(header[0] ?? '');

      for (const tr of trs.slice(headerIdx + 1)) {
        const c = cells(tr);
        if (c.length < 2) continue;

        const campus = campusIsColumn ? c[0] : headerCampus;
        const programme = campusIsColumn ? c[1] : c[0];
        const score = campusIsColumn ? c[2] : c[1];
        const maxMarks = (campusIsColumn ? c[3] : c[2]) ?? '';

        if (!campus || !programme || !NUMERIC.test(score ?? '')) continue;
        rows.push({
          campus: normaliseCampus(campus),
          programme: normaliseProgramme(programme),
          score,
          maxMarks,
        });
      }
    }

    if (!rows.length) {
      console.log(`  ${year}: no parseable tables`);
      continue;
    }

    const out = [
      ['Institute', 'Academic Program Name', 'Quota', 'Seat Type', 'Gender',
       'Round', 'Closing Score', 'Max Marks'].join(','),
    ];
    for (const r of rows) {
      out.push([
        `BITS Pilani, ${r.campus} Campus`,
        r.programme,
        'AI',               // BITS admits all-India; there is no state quota
        'OPEN',             // and no category reservation in its own process
        'Gender-Neutral',
        '1',
        r.score,
        r.maxMarks,
      ].map(csvCell).join(','));
    }

    const file = path.join(outDir, `bitsat-${admissionYear}-r1.csv`);
    fs.writeFileSync(file, out.join('\n'), 'utf8');
    console.log(`  ${year}: ${rows.length} rows -> ${path.basename(file)}`);
    written.push({ year: admissionYear, rows: rows.length });
  }

  console.log('\n=== summary ===');
  let total = 0;
  for (const w of written) { console.log(`  ${String(w.rows).padStart(4)} rows  ${w.year}`); total += w.rows; }
  console.log(`  ${String(total).padStart(4)} rows total`);
}

main().catch((e) => {
  console.error('bitsat-scrape failed:', e.message);
  process.exit(1);
});
