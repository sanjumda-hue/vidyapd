/** Dump every link on a page, optionally filtered, to find where data lives. */
const { chromium } = require('playwright');
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';

(async () => {
  const url = process.argv[2];
  const filter = process.argv[3] ? new RegExp(process.argv[3], 'i') : null;
  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  const page = await browser.newPage({ userAgent: UA });
  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 90000 });
    const links = await page.evaluate(() =>
      [...document.querySelectorAll('a')].map((a) => ({
        text: a.textContent.replace(/\s+/g, ' ').trim(),
        href: a.href,
      })),
    );
    const seen = new Set();
    let n = 0;
    for (const l of links) {
      if (!l.href || seen.has(l.href)) continue;
      seen.add(l.href);
      if (filter && !filter.test(l.text + ' ' + l.href)) continue;
      console.log((l.text || '(no text)').slice(0, 52).padEnd(52), l.href.slice(0, 95));
      if (++n > 60) break;
    }
    console.log('---', seen.size, 'distinct links,', n, 'shown');
  } finally {
    await browser.close();
  }
})().catch((e) => { console.error('FAILED:', e.message.split('\n')[0]); process.exit(1); });
