/**
 * Turn a COMEDK engineering cut-off PDF into the canonical CSV.
 *
 *   node tools/comedk-parse.js --file data/comedk/comedk-2025-all.pdf \
 *                              --year 2025 --round 6 --out data/comedk
 *
 * COMEDK publishes a WIDE matrix: rows are (college, seat category), columns
 * are ~74 branch codes, and the page is split horizontally into groups of
 * about seven columns each. Plain text extraction destroys that -- the cells
 * come out as a stream with no idea which column they belonged to -- so this
 * reads each text item's x/y position and rebuilds the grid.
 *
 * Per page:
 *   1. header items matching "XX-Name" above the data area give the column
 *      code and its x origin
 *   2. a data row is a y with a college code near the left margin
 *   3. every numeric cell on that y is assigned to the nearest column whose
 *      origin is at or left of it
 */
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');

const pdfjs = createRequire(path.join(__dirname, '..', 'api', 'package.json'))(
  'pdf-parse/lib/pdf.js/v1.10.100/build/pdf.js',
);

const arg = (n, d) => {
  const i = process.argv.indexOf('--' + n);
  return i === -1 ? d : process.argv[i + 1];
};

/** Items on a page, normalised to {text, x, y}. */
async function pageItems(doc, pageNo) {
  const tc = await (await doc.getPage(pageNo)).getTextContent();
  return tc.items
    .map((i) => ({
      s: i.str.replace(/\s+/g, ' ').trim(),
      x: Math.round(i.transform[4] * 10) / 10,
      y: Math.round(i.transform[5] * 10) / 10,
    }))
    .filter((i) => i.s);
}

/**
 * Column origins for a page. A branch header is written as "AD-Artificial"
 * with the continuation on lines below, so only the item carrying the code
 * matters and the rest is ignored.
 */
function readColumns(items, dataTopY) {
  const cols = [];
  for (const it of items) {
    if (it.y <= dataTopY) continue;
    const m = /^([A-Z]{2,4})-/.exec(it.s);
    if (!m) continue;
    if (cols.some((c) => c.code === m[1])) continue;
    cols.push({ code: m[1], x: it.x });
  }
  return cols.sort((a, b) => a.x - b.x);
}

/** Nearest column at or left of x, within a tolerance for right-aligned cells. */
function columnFor(cols, x) {
  let best = null;
  for (const c of cols) {
    if (c.x - 6 <= x && (!best || c.x > best.x)) best = c;
  }
  return best;
}

/** College codes look like E001, either alone or glued to the name. */
const CODE_RE = new RegExp('^(E\\d{3})\\b\\s*(.*)$');

const csvCell = (v) => {
  const s = String(v ?? '');
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
};

async function main() {
  const file = arg('file');
  const year = arg('year');
  const round = arg('round', '1');
  const outDir = arg('out', path.join(__dirname, '..', 'data', 'comedk'));
  if (!file || !year) {
    console.error('Usage: --file <pdf> --year <YYYY> [--round N] [--out dir]');
    process.exit(1);
  }
  fs.mkdirSync(outDir, { recursive: true });

  const data = new Uint8Array(fs.readFileSync(file));
  const doc = await pdfjs.getDocument({ data, verbosity: 0 }).promise;
  console.log(`${path.basename(file)}: ${doc.numPages} pages`);

  const rows = [];
  // Code -> name, so a college named on one page is known on the next.
  const nameByCode = new Map();
  let pagesWithColumns = 0;

  for (let p = 1; p <= doc.numPages; p++) {
    const items = await pageItems(doc, p);
    if (!items.length) continue;

    // The data area starts below the header block; the lowest header item
    // marks the boundary. Fall back to a sane split if no header is found.
    const headerYs = items
      .filter((i) => /^[A-Z]{2,4}-/.test(i.s) || /^College$|^Seat$/.test(i.s))
      .map((i) => i.y);
    if (!headerYs.length) continue;
    const dataTopY = Math.min(...headerYs) - 1;

    const cols = readColumns(items, dataTopY);
    if (!cols.length) continue;
    pagesWithColumns++;

    // Group the data area by row.
    const byY = new Map();
    for (const it of items) {
      if (it.y >= dataTopY) continue;
      if (!byY.has(it.y)) byY.set(it.y, []);
      byY.get(it.y).push(it);
    }

    // Walk top to bottom. In this layout the college name is wrapped across
    // its own lines ABOVE the line carrying the code and the ranks, so name
    // fragments are collected as they go by and attached to the next code row.
    const orderedYs = [...byY.keys()].sort((a, b) => b - a);
    let nameParts = [];

    for (const y of orderedYs) {
      const line = byY.get(y).sort((a, b) => a.x - b.x);
      const first = line[0];
      if (!first) continue;

      const codeMatch = CODE_RE.exec(first.s);
      if (!codeMatch) {
        // A lone left-hand text item is part of a college name.
        if (line.length <= 2 && first.x > 60 && first.x < 220 && /[A-Za-z]/.test(first.s)) {
          nameParts.push(first.s);
        }
        continue;
      }
      if (first.x > 120) continue;

      const collegeCode = codeMatch[1];
      const glued = codeMatch[2].trim();

      // Only the fragment immediately above belongs to this college: earlier
      // ones are the tail of the previous college's wrapped name, and joining
      // them produced "Bengaluru Acharya Institute of Technology".
      const nearest = nameParts.length ? nameParts[nameParts.length - 1] : '';
      let collegeName = glued || nearest;
      nameParts = [];

      // A college appears once per seat category. Remember the first good
      // name so the later rows are not left with just the code.
      if (collegeName && collegeName.length > 4) {
        nameByCode.set(collegeCode, collegeName);
      } else {
        collegeName = nameByCode.get(collegeCode) ?? collegeCode;
      }

      // Seat category sits between the name and the first branch column.
      const catItem = line.find((i) => i.x > 200 && i.x < cols[0].x - 10 && /^[A-Z]{2,8}$/.test(i.s));
      // Some layouts append the category to the name with no separator.
      let category = catItem?.s;
      if (!category) {
        const glued = /([A-Z]{2,4})(\d+)?$/.exec(collegeName);
        if (glued) {
          category = glued[1];
          collegeName = collegeName.slice(0, glued.index).trim();
        }
      }
      if (!category) continue;

      for (const cell of line) {
        if (!/^\d+$/.test(cell.s)) continue;
        if (cell.x < cols[0].x - 6) continue;
        const col = columnFor(cols, cell.x);
        if (!col) continue;
        rows.push({
          college: collegeName || collegeCode,
          collegeCode,
          branch: col.code,
          category,
          rank: cell.s,
        });
      }
    }
  }

  console.log(`  ${pagesWithColumns} pages carried a column header`);
  console.log(`  ${rows.length} cutoff cells recovered`);

  const out = [
    ['Institute', 'Academic Program Name', 'Quota', 'Seat Type', 'Gender',
     'Round', 'Opening Rank', 'Closing Rank'].join(','),
  ];
  for (const r of rows) {
    out.push([
      r.college,
      r.branch,              // a COMEDK branch code; aliased in the seed
      'Home State',          // COMEDK admits to Karnataka colleges
      r.category,
      'Gender-Neutral',      // COMEDK publishes no gender pool
      round,
      '',                    // only the closing rank is published
      r.rank,
    ].map(csvCell).join(','));
  }

  const outFile = path.join(outDir, `comedk-${year}-r${round}.csv`);
  fs.writeFileSync(outFile, out.join('\n'), 'utf8');
  console.log(`  wrote ${rows.length} rows -> ${outFile}`);
}

main().catch((e) => {
  console.error('comedk-parse failed:', e.message);
  process.exit(1);
});
