import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../../database/prisma.service';
import { CutoffValidator, NormalizedCutoffRow } from './cutoff-validator';
import { EntityResolver, ResolveContext } from './entity-resolver';
import { TabularParser } from './tabular-parser';

export interface StageOptions {
  filePath: string;
  sourceCode: string;
  academicYear: number;
  roundNo?: number;
  /** Bootstrap the college master from the feed. Tier-1 sources only. */
  createMissing?: boolean;
  /**
   * Which exam these ranks belong to, when the counselling allots on more than
   * one. WBJEEB fills the same seats from both the WBJEE and the JEE (Main)
   * merit lists; those are different rank series and must not be mixed, so the
   * caller says which file is which. Defaults to the process's primary exam.
   */
  examCode?: string;
}

export interface StageResult {
  jobId: bigint;
  parsed: number;
  valid: number;
  invalid: number;
  unresolved: Array<{ label: string; rows: number }>;
}

const CHUNK = 500;

/**
 * Walks a file through the pipeline the design doc requires:
 *
 *   parse -> stage (raw) -> resolve -> validate -> pending_review
 *                                                      |
 *                                            admin approves
 *                                                      v
 *                                            publish -> cutoff_data
 *
 * Nothing reaches cutoff_data except {@link publish}, and publish refuses a job
 * that has not been approved.
 */
@Injectable()
export class ImportRunner {
  private readonly logger = new Logger(ImportRunner.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly parser: TabularParser,
    private readonly resolver: EntityResolver,
    private readonly validator: CutoffValidator,
  ) {}

  async stage(opts: StageOptions): Promise<StageResult> {
    const source = await this.prisma.data_sources.findUnique({
      where: { code: opts.sourceCode },
      select: {
        id: true, tier: true, counselling_authority_id: true, counselling_process_id: true,
      },
    });
    if (!source) throw new NotFoundException(`Unknown data source: ${opts.sourceCode}`);
    if (!source.counselling_authority_id) {
      throw new BadRequestException(`Source ${opts.sourceCode} has no counselling authority.`);
    }
    if (opts.createMissing && !['official_authority', 'official_counselling'].includes(source.tier)) {
      throw new BadRequestException(
        `createMissing is only allowed for official sources; ${opts.sourceCode} is tier "${source.tier}".`,
      );
    }

    const process = await this.prisma.counselling_processes.findFirst({
      where: {
        counselling_authority_id: source.counselling_authority_id,
        academic_year: opts.academicYear,
      },
      select: { id: true },
    });
    if (!process) {
      throw new NotFoundException(
        `No counselling process for authority ${source.counselling_authority_id} in ${opts.academicYear}. Create it first.`,
      );
    }

    const job = await this.prisma.data_import_jobs.create({
      data: {
        source_id: source.id,
        counselling_process_id: process.id,
        academic_year: opts.academicYear,
        status: 'running',
        trigger_kind: 'manual',
        artifact_path: opts.filePath,
        started_at: new Date(),
        validation_report: opts.examCode
          ? ({ examCodeOverride: opts.examCode } as unknown as object)
          : undefined,
      },
      select: { id: true },
    });

    try {
      return await this.runStage(job.id, opts, {
        counsellingProcessId: process.id,
        counsellingAuthorityId: source.counselling_authority_id,
        createMissing: opts.createMissing ?? false,
        defaultStateId: await this.defaultStateFor(source.counselling_authority_id),
      });
    } catch (e) {
      await this.prisma.data_import_jobs.update({
        where: { id: job.id },
        data: {
          status: 'failed',
          finished_at: new Date(),
          error_summary: e instanceof Error ? e.message : String(e),
        },
      });
      throw e;
    }
  }

  private async runStage(
    jobId: bigint,
    opts: StageOptions,
    ctx: ResolveContext,
  ): Promise<StageResult> {
    const { rows } = this.parser.parse(opts.filePath, { roundNo: opts.roundNo });
    await this.resolver.warmUp(ctx);

    let valid = 0;
    let invalid = 0;
    let rowNo = 0;

    for (let i = 0; i < rows.length; i += CHUNK) {
      const slice = rows.slice(i, i + CHUNK);
      const staged: Prisma.data_import_stagingCreateManyInput[] = [];

      for (const raw of slice) {
        rowNo += 1;
        const normalized = await this.resolver.resolve(raw, ctx);
        const errors = this.validator.validate(raw, normalized);
        const ok = errors.length === 0;
        ok ? (valid += 1) : (invalid += 1);

        staged.push({
          import_job_id: jobId,
          row_no: rowNo,
          target_table: 'cutoff_data',
          raw: raw as unknown as object,
          normalized: ok ? (normalized as unknown as object) : undefined,
          status: ok ? ('valid' as const) : ('invalid' as const),
          validation_errors: errors.length > 0 ? (errors as unknown as object) : undefined,
        });
      }

      await this.prisma.data_import_staging.createMany({ data: staged, skipDuplicates: true });
      this.logger.log(`staged ${Math.min(i + CHUNK, rows.length)}/${rows.length}`);
    }

    const unresolved = this.resolver.unresolvedReport();

    await this.prisma.data_import_jobs.update({
      where: { id: jobId },
      data: {
        // Nothing usable means there is no point asking a human to approve it.
        status: valid === 0 ? 'validation_failed' : 'pending_review',
        rows_parsed: rows.length,
        rows_valid: valid,
        rows_invalid: invalid,
        finished_at: new Date(),
        validation_report: {
          unresolved,
          ...(opts.examCode ? { examCodeOverride: opts.examCode } : {}),
        } as unknown as object,
      },
    });

    return { jobId, parsed: rows.length, valid, invalid, unresolved };
  }

  /** Admin action. Only an approved job may be published. */
  async approve(jobId: bigint, userId?: bigint, note?: string): Promise<void> {
    const job = await this.prisma.data_import_jobs.findUnique({
      where: { id: jobId },
      select: { status: true },
    });
    if (!job) throw new NotFoundException(`No import job ${jobId}`);
    if (job.status !== 'pending_review') {
      throw new BadRequestException(`Job ${jobId} is "${job.status}", not pending_review.`);
    }
    await this.prisma.data_import_jobs.update({
      where: { id: jobId },
      data: {
        status: 'approved',
        reviewed_by: userId ?? null,
        reviewed_at: new Date(),
        review_note: note,
      },
    });
  }

  async reject(jobId: bigint, userId?: bigint, note?: string): Promise<void> {
    await this.prisma.data_import_jobs.update({
      where: { id: jobId },
      data: {
        status: 'rejected',
        reviewed_by: userId ?? null,
        reviewed_at: new Date(),
        review_note: note,
      },
    });
  }

  /**
   * The only writer to cutoff_data.
   *
   * Upserts on the natural key, so re-publishing the same round is idempotent
   * rather than doubling the rows. Every write is mirrored into
   * data_change_logs -- cutoff data is the product, and a silent change to it
   * is the worst failure this system can have.
   */
  async publish(jobId: bigint): Promise<{ inserted: number; updated: number }> {
    const job = await this.prisma.data_import_jobs.findUnique({
      where: { id: jobId },
      select: {
        id: true, status: true, academic_year: true, source_id: true,
        counselling_process_id: true, validation_report: true,
      },
    });
    if (!job) throw new NotFoundException(`No import job ${jobId}`);
    if (job.status !== 'approved') {
      throw new BadRequestException(
        `Job ${jobId} is "${job.status}". Only an approved job can be published.`,
      );
    }
    if (!job.academic_year || !job.counselling_process_id) {
      throw new BadRequestException(`Job ${jobId} is missing year or counselling process.`);
    }

    // Which exam a row belongs to depends on the COLLEGE, not just the process.
    //
    // JoSAA allots IIT seats on the JEE Advanced rank and everything else on
    // the JEE Main rank, which is exactly what counselling_exams
    // .applies_to_college_types records. Taking the process's primary exam for
    // every row ignored that and filed 68,863 IIT cutoffs under JEE Main, so a
    // JEE Main rank of 500 was matched against an Advanced closing rank of 610
    // and called a strong match -- while a real JEE Advanced rank returned
    // nothing at all.
    const override = (job.validation_report as { examCodeOverride?: string } | null)
      ?.examCodeOverride;

    const links = await this.prisma.counselling_exams.findMany({
      where: { counselling_process_id: job.counselling_process_id },
      select: { exam_id: true, is_primary: true, applies_to_college_types: true, exams: { select: { code: true } } },
    });

    // An override names the exam for the whole file (WBJEEB ships one per
    // exam), and beats any per-college routing.
    const overridden = override ? links.find((l) => l.exams.code === override) : undefined;
    if (override && !overridden) {
      throw new BadRequestException(
        `Exam ${override} is not linked to counselling process ${job.counselling_process_id} in counselling_exams.`,
      );
    }

    const fallbackExamId =
      overridden?.exam_id ??
      links.find((l) => l.is_primary)?.exam_id ??
      (links.length === 1 ? links[0].exam_id : undefined);
    if (fallbackExamId === undefined) {
      throw new BadRequestException(
        `Counselling process ${job.counselling_process_id} has no primary exam in counselling_exams.`,
      );
    }

    // college_type -> exam, for the links that name the types they cover.
    const examByCollegeType = new Map<string, number>();
    if (!overridden) {
      for (const l of links) {
        for (const t of l.applies_to_college_types ?? []) {
          examByCollegeType.set(t, l.exam_id);
        }
      }
    }

    // cutoff_data.rank_basis defaults to 'category_rank'. That was harmless
    // while every authority published a category rank, and is wrong the moment
    // one does not, so take it from the process rather than the default.
    const process = await this.prisma.counselling_processes.findUniqueOrThrow({
      where: { id: job.counselling_process_id },
      select: { rank_basis: true },
    });

    await this.prisma.$executeRaw`SELECT app_ensure_cutoff_partition(${job.academic_year}::INT)`;

    const staged = await this.prisma.data_import_staging.findMany({
      where: { import_job_id: jobId, status: 'valid' },
      select: { id: true, normalized: true },
    });

    let inserted = 0;
    let updated = 0;

    // Every college this job touches, so the per-row exam can be resolved
    // without awaiting inside the batched value list below.
    const collegeIds = [
      ...new Set(
        staged.map((r) => (r.normalized as unknown as NormalizedCutoffRow).collegeId),
      ),
    ];
    const collegeType = new Map(
      (
        await this.prisma.colleges.findMany({
          where: { id: { in: collegeIds } },
          select: { id: true, college_type: true },
        })
      ).map((c) => [c.id, c.college_type as string]),
    );
    const examFor = (n: NormalizedCutoffRow): number =>
      examByCollegeType.get(collegeType.get(n.collegeId) ?? '') ?? fallbackExamId;

    // Resolve every round this job touches up front: the insert below is
    // batched, so it cannot await inside the value list.
    const rounds = new Map<number, number>();
    for (const row of staged) {
      const n = row.normalized as unknown as NormalizedCutoffRow;
      if (!rounds.has(n.roundNo)) {
        rounds.set(n.roundNo, await this.roundId(job.counselling_process_id, n.roundNo));
      }
    }

    for (let i = 0; i < staged.length; i += CHUNK) {
      const batch = staged.slice(i, i + CHUNK);

      // ON CONFLICT DO UPDATE cannot touch the same row twice in one
      // statement, so a duplicate natural key inside the batch would abort it.
      // Last one wins, which matches the per-row behaviour this replaces.
      const unique = new Map<string, (typeof batch)[number]>();
      for (const row of batch) {
        const n = row.normalized as unknown as NormalizedCutoffRow;
        unique.set(
          [examFor(n), n.roundNo, n.collegeBranchId, n.seatTypeId, n.quotaId, n.genderId].join('|'),
          row,
        );
      }

      const tuples = [...unique.values()].map((row) => {
        const n = row.normalized as unknown as NormalizedCutoffRow;
        return Prisma.sql`(
          ${job.academic_year}::SMALLINT, ${job.counselling_process_id},
          ${rounds.get(n.roundNo)}, ${n.roundNo}::SMALLINT, ${examFor(n)}::SMALLINT,
          ${n.collegeBranchId}::BIGINT, ${n.collegeId}, ${n.branchId}::SMALLINT,
          ${n.seatTypeId}::SMALLINT, ${n.seatTypeId}::SMALLINT,
          ${n.quotaId}::SMALLINT, ${n.genderId}::SMALLINT,
          ${n.openingRank}, ${n.closingRank},
          ${n.openingPercentile}, ${n.closingPercentile},
          ${n.openingScore}, ${n.closingScore}, ${n.maxScore},
          ${process.rank_basis},
          ${job.source_id}, ${jobId}, ${n.isPreparatory ?? false}
        )`;
      });

      // One statement per CHUNK rows instead of one per row. The per-row
      // version managed about 170 rows/s, which is 75s for a single JoSAA
      // round and over an hour for a full backfill.
      //
      // category_id is a placeholder in the value list: the BEFORE INSERT
      // trigger app_sync_cutoff_category() derives it from seat_type_id, so
      // the two cannot disagree.
      const result = await this.prisma.$queryRaw<Array<{ inserted: boolean }>>(Prisma.sql`
        INSERT INTO cutoff_data (
          academic_year, counselling_process_id, counselling_round_id, round_no, exam_id,
          college_branch_id, college_id, branch_id,
          seat_type_id, category_id, quota_id, gender_id,
          opening_rank, closing_rank, opening_percentile, closing_percentile,
          opening_score, closing_score, max_score, rank_basis,
          source_id, import_job_id, is_preparatory
        ) VALUES ${Prisma.join(tuples)}
        ON CONFLICT (academic_year, counselling_process_id, exam_id, round_no,
                     college_branch_id, seat_type_id, quota_id, gender_id)
        DO UPDATE SET
          opening_rank = EXCLUDED.opening_rank,
          closing_rank = EXCLUDED.closing_rank,
          opening_percentile = EXCLUDED.opening_percentile,
          closing_percentile = EXCLUDED.closing_percentile,
          opening_score = EXCLUDED.opening_score,
          closing_score = EXCLUDED.closing_score,
          max_score = EXCLUDED.max_score,
          rank_basis = EXCLUDED.rank_basis,
          source_id = EXCLUDED.source_id,
          import_job_id = EXCLUDED.import_job_id,
          is_preparatory = EXCLUDED.is_preparatory,
          updated_at = now()
        RETURNING (imported_at = updated_at) AS inserted
      `);

      for (const r of result) r.inserted ? (inserted += 1) : (updated += 1);

      await this.prisma.data_import_staging.updateMany({
        where: { id: { in: batch.map((r) => r.id) } },
        data: { status: 'imported' },
      });
      this.logger.log(`published ${Math.min(i + CHUNK, staged.length)}/${staged.length}`);
    }

    await this.prisma.data_change_logs.create({
      data: {
        table_name: 'cutoff_data',
        row_id: jobId,
        action: 'insert',
        import_job_id: jobId,
        actor_kind: 'importer',
        new_values: { inserted, updated, academic_year: job.academic_year } as unknown as object,
      },
    });

    await this.prisma.data_import_jobs.update({
      where: { id: jobId },
      data: {
        status: 'published',
        published_at: new Date(),
        rows_inserted: inserted,
        rows_updated: updated,
      },
    });

    // The trend view is what the predictor reads; without this the new round is
    // invisible to every student.
    await this.prisma.$executeRaw`SELECT fn_refresh_cutoff_trend(true)`;
    this.logger.log(`job ${jobId} published: ${inserted} inserted, ${updated} updated`);

    return { inserted, updated };
  }

  private roundCache = new Map<string, number>();

  private async roundId(processId: number, roundNo: number): Promise<number> {
    const key = `${processId}|${roundNo}`;
    const hit = this.roundCache.get(key);
    if (hit) return hit;

    const existing = await this.prisma.counselling_rounds.findFirst({
      where: { counselling_process_id: processId, round_no: roundNo, kind: 'regular' },
      select: { id: true },
    });
    const id =
      existing?.id ??
      (await this.prisma.counselling_rounds.create({
        data: {
          counselling_process_id: processId,
          round_no: roundNo,
          name: `Round ${roundNo}`,
          cutoff_published: true,
        },
        select: { id: true },
      })).id;

    this.roundCache.set(key, id);
    return id;
  }

  /**
   * Which state a bootstrapped college belongs to.
   *
   * colleges.state_id decides home-state quota eligibility, so getting this
   * wrong is not cosmetic. A state counselling body only admits to colleges in
   * its own state, and counselling_authorities.state_id already records that,
   * so use it. West Bengal showed why: its OBC-A and OBC-B seats are all
   * home-state, and with the colleges parked on a generic fallback every WB
   * candidate saw zero OBC-A matches.
   *
   * National authorities (JoSAA, CSAB) have no state, and their institutes are
   * spread across the country; those genuinely need correcting by hand, and
   * the resolver warns per college when it creates one.
   */
  private async defaultStateFor(authorityId: number): Promise<number> {
    const authority = await this.prisma.counselling_authorities.findUnique({
      where: { id: authorityId },
      select: { state_id: true },
    });
    if (authority?.state_id) return authority.state_id;

    const fallback = await this.prisma.states.findFirstOrThrow({
      where: { code: 'DL' },
      select: { id: true },
    });
    return fallback.id;
  }
}
