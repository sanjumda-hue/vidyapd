/** Report the ASP.NET form shape of a page: selects, buttons, postback fields. */
const { chromium } = require('playwright');
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';

(async () => {
  const target = process.argv[2];
  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  const page = await browser.newPage({ userAgent: UA });
  try {
    const resp = await page.goto(target, { waitUntil: 'domcontentloaded', timeout: 90000 });
    await page.waitForTimeout(2500);
    console.log('status:', resp.status(), '| title:', await page.title());
    const info = await page.evaluate(() => ({
      eventTarget: !!document.querySelector('input[name="__EVENTTARGET"]'),
      forms: [...document.forms].map((f) => f.name || f.id),
      selects: [...document.querySelectorAll('select')].map((s) => ({
        id: s.id,
        cls: s.className,
        n: s.options.length,
        sample: [...s.options].slice(0, 5).map((o) => o.value + '=' + o.textContent.replace(/\s+/g, ' ').trim().slice(0, 30)),
      })),
      buttons: [...document.querySelectorAll('input[type=submit],button')].map((x) => x.id || x.name).filter(Boolean),
      tables: document.querySelectorAll('table').length,
    }));
    console.log('__EVENTTARGET:', info.eventTarget, '| forms:', info.forms.join(','), '| tables:', info.tables);
    console.log('buttons:', info.buttons.join(', ') || '(none)');
    for (const s of info.selects) {
      console.log(`  select #${s.id} [${s.cls}] ${s.n} options`);
      s.sample.forEach((o) => console.log('       ', o));
    }
  } catch (e) {
    console.error('FAILED:', e.message.split('\n')[0]);
  } finally {
    await browser.close();
  }
})();
