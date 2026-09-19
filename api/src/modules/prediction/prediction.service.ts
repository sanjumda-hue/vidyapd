import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';
import { PredictDto } from './dto/predict.dto';
import { WhatIfDto } from './dto/what-if.dto';
import {
  MatchGrade,
  PredictionMatch,
  PredictionResponse,
  PredictionRow,
} from './prediction.types';

const GRADE_LABEL: Record<MatchGrade, string> = {
  strong_historical_match: 'Strong historical match',
  historical_match: 'Historical match',
  borderline: 'Borderline',
  outside_historical_range: 'Outside historical range',
};

interface ProgramSummaryRow {
  college_branch_id: bigint;
  program_name: string;
  college_id: number;
  college_name: string;
  college_short_name: string | null;
  college_type: string;
  state_name: string;
  branch_id: number;
  branch_code: string;
  branch_name: string;
}

interface LookupRow {
  id: number;
  name: string;
}

const DISCLAIMER =
  'These results are based on published closing ranks from previous years. ' +
  'Cutoffs change every season with seat matrix, exam difficulty and candidate ' +
  'count. This is not a prediction of admission.';

@Injectable()
export class PredictionService {
  private readonly logger = new Logger(PredictionService.name);

  constructor(private readonly prisma: PrismaService) {}

  async predict(dto: PredictDto, userId?: number): Promise<PredictionResponse> {
    const started = Date.now();
    const context = await this.resolveContext(dto);
    const { rank, isEstimated, method } = await this.resolveRank(dto, context);

    const rows = await this.prisma.$queryRaw<PredictionRow[]>`
      SELECT * FROM fn_predict_colleges(
        ${context.examId}::SMALLINT,
        ${rank}::BIGINT,
        ${context.categoryId}::SMALLINT,
        ${dto.gender}::applicant_gender,
        ${dto.isPwd}::BOOLEAN,
        ${context.homeStateId}::SMALLINT,
        ${context.branchIds}::SMALLINT[],
        ${context.stateIds}::SMALLINT[],
        ${context.collegeTypes}::college_type[],
        'default'::TEXT,
        ${dto.limit}::INT
      )
    `;

    const matches = await this.decorate(rows);
    const request = await this.logRequest(dto, context, rank, isEstimated, matches.length, userId);
    await this.persistResults(request.id, rows);

    this.logger.log(
      `prediction exam=${dto.examCode} rank=${rank} results=${matches.length} in ${Date.now() - started}ms`,
    );

    return {
      requestId: request.uuid,
      exam: { code: context.examCode, name: context.examName },
      academicYear: context.academicYear,
      rankUsed: rank,
      rankIsEstimated: isEstimated,
      rankEstimateMethod: method,
      category: dto.categoryCode,
      gender: dto.gender,
      homeState: dto.homeStateCode ?? null,
      counts: this.countByGrade(matches),
      matches,
      disclaimer: DISCLAIMER,
    };
  }

  /**
   * Design doc section 29. Each hypothetical rank is a full prediction run
   * linked back to the original through prediction_requests.what_if_parent_id,
   * so the analytics panel can tell a sweep apart from five real searches.
   */
  async whatIf(dto: WhatIfDto, userId?: number): Promise<{
    baseline: PredictionResponse;
    scenarios: Array<{ rank: number; counts: Record<MatchGrade, number>; topMatches: PredictionMatch[] }>;
  }> {
    const baseline = await this.predict(dto, userId);
    const ranks = dto.ranks?.length ? dto.ranks : this.defaultWhatIfRanks(baseline.rankUsed);

    const scenarios: Array<{
      rank: number;
      counts: Record<MatchGrade, number>;
      topMatches: PredictionMatch[];
    }> = [];
    for (const rank of ranks) {
      const run = await this.predict({ ...dto, rank, percentile: undefined }, userId);
      scenarios.push({
        rank,
        counts: run.counts,
        topMatches: run.matches.slice(0, 10),
      });
    }

    return { baseline, scenarios };
  }

  /** A spread around the real rank: better, same, worse. */
  private defaultWhatIfRanks(rank: number): number[] {
    return [0.6, 0.8, 1.0, 1.25, 1.6]
      .map((f) => Math.max(1, Math.round(rank * f)))
      .filter((v, i, arr) => arr.indexOf(v) === i);
  }

  /** Resolve every human-readable code to the id the SQL function expects. */
  private async resolveContext(dto: PredictDto) {
    const exam = await this.prisma.exams.findUnique({
      where: { code: dto.examCode },
      select: { id: true, code: true, name: true, has_percentile: true },
    });
    if (!exam) throw new NotFoundException(`Unknown exam code: ${dto.examCode}`);

    const category = await this.prisma.categories.findUnique({
      where: { code: dto.categoryCode },
      select: { id: true },
    });
    if (!category) throw new NotFoundException(`Unknown category code: ${dto.categoryCode}`);

    let homeStateId: number | null = null;
    if (dto.homeStateCode) {
      const state = await this.prisma.states.findUnique({
        where: { code: dto.homeStateCode },
        select: { id: true },
      });
      if (!state) throw new NotFoundException(`Unknown state code: ${dto.homeStateCode}`);
      homeStateId = state.id;
    }

    const branchIds = dto.branchCodes?.length
      ? (await this.prisma.branches.findMany({
          where: { code: { in: dto.branchCodes } },
          select: { id: true },
        })).map((b) => b.id)
      : null;

    const stateIds = dto.stateCodes?.length
      ? (await this.prisma.states.findMany({
          where: { code: { in: dto.stateCodes } },
          select: { id: true },
        })).map((s) => s.id)
      : null;

    return {
      examId: exam.id,
      examCode: exam.code,
      examName: exam.name,
      examHasPercentile: exam.has_percentile,
      categoryId: category.id,
      homeStateId,
      branchIds,
      stateIds,
      collegeTypes: dto.collegeTypes?.length ? dto.collegeTypes : null,
      academicYear: dto.academicYear ?? this.currentAdmissionYear(),
    };
  }

  /**
   * A student may give a rank or a percentile. When it is a percentile we call
   * fn_percentile_to_rank and take the midpoint of the returned band -- but we
   * carry `isEstimated` all the way into the response so the UI can label it.
   * If the conversion has no data to work with we fail loudly rather than
   * guessing, because a wrong rank silently poisons every row below it.
   */
  private async resolveRank(
    dto: PredictDto,
    context: { examId: number; academicYear: number; categoryId: number; examHasPercentile: boolean },
  ): Promise<{ rank: number; isEstimated: boolean; method?: string }> {
    if (dto.rank) {
      return { rank: dto.rank, isEstimated: false };
    }

    if (dto.percentile === undefined) {
      throw new BadRequestException('Provide either rank or percentile.');
    }
    if (!context.examHasPercentile) {
      throw new BadRequestException(`${dto.examCode} does not publish percentiles. Enter a rank instead.`);
    }

    const [band] = await this.prisma.$queryRaw<
      Array<{ rank_from: string; rank_to: string; is_official: boolean; method: string }>
    >`
      SELECT * FROM fn_percentile_to_rank(
        ${context.examId}::SMALLINT,
        ${context.academicYear}::SMALLINT,
        ${dto.percentile}::NUMERIC,
        ${context.categoryId}::SMALLINT
      )
    `;

    if (!band) {
      throw new BadRequestException(
        `No percentile-to-rank data available for ${dto.examCode} ${context.academicYear}. Enter your rank instead.`,
      );
    }

    const rank = Math.round((Number(band.rank_from) + Number(band.rank_to)) / 2);
    return { rank, isEstimated: !band.is_official, method: band.method };
  }

  /** Join the SQL result back onto display names in one round trip. */
  private async decorate(rows: PredictionRow[]): Promise<PredictionMatch[]> {
    if (rows.length === 0) return [];

    const programIds = rows.map((r) => BigInt(r.college_branch_id));

    const programs = await this.prisma.$queryRaw<ProgramSummaryRow[]>`
      SELECT college_branch_id, program_name, college_id, college_name,
             college_short_name, college_type::TEXT, state_name,
             branch_id, branch_code, branch_name
      FROM v_program_summary
      WHERE college_branch_id = ANY(${programIds}::BIGINT[])
    `;
    const seatTypes: LookupRow[] = await this.prisma.seat_types.findMany({
      select: { id: true, name: true },
    });
    const quotas: LookupRow[] = await this.prisma.quotas.findMany({
      select: { id: true, name: true },
    });
    const genders: LookupRow[] = await this.prisma.genders.findMany({
      select: { id: true, name: true },
    });

    const programById = new Map(programs.map((p) => [String(p.college_branch_id), p] as const));
    const seatTypeById = new Map(seatTypes.map((s) => [s.id, s.name] as const));
    const quotaById = new Map(quotas.map((q) => [q.id, q.name] as const));
    const genderById = new Map(genders.map((g) => [g.id, g.name] as const));

    return rows.flatMap((row) => {
      const program = programById.get(String(row.college_branch_id));
      if (!program) return [];

      return [{
        collegeBranchId: Number(row.college_branch_id),
        college: {
          id: program.college_id,
          name: program.college_name,
          shortName: program.college_short_name,
          type: program.college_type,
          state: program.state_name,
        },
        branch: { id: program.branch_id, code: program.branch_code, name: program.branch_name },
        programName: program.program_name,
        seatType: seatTypeById.get(row.seat_type_id) ?? String(row.seat_type_id),
        quota: quotaById.get(row.quota_id) ?? String(row.quota_id),
        genderPool: genderById.get(row.gender_id) ?? String(row.gender_id),
        grade: row.grade,
        gradeLabel: GRADE_LABEL[row.grade],
        score: Number(row.score),
        weightedClosingRank: row.weighted_closing_rank ? Number(row.weighted_closing_rank) : null,
        bestClosingRank: row.best_closing_rank ? Number(row.best_closing_rank) : null,
        worstClosingRank: row.worst_closing_rank ? Number(row.worst_closing_rank) : null,
        latestClosingRank: row.latest_closing_rank ? Number(row.latest_closing_rank) : null,
        rankMargin: row.rank_margin ? Number(row.rank_margin) : null,
        yearsAvailable: row.years_available,
        trend: this.describeTrend(row.trend_slope),
        cutoffHistory: Object.entries(row.cutoff_history ?? {})
          .map(([year, v]) => ({ year: Number(year), ...v }))
          .sort((a, b) => b.year - a.year),
      }];
    });
  }

  /** Negative slope means the closing rank is falling year on year: harder to get in. */
  private describeTrend(slope: string | null): PredictionMatch['trend'] {
    if (slope === null) return 'unknown';
    const value = Number(slope);
    if (value < -500) return 'tightening';
    if (value > 500) return 'loosening';
    return 'stable';
  }

  private countByGrade(matches: PredictionMatch[]): Record<MatchGrade, number> {
    const counts: Record<MatchGrade, number> = {
      strong_historical_match: 0,
      historical_match: 0,
      borderline: 0,
      outside_historical_range: 0,
    };
    for (const m of matches) counts[m.grade] += 1;
    return counts;
  }

  /** Counselling season rolls over mid-year; before June we are still on last year's cycle. */
  private currentAdmissionYear(): number {
    const now = new Date();
    return now.getMonth() >= 5 ? now.getFullYear() : now.getFullYear() - 1;
  }

  private async logRequest(
    dto: PredictDto,
    context: { examId: number; academicYear: number; categoryId: number; homeStateId: number | null;
               branchIds: number[] | null; stateIds: number[] | null; collegeTypes: string[] | null },
    rank: number,
    isEstimated: boolean,
    resultCount: number,
    userId?: number,
  ): Promise<{ id: bigint; uuid: string }> {
    const [row] = await this.prisma.$queryRaw<Array<{ id: bigint; uuid: string }>>`
      INSERT INTO prediction_requests (
        user_id, exam_id, academic_year, input_kind, input_rank, input_percentile,
        resolved_rank, resolved_rank_is_estimated, category_id, applicant_gender,
        is_pwd, home_state_id, filter_branch_ids, filter_state_ids, filter_college_types,
        result_count
      ) VALUES (
        ${userId ?? null}, ${context.examId}::SMALLINT, ${context.academicYear}::SMALLINT,
        ${dto.rank ? 'rank' : 'percentile'}::prediction_input_kind,
        ${dto.rank ?? null}, ${dto.percentile ?? null},
        ${rank}::BIGINT, ${isEstimated}, ${context.categoryId}::SMALLINT,
        ${dto.gender}::applicant_gender, ${dto.isPwd}, ${context.homeStateId}::SMALLINT,
        ${context.branchIds}::SMALLINT[], ${context.stateIds}::SMALLINT[],
        ${context.collegeTypes}::college_type[], ${resultCount}
      )
      RETURNING id, uuid
    `;
    return row;
  }

  /**
   * Snapshot the result set. The trend view is refreshed whenever a new round
   * is published, so without this a student reopening a saved prediction would
   * silently see different numbers than the ones they screenshotted.
   */
  private async persistResults(requestId: bigint, rows: PredictionRow[]): Promise<void> {
    if (rows.length === 0) return;

    await this.prisma.prediction_results.createMany({
      data: rows.map((row, index) => ({
        prediction_request_id: requestId,
        college_branch_id: BigInt(row.college_branch_id),
        college_id: row.college_id,
        branch_id: row.branch_id,
        counselling_authority_id: row.counselling_authority_id,
        seat_type_id: row.seat_type_id,
        quota_id: row.quota_id,
        gender_id: row.gender_id,
        grade: row.grade,
        score: row.score,
        weighted_closing_rank: row.weighted_closing_rank ? BigInt(row.weighted_closing_rank) : null,
        best_closing_rank: row.best_closing_rank ? BigInt(row.best_closing_rank) : null,
        worst_closing_rank: row.worst_closing_rank ? BigInt(row.worst_closing_rank) : null,
        latest_closing_rank: row.latest_closing_rank ? BigInt(row.latest_closing_rank) : null,
        rank_margin: row.rank_margin ? BigInt(row.rank_margin) : null,
        years_available: row.years_available,
        trend_slope: row.trend_slope,
        cutoff_history: row.cutoff_history,
        display_rank: index + 1,
      })),
      skipDuplicates: true,
    });
  }

  /** Replay a stored prediction. Reads the snapshot, never re-runs the engine. */
  async findSavedResult(requestUuid: string): Promise<PredictionResponse> {
    const request = await this.prisma.prediction_requests.findUnique({
      where: { uuid: requestUuid },
    });
    if (!request) throw new NotFoundException(`No prediction found for ${requestUuid}`);

    const stored = await this.prisma.$queryRaw<PredictionRow[]>`
      SELECT r.college_branch_id, r.college_id, r.branch_id,
             r.counselling_authority_id,
             r.seat_type_id, r.quota_id, r.gender_id,
             r.grade, r.score::TEXT AS score,
             r.weighted_closing_rank, r.best_closing_rank, r.worst_closing_rank,
             r.latest_closing_rank, r.rank_margin, r.years_available,
             r.trend_slope::TEXT AS trend_slope, r.cutoff_history
      FROM prediction_results r
      WHERE r.prediction_request_id = ${request.id}
      ORDER BY r.display_rank NULLS LAST
    `;

    const exam = await this.prisma.exams.findUniqueOrThrow({
      where: { id: request.exam_id },
      select: { code: true, name: true },
    });
    const matches = await this.decorate(stored);

    return {
      requestId: request.uuid,
      exam,
      academicYear: request.academic_year,
      rankUsed: Number(request.resolved_rank),
      rankIsEstimated: request.resolved_rank_is_estimated,
      category: String(request.category_id),
      gender: String(request.applicant_gender),
      homeState: request.home_state_id ? String(request.home_state_id) : null,
      counts: this.countByGrade(matches),
      matches,
      disclaimer: DISCLAIMER,
    };
  }
}
