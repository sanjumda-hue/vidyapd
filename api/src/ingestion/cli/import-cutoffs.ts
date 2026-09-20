/**
 * Stage a downloaded cutoff file, then optionally approve and publish it.
 *
 *   npm run import:cutoffs -- --file ./data/josaa-2026-r5.csv \
 *                             --source JOSAA_ORCR --year 2026 --round 5
 *
 *   # first ever import, when the college master is empty:
 *   ... --create-missing
 *
 *   # skip the review step (only for a source you trust and a file you checked):
 *   ... --publish
 *
 * Without --publish the job stops at pending_review, which is the default on
 * purpose: cutoff data is what students act on.
 */
import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';

import { AppModule } from '../../app.module';
import { ImportRunner } from '../pipeline/import-runner';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? undefined : process.argv[i + 1];
}
const flag = (name: string) => process.argv.includes(`--${name}`);

async function main(): Promise<void> {
  const log = new Logger('import-cutoffs');

  const file = arg('file');
  const source = arg('source');
  const year = arg('year');
  if (!file || !source || !year) {
    console.error(
      'Usage: --file <path> --source <SOURCE_CODE> --year <YYYY> [--round N] [--create-missing] [--publish]',
    );
    process.exit(1);
  }

  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['log', 'warn', 'error'] });
  try {
    const runner = app.get(ImportRunner);

    const result = await runner.stage({
      filePath: file,
      sourceCode: source,
      academicYear: Number.parseInt(year, 10),
      roundNo: arg('round') ? Number.parseInt(arg('round') as string, 10) : undefined,
      createMissing: flag('create-missing'),
    });

    log.log(`job ${result.jobId}: ${result.parsed} parsed, ${result.valid} valid, ${result.invalid} invalid`);

    if (result.unresolved.length > 0) {
      log.warn('Labels that could not be resolved (fix these, then re-run):');
      for (const u of result.unresolved) {
        log.warn(`  ${String(u.rows).padStart(7)} rows  ${u.label}`);
      }
    }

    if (result.valid === 0) {
      log.error('Nothing valid to publish. Job left as validation_failed.');
      process.exitCode = 1;
      return;
    }

    if (!flag('publish')) {
      log.log(`Staged for review. Approve with:`);
      log.log(`  curl -X POST localhost:3000/api/v1/admin/imports/${result.jobId}/approve`);
      log.log(`  curl -X POST localhost:3000/api/v1/admin/imports/${result.jobId}/publish`);
      return;
    }

    await runner.approve(result.jobId, undefined, 'auto-approved via --publish');
    const published = await runner.publish(result.jobId);
    log.log(`published: ${published.inserted} inserted, ${published.updated} updated`);
  } finally {
    await app.close();
  }
}

main().catch((e) => {
  console.error(e instanceof Error ? e.stack : e);
  process.exit(1);
});
