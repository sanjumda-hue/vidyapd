/** Fetch a page with a real browser and report what actually came back. */
const { chromium } = require('playwright');
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';

(async () => {
  const url = process.argv[2];
  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  const page = await browser.newPage({ userAgent: UA });
  try {
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 90000 });
    console.log('status :', resp && resp.status());
    console.log('url    :', page.url());
    console.log('title  :', await page.title());
    const info = await page.evaluate(() => ({
      text: document.body.innerText.replace(/\s+/g, ' ').trim().slice(0, 300),
      links: [...document.querySelectorAll('a')]
        .map((a) => ({ t: a.textContent.replace(/\s+/g, ' ').trim(), h: a.href }))
        .filter((x) => /rank|cut.?off|orcr|opening|closing|round|allot/i.test(x.t))
        .slice(0, 25),
    }));
    console.log('text   :', info.text);
    console.log('relevant links:');
    info.links.forEach((l) => console.log('   -', l.t.slice(0, 60), '=>', l.h));
  } catch (e) {
    console.error('FAILED:', e.message.split('\n')[0]);
  } finally {
    await browser.close();
  }
})();
