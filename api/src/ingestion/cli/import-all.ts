/**
 * Import every josaa-<year>-r<round>.csv in a directory, in one process.
 *
 *   npm run import:all -- --dir ../data
 *
 * One Nest context and one connection pool for the whole batch, rather than
 * paying startup and pool warm-up 22 times.
 *
 * Re-running is safe: publish upserts on the natural key, so a file that has
 * already been loaded is updated in place rather than duplicated.
 */
import { readdirSync } from 'node:fs';
import { join } from 'node:path';

import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from '../../app.module';
import { ImportRunner } from '../pipeline/import-runner';

function arg(name: string, fallback?: string): string | undefined {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? fallback : process.argv[i + 1];
}

async function main(): Promise<void> {
  const log = new Logger('import-all');
  const dir = arg('dir', '../data') as string;

  // josaa-<year>-r<round>.csv  -> JoSAA, round in the filename
  // wbjee-<year>-<exam>.csv     -> WBJEEB, round is a column, exam in the name
  const files = readdirSync(dir)
    .map((f) => {
      const josaa = /^josaa-(\d{4})-r(\d+)\.csv$/.exec(f);
      if (josaa) {
        return {
          file: join(dir, f),
          year: Number.parseInt(josaa[1], 10),
          round: Number.parseInt(josaa[2], 10),
          authority: 'JOSAA' as const,
          examCode: undefined as string | undefined,
        };
      }
      const comedk = /^comedk-(\d{4})-r(\d+)\.csv$/.exec(f);
      if (comedk) {
        return {
          file: join(dir, f),
          year: Number.parseInt(comedk[1], 10),
          round: Number.parseInt(comedk[2], 10),
          authority: 'COMEDK' as const,
          examCode: undefined as string | undefined,
        };
      }
      const csab = /^csab-(\d{4})-r(\d+)\.csv$/.exec(f);
      if (csab) {
        return {
          file: join(dir, f),
          year: Number.parseInt(csab[1], 10),
          round: Number.parseInt(csab[2], 10),
          authority: 'CSAB' as const,
          examCode: undefined as string | undefined,
        };
      }
      const uptac = /^uptac-(\d{4})-all\.csv$/.exec(f);
      if (uptac) {
        return {
          file: join(dir, f),
          year: Number.parseInt(uptac[1], 10),
          // Round is a column in this feed, not part of the filename.
          round: undefined as number | undefined,
          authority: 'UPTAC' as const,
          examCode: undefined as string | undefined,
        };
      }
      const bitsat = /^bitsat-(\d{4})-r(\d+)\.csv$/.exec(f);
      if (bitsat) {
        return {
          file: join(dir, f),
          year: Number.parseInt(bitsat[1], 10),
          round: Number.parseInt(bitsat[2], 10),
          authority: 'BITS' as const,
          examCode: undefined as string | undefined,
        };
      }
      const wbjee = /^wbjee-(\d{4})-(\w+)\.csv$/.exec(f);
      if (wbjee) {
        return {
          file: join(dir, f),
          year: Number.parseInt(wbjee[1], 10),
          round: undefined as number | undefined,
          authority: 'WBJEEB' as const,
          examCode: wbjee[2].toUpperCase(),
        };
      }
      return null;
    })
    .filter((x): x is NonNullable<typeof x> => x !== null)
    .sort((a, b) => a.year - b.year || (a.round ?? 0) - (b.round ?? 0));

  if (files.length === 0) {
    log.error(`No josaa-YYYY-rN.csv files in ${dir}`);
    process.exit(1);
  }
  log.log(`${files.length} files to import`);

  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['warn', 'error'] });
  const runner = app.get(ImportRunner);
  const summary: string[] = [];

  try {
    for (const { file, year, round, authority, examCode } of files) {
      // JoSAA's archive page only goes up to last season; the current year
      // comes from the live OR-CR page, and the two are separate data_sources.
      const source =
        authority === 'WBJEEB'
          ? 'WBJEEB_ORCR'
          : authority === 'UPTAC'
            ? 'UPTAC_SAMARTH'
            : authority === 'CSAB'
              ? 'CSAB_ORCR'
              : authority === 'COMEDK'
                ? 'COMEDK_COUNSELLING'
              : authority === 'BITS'
                ? 'BITS_CUTOFFS'
              : year >= new Date().getFullYear()
                ? 'JOSAA_ORCR'
                : 'JOSAA_ORCR_ARCHIVE';
      const started = Date.now();
      try {
        const staged = await runner.stage({
          filePath: file,
          sourceCode: source,
          academicYear: year,
          roundNo: round,
          createMissing: true,
          examCode,
        });
        if (staged.valid === 0) {
          summary.push(`${authority} ${year}: NOTHING VALID (${staged.parsed} parsed)`);
          continue;
        }
        await runner.approve(staged.jobId, undefined, 'batch import');
        const published = await runner.publish(staged.jobId);
        const secs = ((Date.now() - started) / 1000).toFixed(0);
        const label = round
          ? `${authority} ${year} r${round}`
          : `${authority} ${year}${examCode ? ' ' + examCode : ''}`;
        const line =
          `${label}: ${staged.parsed} parsed, ${staged.valid} valid, ` +
          `${staged.invalid} invalid -> ${published.inserted} new, ${published.updated} updated (${secs}s)`;
        log.log(line);
        summary.push(line);
      } catch (e) {
        const msg = e instanceof Error ? e.message.split('\n')[0] : String(e);
        log.error(`${year} r${round} FAILED: ${msg}`);
        summary.push(`${year} r${round}: FAILED - ${msg}`);
      }
    }
  } finally {
    await app.close();
  }

  console.log('\n=== summary ===');
  summary.forEach((l) => console.log('  ' + l));
}

main().catch((e) => {
  console.error(e instanceof Error ? e.stack : e);
  process.exit(1);
});
