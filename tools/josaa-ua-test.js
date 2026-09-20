const { chromium } = require('playwright');
const URL = 'https://josaa.admissions.nic.in/applicant/seatmatrix/openingclosingrankarchieve.aspx';

const AGENTS = [
  ['default (playwright)', undefined],
  ['custom bot UA', 'BTechAdmissionPredictor/0.1 (+contact@example.com)'],
];

(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  for (const [label, ua] of AGENTS) {
    const page = await browser.newPage(ua ? { userAgent: ua } : {});
    await page.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
    const info = await page.evaluate(() => ({
      title: document.title,
      hasEventTarget: !!document.querySelector('input[name="__EVENTTARGET"]'),
      hasForm: !!document.forms['aspnetForm'],
      yearOpts: (document.getElementById('ctl00_ContentPlaceHolder1_ddlYear')?.options || []).length,
      bodyStart: document.body.innerText.trim().slice(0, 100).replace(/\s+/g, ' '),
    }));
    console.log(`${label}:`, JSON.stringify(info));
    await page.close();
  }
  await browser.close();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
