/**
 * Download JoSAA opening/closing ranks for a year and write one CSV per round.
 *
 *   node tools/josaa-scrape.js --year 2025 --rounds 1-6 --out ./data
 *
 * Every dropdown has an ALL option, so one round is ONE page load: a full year
 * costs six requests. There is no excuse for hammering this server, and the
 * delay below is deliberately generous.
 *
 * On the user agent: it must begin with "Mozilla/" or ASP.NET's legacy
 * browserCaps decides the client cannot run JavaScript and omits __EVENTTARGET,
 * which is what drives the form. Measured on the live site, Googlebot and a
 * bare "Mozilla/5.0" both receive the fields while "curl/8.5.0" does not --
 * capability sniffing, not a bot block. We really are Chromium, so the Chrome
 * token is accurate, and the suffix keeps us identifiable in the access log.
 */
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

/**
 * Two pages, same ASP.NET form, small differences.
 *
 * The archive covers 2016-2025 and has a year dropdown. The current-year page
 * has no year (it is implicitly the live season) and spells the seat-type
 * control "ddlSeattype" with a lowercase t.
 */
const PAGES = {
  archive: {
    url: 'https://josaa.admissions.nic.in/applicant/seatmatrix/openingclosingrankarchieve.aspx',
    hasYear: true,
    seatTypeField: 'ddlSeatType',
  },
  current: {
    url: 'https://josaa.admissions.nic.in/Applicant/seatallotmentresult/currentorcr.aspx',
    hasYear: false,
    seatTypeField: 'ddlSeattype',
  },
  // CSAB runs the special rounds after JoSAA closes, on the same NIC platform
  // and the same page names, just under /csabspl/. Same form, same technique.
  csab: {
    url: 'https://admissions.nic.in/csabspl/Applicant/seatallotmentresult/openingclosingrankarchieve.aspx',
    hasYear: true,
    seatTypeField: 'ddlSeatType',
  },
  csab_current: {
    url: 'https://admissions.nic.in/csabspl/Applicant/seatallotmentresult/currentorcr.aspx',
    hasYear: false,
    seatTypeField: 'ddlSeattype',
  },
};
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';

const DELAY_MS = 6000;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function arg(name, fallback) {
  const i = process.argv.indexOf('--' + name);
  return i === -1 ? fallback : process.argv[i + 1];
}

function parseRounds(spec) {
  if (spec.includes('-')) {
    const [a, b] = spec.split('-').map(Number);
    return Array.from({ length: b - a + 1 }, (_, i) => a + i);
  }
  return spec.split(',').map(Number);
}

async function setField(page, name, value) {
  const id = 'ctl00_ContentPlaceHolder1_' + name;
  const postName = 'ctl00$ContentPlaceHolder1$' + name;
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle', timeout: 120000 }),
    page.evaluate(
      ({ id, value, postName }) => {
        const form = document.forms['aspnetForm'];
        const target = document.querySelector('input[name="__EVENTTARGET"]');
        const argument = document.querySelector('input[name="__EVENTARGUMENT"]');
        if (!target) throw new Error('__EVENTTARGET missing - downlevel page served');
        document.getElementById(id).value = value;
        target.value = postName;
        if (argument) argument.value = '';
        form.submit();
      },
      { id, value, postName },
    ),
  ]);
}

async function submit(page) {
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle', timeout: 180000 }),
    page.evaluate(() => {
      const form = document.forms['aspnetForm'];
      const target = document.querySelector('input[name="__EVENTTARGET"]');
      const argument = document.querySelector('input[name="__EVENTARGUMENT"]');
      target.value = 'ctl00$ContentPlaceHolder1$btnSubmit';
      if (argument) argument.value = '';
      form.submit();
    }),
  ]);
}

/** Pull the widest table on the page as a header row plus data rows. */
async function extractTable(page) {
  return page.evaluate(() => {
    const tables = [...document.querySelectorAll('table')];
    let best = null;
    for (const t of tables) {
      const rows = t.querySelectorAll('tr');
      if (rows.length < 2) continue;
      const cols = rows[0].querySelectorAll('th,td').length;
      // The results grid is the one with the most cells; the page also holds
      // small layout tables.
      const score = rows.length * cols;
      if (!best || score > best.score) best = { t, score, cols, rowCount: rows.length };
    }
    if (!best) return null;

    const cells = (tr) =>
      [...tr.querySelectorAll('th,td')].map((c) => c.textContent.replace(/\s+/g, ' ').trim());
    const all = [...best.t.querySelectorAll('tr')].map(cells);
    return { header: all[0], rows: all.slice(1), cols: best.cols };
  });
}

const csvCell = (v) => {
  const s = String(v ?? '');
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};

async function main() {
  const year = arg('year', '2025');
  const mode = arg('page', 'archive');
  const profile = PAGES[mode];
  if (!profile) throw new Error('--page must be one of: ' + Object.keys(PAGES).join(', '));
  const rounds = parseRounds(arg('rounds', '1-6'));
  const outDir = arg('out', path.join(__dirname, '..', 'data'));
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  const page = await browser.newPage({ userAgent: UA });
  const written = [];

  try {
    for (const round of rounds) {
      console.log(`\n=== ${year} round ${round} ===`);
      await page.goto(profile.url, { waitUntil: 'networkidle', timeout: 120000 });

      if (profile.hasYear) await setField(page, 'ddlYear', String(year));
      await setField(page, 'ddlroundno', String(round));
      await setField(page, 'ddlInstype', 'ALL');
      await setField(page, 'ddlInstitute', 'ALL');
      await setField(page, 'ddlBranch', 'ALL');
      // Seat type is the last level and does not cascade, so set it inline.
      // Not every variant of this page has a seat-type control; where it is
      // absent the report already covers all seat types.
      await page.evaluate((field) => {
        const el =
          document.getElementById('ctl00_ContentPlaceHolder1_' + field) ||
          document.getElementById('ctl00_ContentPlaceHolder1_ddlSeattype') ||
          document.getElementById('ctl00_ContentPlaceHolder1_ddlSeatType');
        if (el) el.value = 'ALL';
      }, profile.seatTypeField);

      await submit(page);
      const table = await extractTable(page);

      if (!table || table.rows.length === 0) {
        console.log('  no rows returned - round may not exist for this year');
        continue;
      }

      console.log(`  header: ${table.header.join(' | ')}`);
      console.log(`  rows:   ${table.rows.length}`);

      const prefix = mode.startsWith('csab') ? 'csab' : 'josaa';
      const file = path.join(outDir, `${prefix}-${year}-r${round}.csv`);
      const lines = [table.header.map(csvCell).join(',')];
      for (const r of table.rows) lines.push(r.map(csvCell).join(','));
      fs.writeFileSync(file, lines.join('\n'), 'utf8');
      console.log(`  wrote:  ${file}`);
      written.push({ file, rows: table.rows.length });

      await sleep(DELAY_MS);
    }
  } finally {
    await browser.close();
  }

  console.log('\n=== summary ===');
  for (const w of written) console.log(`  ${w.rows} rows  ${w.file}`);
  if (written.length === 0) process.exitCode = 1;
}

main().catch((e) => {
  console.error('scrape failed:', e.message);
  process.exit(1);
});
