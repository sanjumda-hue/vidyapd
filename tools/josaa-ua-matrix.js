/**
 * Is the missing __EVENTTARGET a bot block, or legacy ASP.NET capability
 * sniffing?
 *
 * ASP.NET's browserCaps falls back to a "downlevel" profile for user agents it
 * does not recognise and then omits the __doPostBack plumbing, on the 2005-era
 * assumption that such a client cannot run JavaScript. If that is what is
 * happening, ANY recognisably-Mozilla UA gets the fields and obviously-bot
 * strings like Googlebot get them too. A real bot block would behave the
 * opposite way.
 */
const { chromium } = require('playwright');
const URL = 'https://josaa.admissions.nic.in/applicant/seatmatrix/openingclosingrankarchieve.aspx';

const AGENTS = [
  ['modern Chrome', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36'],
  ['old Firefox',   'Mozilla/5.0 (Windows NT 10.0; rv:120.0) Gecko/20100101 Firefox/120.0'],
  ['Googlebot',     'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'],
  ['bare Mozilla',  'Mozilla/5.0'],
  ['named bot, no Mozilla', 'BTechAdmissionPredictor/0.1 (+contact@example.com)'],
  ['curl-like',     'curl/8.5.0'],
];

(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  for (const [label, ua] of AGENTS) {
    const page = await browser.newPage({ userAgent: ua });
    let res;
    try {
      const resp = await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
      res = await page.evaluate(() => ({
        eventTarget: !!document.querySelector('input[name="__EVENTTARGET"]'),
        viewState: !!document.querySelector('input[name="__VIEWSTATE"]'),
        years: (document.getElementById('ctl00_ContentPlaceHolder1_ddlYear')?.options || []).length,
      }));
      res.status = resp.status();
    } catch (e) {
      res = { error: e.message.slice(0, 50) };
    }
    console.log(
      `${label.padEnd(24)} status=${res.status ?? '-'} __EVENTTARGET=${String(res.eventTarget).padEnd(5)} __VIEWSTATE=${String(res.viewState).padEnd(5)} years=${res.years ?? '-'}`,
    );
    await page.close();
    await new Promise((r) => setTimeout(r, 2500)); // be polite between hits
  }
  await browser.close();
})().catch((e) => { console.error('failed:', e.message); process.exit(1); });
