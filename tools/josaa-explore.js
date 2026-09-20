/**
 * Reconnaissance for the JoSAA OR-CR archive form.
 *
 * Before writing a scraper, find out how many requests one year actually
 * costs. If the institute and programme dropdowns carry an "ALL" option the
 * whole year is a handful of requests; if not, it is thousands, and the polite
 * approach changes completely.
 *
 *   node tools/josaa-explore.js 2025
 */
const { chromium } = require('playwright');

const URL = 'https://josaa.admissions.nic.in/applicant/seatmatrix/openingclosingrankarchieve.aspx';
const ID = (n) => `#ctl00_ContentPlaceHolder1_${n}`;

/**
 * Must start with "Mozilla/" and this is not evasion.
 *
 * Measured against the live site: Googlebot, bare "Mozilla/5.0", Chrome and
 * Firefox all receive __EVENTTARGET; "curl/8.5.0" and a plain named-bot string
 * do not. That is ASP.NET's legacy browserCaps deciding the client cannot run
 * JavaScript and serving a downlevel page -- progressive enhancement from 2005,
 * not a bot countermeasure (a real one would block Googlebot, not serve it).
 *
 * We genuinely are Chromium with JavaScript, so the Chrome token is accurate.
 * The suffix keeps us identifiable to whoever reads the access logs.
 */
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/153.0.0.0 Safari/537.36 BTechAdmissionPredictor/0.1 (+contact@example.com)';

async function options(page, name) {
  return page.$$eval(`${ID(name)} option`, (els) =>
    els.map((e) => ({ value: e.value, text: e.textContent.trim() })),
  );
}

/**
 * Drive one cascading dropdown.
 *
 * Two things make this awkward:
 *  - the selects carry class="chosen-select", so the jQuery Chosen plugin
 *    hides the native element and selectOption() times out on it;
 *  - __doPostBack comes from a WebResource.axd script that is sometimes still
 *    loading when networkidle fires, so calling it races.
 *
 * Setting __EVENTTARGET and submitting the form is precisely what
 * __doPostBack does, and it depends on nothing but the DOM.
 */
async function choose(page, name, value) {
  const id = `ctl00_ContentPlaceHolder1_${name}`;
  const postName = `ctl00$ContentPlaceHolder1$${name}`;

  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle', timeout: 90000 }),
    page.evaluate(
      ({ id, value, postName }) => {
        // Named form access (form.__EVENTTARGET) is unreliable here; query the
        // hidden inputs directly.
        const form = document.forms['aspnetForm'];
        const target = document.querySelector('input[name="__EVENTTARGET"]');
        const argument = document.querySelector('input[name="__EVENTARGUMENT"]');
        if (!form || !target) throw new Error('ASP.NET form or __EVENTTARGET not found');
        document.getElementById(id).value = value;
        target.value = postName;
        if (argument) argument.value = '';
        form.submit();
      },
      { id, value, postName },
    ),
  ]);
}

/** The Submit button is a normal postback target, same mechanism. */
async function submit(page) {
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle', timeout: 90000 }),
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

(async () => {
  const year = process.argv[2] || '2025';
  // channel:'chromium' uses the full Chromium build. The default headless mode
  // wants chrome-headless-shell, which is a separate download.
  const browser = await chromium.launch({ headless: true, channel: 'chromium' });
  const page = await browser.newPage({ userAgent: UA });

  try {
    await page.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
    console.log('title:', await page.title());

    await choose(page, 'ddlYear', year);
    console.log('');
    console.log('year=' + year);

    // Walk the cascade one level at a time, taking the first real option at
    // each step, and report how many choices each level offers. The product of
    // those counts is what a full-year scrape would cost in page loads.
    const chain = ['ddlroundno', 'ddlInstype', 'ddlInstitute', 'ddlBranch', 'ddlSeatType'];
    const counts = {};

    for (const dd of chain) {
      const opts = await options(page, dd);
      const real = opts.filter((o) => o.value && o.value !== '0');
      counts[dd] = real.length;

      console.log('');
      console.log('--- ' + dd + ': ' + real.length + ' real options ---');
      real.slice(0, 10).forEach((o) => console.log('    "' + o.value + '" = ' + o.text.slice(0, 62)));
      if (real.length > 10) console.log('    ... ' + (real.length - 10) + ' more');

      // An "ALL" option collapses a whole level into a single request.
      const all = real.find((o) => /^all|all institute|all program|^--all/i.test(o.text));
      if (all) console.log('    >>> ALL option present: "' + all.value + '" = ' + all.text);

      if (real.length === 0) break;
      if (dd !== 'ddlSeatType') {
        const pick = all || real[0];
        await choose(page, dd, pick.value);
        console.log('    [selected: ' + pick.text.slice(0, 50) + ']');
      }
    }

    console.log('');
    console.log('=== cost estimate for one full year ===');
    console.log('   ' + JSON.stringify(counts));

  } finally {
    await browser.close();
  }
})().catch((e) => {
  console.error('explore failed:', e.message);
  process.exit(1);
});
