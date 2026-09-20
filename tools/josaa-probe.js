const { chromium } = require('playwright');
const URL = 'https://josaa.admissions.nic.in/applicant/seatmatrix/openingclosingrankarchieve.aspx';

(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('requestfailed', (r) => errors.push(`FAILED ${r.url().slice(0, 90)}`));

  await page.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });

  const info = await page.evaluate(() => ({
    hasDoPostBack: typeof window.__doPostBack,
    hasTheForm: typeof window.theForm,
    forms: [...document.forms].map((f) => ({ name: f.name, id: f.id, action: f.action })),
    hiddens: [...document.querySelectorAll('input[type=hidden]')].map((h) => h.name).slice(0, 12),
    scripts: [...document.scripts].map((s) => s.src).filter(Boolean).slice(0, 10),
    yearOptions: [...(document.getElementById('ctl00_ContentPlaceHolder1_ddlYear')?.options || [])]
      .map((o) => o.value).slice(0, 5),
  }));
  console.log(JSON.stringify(info, null, 2));
  if (errors.length) console.log('\nPAGE ERRORS:\n  ' + errors.slice(0, 8).join('\n  '));
  await browser.close();
})().catch((e) => { console.error('probe failed:', e.message); process.exit(1); });
