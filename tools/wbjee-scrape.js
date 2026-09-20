/**
 * Download WBJEEB opening/closing ranks and write one CSV per year and channel.
 *
 *   node tools/wbjee-scrape.js --out ./data/wbjee
 *
 * Unlike JoSAA this needs no form driving: the report page returns the whole
 * year as one long-format HTML table (about 7 MB, 4-5k rows, all rounds). The
 * `enc` tokens below are the static links published on the WBJEEB eServices
 * page; re-read that page if a year stops working.
 *
 * WBJEEB's "Seat Type" column is the admission channel -- whether the seat is
 * allotted on the WBJEE rank or the JEE (Main) rank. Those are two different
 * exams and therefore two different rank series, so each becomes its own file.
 * WBJEEB's "Category" column is what JoSAA calls seat type, and is emitted
 * under that name so the shared parser understands it.
 */
const fs = require('node:fs');
const path = require('node:path');

const BASE = 'https://admissions.nic.in/wbjeeb/Applicant/report/orcrreport.aspx?enc=';
const YEARS = {
  2026: 'yVQCIiq12npg+pcvNJRdc0HDRnuJ9gFOaCInZL4j9NW30CHtS0gho2BQTEcrr6Wa',
  2025: 'Nm7QwHILXclJQSv2YVS+7ud0s9OnRxxLItScoKR31F4qbKNJ7YB3loiJ7DTFho11',
  2024: 'Nm7QwHILXclJQSv2YVS+7l8OpFY/O746kfneOXEneV50mv1B/txHsSKB11hFlsvw',
  2023: 'b6w3EPyuw0C4FADZ4v1XmYUz0XFq314fzLjkE3wbM2xr/DbsjpvUS9LBCKXjSeSL',
  2022: 'Nm7QwHILXclJQSv2YVS+7hcjwg9gJLL3dN9nSB9R2fAEJ/7sG2MvnUlvdh4rG3CN',
  2021: 'Nm7QwHILXclJQSv2YVS+7t5O5EVrvqMhdk/bbq9ioFjahMV3TyfdCGo7ms/IlfkE',
};

/** WBJEEB "Seat Type" value -> the exam whose rank that seat is allotted on. */
const CHANNEL_EXAM = {
  'WBJEE Seats': 'WBJEE',
  'JEE(Main) Seats': 'JEE_MAIN',
};
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';

const arg = (n, d) => {
  const i = process.argv.indexOf('--' + n);
  return i === -1 ? d : process.argv[i + 1];
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function stripTags(s) {
  return s
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
}

function parseTable(html) {
  const rows = html.match(/<tr[^>]*>[\s\S]*?<\/tr>/gi) || [];
  const out = [];
  for (const r of rows) {
    const cells = (r.match(/<t[dh][^>]*>[\s\S]*?<\/t[dh]>/gi) || []).map(stripTags);
    if (cells.length) out.push(cells);
  }
  return out;
}

const csvCell = (v) => {
  const s = String(v ?? '');
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};

async function main() {
  const outDir = arg('out', path.join(__dirname, '..', 'data', 'wbjee'));
  const only = arg('year');
  fs.mkdirSync(outDir, { recursive: true });

  const years = only ? [only] : Object.keys(YEARS).sort().reverse();
  const written = [];

  for (const year of years) {
    const token = YEARS[year];
    if (!token) {
      console.error(`no token for ${year}`);
      continue;
    }
    console.log(`\n=== WBJEEB ${year} ===`);
    const res = await fetch(BASE + token, { headers: { 'User-Agent': UA } });
    if (!res.ok) {
      console.error(`  HTTP ${res.status}`);
      continue;
    }
    const html = await res.text();
    console.log(`  fetched ${(html.length / 1e6).toFixed(1)} MB`);

    const table = parseTable(html);
    if (table.length < 2) {
      console.error('  no table rows');
      continue;
    }
    const header = table[0];
    const col = Object.fromEntries(header.map((h, i) => [h, i]));
    const need = ['Round', 'Institute', 'Program', 'Seat Type', 'Quota', 'Category',
                  'Opening Rank', 'Closing Rank'];
    const missing = need.filter((n) => col[n] === undefined);
    if (missing.length) {
      console.error(`  missing columns: ${missing.join(', ')}`);
      continue;
    }

    // Split by admission channel: each is a different exam's rank series.
    const byChannel = new Map();
    for (const r of table.slice(1)) {
      if (r.length !== header.length) continue;
      const exam = CHANNEL_EXAM[r[col['Seat Type']]];
      if (!exam) continue;
      if (!byChannel.has(exam)) byChannel.set(exam, []);
      byChannel.get(exam).push(r);
    }

    for (const [exam, rows] of byChannel) {
      // Emit the column names the shared TabularParser recognises. WBJEEB's
      // "Category" is what JoSAA calls Seat Type; WBJEEB's own "Seat Type" is
      // the channel and is already encoded in the filename.
      const out = [
        ['Institute', 'Academic Program Name', 'Quota', 'Seat Type', 'Gender',
         'Round', 'Opening Rank', 'Closing Rank'].join(','),
      ];
      for (const r of rows) {
        out.push([
          r[col['Institute']],
          r[col['Program']],
          r[col['Quota']],
          r[col['Category']],
          // WBJEEB publishes no gender pool; every seat is gender-neutral.
          'Gender-Neutral',
          (/(\d+)/.exec(r[col['Round']]) || [, '1'])[1],
          r[col['Opening Rank']],
          r[col['Closing Rank']],
        ].map(csvCell).join(','));
      }
      const file = path.join(outDir, `wbjee-${year}-${exam.toLowerCase()}.csv`);
      fs.writeFileSync(file, out.join('\n'), 'utf8');
      console.log(`  ${String(rows.length).padStart(5)} rows -> ${file}`);
      written.push({ file, rows: rows.length, year, exam });
    }
    await sleep(5000);
  }

  console.log('\n=== summary ===');
  let total = 0;
  for (const w of written) {
    console.log(`  ${String(w.rows).padStart(5)} rows  ${w.year} ${w.exam}`);
    total += w.rows;
  }
  console.log(`  ${String(total).padStart(5)} rows total`);
}

main().catch((e) => {
  console.error('wbjee-scrape failed:', e.message);
  process.exit(1);
});
