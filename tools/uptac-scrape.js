/**
 * Download UPTAC cutoffs from the Samarth platform.
 *
 *   node tools/uptac-scrape.js --out ./data/uptac --pages 3   # sample
 *   node tools/uptac-scrape.js --out ./data/uptac             # everything
 *
 * UPTAC moved off admissions.nic.in for 2026; the old NIC OR-CR report now
 * returns 500. Samarth serves the same data as a paginated long-format table.
 *
 * robots.txt on uptac.samarth.edu.in is "Disallow:" with nothing after it,
 * i.e. everything is allowed. per-page is capped at 50 server side, so a full
 * pull is ~534 requests; the delay below keeps that gentle.
 */
const fs = require('node:fs');
const path = require('node:path');

const BASE = 'https://uptac.samarth.edu.in/index.php/cut-off-matrix/index';
const P = 'PrgAdmissionCutOffSeatsSearch';
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';
const DELAY_MS = 1500;

const arg = (n, d) => {
  const i = process.argv.indexOf('--' + n);
  return i === -1 ? d : process.argv[i + 1];
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const strip = (s) =>
  s
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/&#x([0-9a-f]+);/gi, (_, n) => String.fromCharCode(parseInt(n, 16)))
    .replace(/\s+/g, ' ')
    .trim();

function parseRows(html) {
  const trs = html.match(/<tr[^>]*>[\s\S]*?<\/tr>/gi) || [];
  return trs
    .map((tr) => (tr.match(/<t[dh][^>]*>[\s\S]*?<\/t[dh]>/gi) || []).map(strip))
    .filter((c) => c.length);
}

const csvCell = (v) => {
  const s = String(v ?? '');
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};

async function fetchPage(page) {
  const url =
    `${BASE}?${encodeURIComponent(P + '[parent_programme_id]')}=5&page=${page}&per-page=50`;
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      const res = await fetch(url, { headers: { 'User-Agent': UA } });
      if (res.ok) return await res.text();
      console.error(`  page ${page}: HTTP ${res.status} (attempt ${attempt})`);
    } catch (e) {
      console.error(`  page ${page}: ${e.message} (attempt ${attempt})`);
    }
    await sleep(4000);
  }
  return null;
}

async function main() {
  const outDir = arg('out', path.join(__dirname, '..', 'data', 'uptac'));
  const maxPages = arg('pages') ? Number.parseInt(arg('pages'), 10) : null;
  fs.mkdirSync(outDir, { recursive: true });

  const first = await fetchPage(1);
  if (!first) throw new Error('could not fetch the first page');

  const totalMatch = /Showing [\d,-]+ of ([\d,]+)/.exec(first);
  const total = totalMatch ? Number.parseInt(totalMatch[1].replace(/,/g, ''), 10) : 0;
  const pages = maxPages ?? Math.ceil(total / 50);
  console.log(`${total} records, ${Math.ceil(total / 50)} pages; fetching ${pages}`);

  const rows = parseRows(first);
  const header = rows[0];
  console.log('header:', header.join(' | '));

  const all = rows.slice(1).filter((r) => r.length === header.length);
  for (let p = 2; p <= pages; p++) {
    await sleep(DELAY_MS);
    const html = await fetchPage(p);
    if (!html) continue;
    const got = parseRows(html).slice(1).filter((r) => r.length === header.length);
    all.push(...got);
    if (p % 25 === 0 || p === pages) {
      console.log(`  page ${p}/${pages}, ${all.length} rows so far`);
    }
  }

  const col = Object.fromEntries(header.map((h, i) => [h, i]));
  const need = ['Round', 'Institute', 'Branch', 'Category', 'Seat Gender',
                'Exam Name', 'Opening Rank', 'Closing Rank'];
  const missing = need.filter((n) => col[n] === undefined);
  if (missing.length) throw new Error('missing columns: ' + missing.join(', '));

  // Canonical column names, so the shared TabularParser handles this feed too.
  // UPTAC's compound Category code (e.g. BCGL = Backward Class, Girls) carries
  // both the seat type and the gender pool; it is emitted verbatim and decoded
  // during resolution, where counselling_dimension_map can be consulted.
  const out = [
    ['Institute', 'Academic Program Name', 'Quota', 'Seat Type', 'Gender',
     'Round', 'Exam', 'Opening Rank', 'Closing Rank'].join(','),
  ];
  let skipped = 0;
  for (const r of all) {
    const cat = r[col['Category']];
    // "NET SEATS" is a per-institute summary line, not a cutoff.
    if (!cat || cat.toUpperCase() === 'NET SEATS') { skipped++; continue; }

    // UPTAC publishes the full grid of every institute x branch x category,
    // with ranks only where a seat was actually allotted. A row with no rank
    // is not a cutoff, so it is dropped rather than shipped for the validator
    // to reject 15,000 times.
    const open = r[col['Opening Rank']];
    const close = r[col['Closing Rank']];
    const hasRank = (v) => v && v !== '-' && /\d/.test(v);
    if (!hasRank(open) && !hasRank(close)) { skipped++; continue; }

    // The same counselling also fills seats from CUET-UG and board merit,
    // which are different rank series. Only the JEE (Main) channel belongs in
    // a JEE-keyed predictor; the rest need their own exams first.
    const examName = (r[col['Exam Name']] || '').trim().toLowerCase();
    if (examName !== 'jee-main') { skipped++; continue; }
    out.push([
      r[col['Institute']],
      r[col['Branch']],
      'Home State',
      cat,
      r[col['Seat Gender']],
      (/(\d+)/.exec(r[col['Round']]) || [, '1'])[1],
      r[col['Exam Name']],
      r[col['Opening Rank']],
      r[col['Closing Rank']],
    ].map(csvCell).join(','));
  }

  const file = path.join(outDir, 'uptac-2026-all.csv');
  fs.writeFileSync(file, out.join('\n'), 'utf8');
  console.log(`\nwrote ${out.length - 1} rows (${skipped} summary rows skipped) -> ${file}`);
}

main().catch((e) => {
  console.error('uptac-scrape failed:', e.message);
  process.exit(1);
});
