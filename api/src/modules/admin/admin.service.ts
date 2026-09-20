import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';
import { ImportRunner } from '../../ingestion/pipeline/import-runner';

/** Import review, approval and data administration. */
@Injectable()
export class AdminService {
  constructor(
    protected readonly prisma: PrismaService,
    private readonly runner: ImportRunner,
  ) {}

  listJobs(status?: string, limit = 50) {
    return this.prisma.data_import_jobs.findMany({
      where: status ? { status: status as never } : {},
      orderBy: { created_at: 'desc' },
      take: limit,
      select: {
        id: true, status: true, academic_year: true, trigger_kind: true,
        rows_parsed: true, rows_valid: true, rows_invalid: true,
        rows_inserted: true, rows_updated: true,
        started_at: true, finished_at: true, published_at: true,
        error_summary: true,
        data_sources: { select: { code: true, name: true, tier: true } },
      },
    });
  }

  async jobDetail(id: bigint) {
    const job = await this.prisma.data_import_jobs.findUniqueOrThrow({
      where: { id },
      select: {
        id: true, status: true, academic_year: true, validation_report: true,
        rows_parsed: true, rows_valid: true, rows_invalid: true,
        artifact_path: true, review_note: true,
        data_sources: { select: { code: true, name: true, tier: true, url: true } },
      },
    });

    // A reviewer needs to see what actually failed, not just a count.
    const failures = await this.prisma.data_import_staging.findMany({
      where: { import_job_id: id, status: 'invalid' },
      take: 50,
      orderBy: { row_no: 'asc' },
      select: { row_no: true, raw: true, validation_errors: true },
    });

    const sample = await this.prisma.data_import_staging.findMany({
      where: { import_job_id: id, status: 'valid' },
      take: 10,
      orderBy: { row_no: 'asc' },
      select: { row_no: true, raw: true, normalized: true },
    });

    return { job, failures, sample };
  }

  approve(id: bigint, note?: string) {
    return this.runner.approve(id, undefined, note);
  }

  reject(id: bigint, note?: string) {
    return this.runner.reject(id, undefined, note);
  }

  publish(id: bigint) {
    return this.runner.publish(id);
  }

  /** Dashboard counters from design doc section 24. */
  async stats() {
    const [exams, colleges, branches, cutoffs, pending] = await Promise.all([
      this.prisma.exams.count({ where: { is_active: true } }),
      this.prisma.colleges.count({ where: { is_active: true } }),
      this.prisma.branches.count({ where: { is_active: true } }),
      this.prisma.cutoff_data.count(),
      this.prisma.data_import_jobs.count({ where: { status: 'pending_review' } }),
    ]);
    return { exams, colleges, branches, cutoffs, pendingImports: pending };
  }
}
