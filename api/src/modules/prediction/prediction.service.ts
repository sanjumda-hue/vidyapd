import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';

import { currentAdmissionYear } from '../../common/admission-year';
import { PrismaService } from '../../database/prisma.service';
import { PredictDto } from './dto/predict.dto';
import { WhatIfDto } from './dto/what-if.dto';
import {
  AnyPredictionRow,
  MatchGrade,
  PredictionMatch,
  PredictionMeasure,
  PredictionResponse,
  PredictionRow,
  PredictionScoreRow,
  WhatIfScenario,
  isScoreRow,
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

interface PredictionContext {
  examId: number;
  examCode: string;
  examName: string;
  examHasPercentile: boolean;
  /** True when the authority allots on marks rather than a rank. */
  isScoreBased: boolean;
  categoryId: number;
  homeStateId: number | null;
  branchIds: number[] | null;
  stateIds: number[] | null;
  collegeTypes: string[] | null;
  academicYear: number;
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
    const context = await this.resolveContext(dto);
    return context.isScoreBased
      ? this.predictByScore(dto, context, userId)
      : this.predictByRank(dto, context, userId);
  }

  private async predictByRank(
    dto: PredictDto,
    context: PredictionContext,
    userId?: number,
  ): Promise<PredictionResponse> {
    const started = Date.now();
    const { rank, isEstimated, method } = await this.resolveRank(dto, context);

    const rows = await this.prisma.$queryRaw<PredictionRow[]>`
      SELECT * FROM fn_predict_colleges_banded(
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
        ${dto.limit}::INT,
        false
      )
    `;

    const matches = await this.decorate(rows, 'rank');
    const request = await this.logRequest(dto, context, {
      kind: dto.rank ? 'rank' : 'percentile',
      rank,
      isEstimated,
      score: null,
      maxScore: null,
      resultCount: matches.length,
      userId,
    });
    await this.persistResults(request.id, rows);

    this.logger.log(
      `prediction exam=${dto.examCode} rank=${rank} results=${matches.length} in ${Date.now() - started}ms`,
    );

    return {
      requestId: request.uuid,
      exam: { code: context.examCode, name: context.examName },
      academicYear: context.academicYear,
      measure: 'rank',
      rankUsed: rank,
      rankIsEstimated: isEstimated,
      rankEstimateMethod: method,
      scoreUsed: null,
      maxScoreUsed: null,
      category: dto.categoryCode,
      gender: dto.gender,
      homeState: dto.homeStateCode ?? null,
      counts: this.countByGrade(rows),
      matches,
      disclaimer: DISCLAIMER,
    };
  }

  /**
   * Marks-based exams (BITSAT) go through fn_predict_colleges_by_score.
   *
   * The two engines are deliberately separate rather than one function with a
   * flag: ranks and scores run in opposite directions, so every comparison,
   * every ordering and the reach cut-off invert. Sharing one body would mean a
   * sign test on each of them.
   */
  private async predictByScore(
    dto: PredictDto,
    context: PredictionContext,
    userId?: number,
  ): Promise<PredictionResponse> {
    const started = Date.now();
    if (dto.score === undefined) {
      throw new BadRequestException(
        `${dto.examCode} is scored on marks, not a rank. Send your score instead.`,
      );
    }
    const maxScore = await this.resolveMaxScore(dto, context);
    if (dto.score > maxScore) {
      throw new BadRequestException(`A score of ${dto.score} is above the paper total of ${maxScore}.`);
    }

    const rows = await this.prisma.$queryRaw<PredictionScoreRow[]>`
      SELECT * FROM fn_predict_colleges_by_score_banded(
        ${context.examId}::SMALLINT,
        ${dto.score}::NUMERIC,
        ${maxScore}::NUMERIC,
        ${context.categoryId}::SMALLINT,
        ${dto.gender}::applicant_gender,
        ${dto.isPwd}::BOOLEAN,
        ${context.homeStateId}::SMALLINT,
        ${context.branchIds}::SMALLINT[],
        ${context.stateIds}::SMALLINT[],
        ${context.collegeTypes}::college_type[],
        'default'::TEXT,
        ${dto.limit}::INT,
        false
      )
    `;

    const matches = await this.decorate(rows, 'score');
    const request = await this.logRequest(dto, context, {
      kind: 'marks',
      rank: null,
      isEstimated: false,
      score: dto.score,
      maxScore,
      resultCount: matches.length,
      userId,
    });
    await this.persistResults(request.id, rows);

    this.logger.log(
      `prediction exam=${dto.examCode} score=${dto.score}/${maxScore} ` +
        `results=${matches.length} in ${Date.now() - started}ms`,
    );

    return {
      requestId: request.uuid,
      exam: { code: context.examCode, name: context.examName },
      academicYear: context.academicYear,
      measure: 'score',
      rankUsed: null,
      rankIsEstimated: false,
      scoreUsed: dto.score,
      maxScoreUsed: maxScore,
      category: dto.categoryCode,
      gender: dto.gender,
      homeState: dto.homeStateCode ?? null,
      counts: this.countByGrade(rows),
      matches,
      disclaimer: DISCLAIMER,
    };
  }

  /**
   * The paper total. Taken from the candidate when they give one -- a 2019
   * BITSAT score is out of 450, not today's 390 -- and otherwise from the most
   * recent total published for the exam.
   */
  private async resolveMaxScore(dto: PredictDto, context: PredictionContext): Promise<number> {
    if (dto.maxScore !== undefined) return dto.maxScore;

    const [row] = await this.prisma.$queryRaw<Array<{ max_score: string }>>`
      SELECT c.max_score::TEXT AS max_score
      FROM cutoff_data c
      WHERE c.exam_id = ${context.examId}::SMALLINT
        AND c.max_score IS NOT NULL
      ORDER BY c.academic_year DESC
      LIMIT 1
    `;
    if (!row) {
      throw new BadRequestException(
        `No paper total on record for ${dto.examCode}. Send maxScore with your score.`,
      );
    }
    return Number(row.max_score);
  }

  /**
   * Design doc section 29. Each hypothetical rank is a full prediction run
   * linked back to the original through prediction_requests.what_if_parent_id,
   * so the analytics panel can tell a sweep apart from five real searches.
   */
  async whatIf(dto: WhatIfDto, userId?: number): Promise<{
    baseline: PredictionResponse;
    scenarios: WhatIfScenario[];
  }> {
    const baseline = await this.predict(dto, userId);
    const scenarios: WhatIfScenario[] = [];

    if (baseline.measure === 'score') {
      const max = baseline.maxScoreUsed as number;
      const scores = dto.scores?.length
        ? dto.scores.filter((v) => v > 0 && v <= max)
        : this.defaultWhatIfScores(baseline.scoreUsed as number, max);

      for (const score of scores) {
        const run = await this.predict(
          { ...dto, score, maxScore: max, rank: undefined, percentile: undefined },
          userId,
        );
        scenarios.push({
          rank: null,
          score,
          counts: run.counts,
          topMatches: run.matches.slice(0, 10),
        });
      }
      return { baseline, scenarios };
    }

    const ranks = dto.ranks?.length
      ? dto.ranks
      : this.defaultWhatIfRanks(baseline.rankUsed as number);

    for (const rank of ranks) {
      const run = await this.predict({ ...dto, rank, percentile: undefined }, userId);
      scenarios.push({
        rank,
        score: null,
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

  /**
   * The same spread in score space, but much tighter and clamped to the paper
   * total. The rank sweep runs from 0.6x to 1.6x because ranks range over
   * orders of magnitude; the same factors on a score would ask what happens at
   * 480/390, which is not a question.
   */
  private defaultWhatIfScores(score: number, maxScore: number): number[] {
    return [0.85, 0.95, 1.0, 1.05, 1.15]
      .map((f) => Math.min(maxScore, Math.max(1, Math.round(score * f))))
      .filter((v, i, arr) => arr.indexOf(v) === i);
  }

  /** Resolve every human-readable code to the id the SQL function expects. */
  private async resolveContext(dto: PredictDto): Promise<PredictionContext> {
    const exam = await this.prisma.exams.findUnique({
      where: { code: dto.examCode },
      select: {
        id: true,
        code: true,
        name: true,
        has_percentile: true,
        primary_score_type: true,
      },
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
      // 'marks' is what BITSAT carries. 'composite' is reserved for exams that
      // blend a test with board marks; none is loaded yet, and routing one to
      // the score engine on a guess would be worse than refusing it.
      isScoreBased: exam.primary_score_type === 'marks',
      categoryId: category.id,
      homeStateId,
      branchIds,
      stateIds,
      collegeTypes: dto.collegeTypes?.length ? dto.collegeTypes : null,
      academicYear: dto.academicYear ?? currentAdmissionYear(),
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
    context: PredictionContext,
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
  private async decorate(
    rows: AnyPredictionRow[],
    measure: PredictionMeasure,
  ): Promise<PredictionMatch[]> {
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
        // A row carries one measure or the other, never both, and the side it
        // does not carry stays null rather than being filled with a stand-in.
        weightedClosingRank: isScoreRow(row) ? null : this.num(row.weighted_closing_rank),
        bestClosingRank: isScoreRow(row) ? null : this.num(row.best_closing_rank),
        worstClosingRank: isScoreRow(row) ? null : this.num(row.worst_closing_rank),
        latestClosingRank: isScoreRow(row) ? null : this.num(row.latest_closing_rank),
        rankMargin: isScoreRow(row) ? null : this.num(row.rank_margin),
        scoreBand: isScoreRow(row)
          ? {
              weightedClosing: this.num(row.weighted_closing_score),
              toughestClosing: this.num(row.toughest_closing_score),
              easiestClosing: this.num(row.easiest_closing_score),
              latestClosing: this.num(row.latest_closing_score),
              maxScore: this.num(row.max_score),
              margin: this.num(row.score_margin),
            }
          : null,
        yearsAvailable: row.years_available,
        trend: this.describeTrend(row.trend_slope, measure),
        cutoffHistory: Object.entries(row.cutoff_history ?? {})
          .map(([year, v]) => ({ year: Number(year), ...v }))
          .sort((a, b) => b.year - a.year),
      }];
    });
  }

  /**
   * Which way a cut-off is moving.
   *
   * The sign AND the scale differ by measure. A rank slope is places per year
   * and NEGATIVE means tightening, with 500 places a year the point at which it
   * is worth mentioning. A score slope is percentage points of the paper per
   * year and POSITIVE means tightening; the whole observed range is about
   * +/-3, so the same threshold would call every programme stable.
   */
  private describeTrend(slope: string | null, measure: PredictionMeasure): PredictionMatch['trend'] {
    if (slope === null) return 'unknown';
    const value = Number(slope);
    const threshold = measure === 'score' ? 0.5 : 500;
    const tightening = measure === 'score' ? value > threshold : value < -threshold;
    const loosening = measure === 'score' ? value < -threshold : value > threshold;
    if (tightening) return 'tightening';
    if (loosening) return 'loosening';
    return 'stable';
  }

  /** Postgres hands NUMERIC and BIGINT back as strings; 0 is a real value. */
  private num(v: string | null | undefined): number | null {
    return v === null || v === undefined ? null : Number(v);
  }

  /**
   * The size of each band in the FULL result, not in the slice returned.
   *
   * The engine hands back a share of each band, so counting rows here would
   * have told a candidate with 811 strong matches that they had 34.
   */
  private countByGrade(rows: AnyPredictionRow[]): Record<MatchGrade, number> {
    const counts: Record<MatchGrade, number> = {
      strong_historical_match: 0,
      historical_match: 0,
      borderline: 0,
      outside_historical_range: 0,
    };
    for (const r of rows) counts[r.grade] = Number(r.band_total);
    return counts;
  }

  private async logRequest(
    dto: PredictDto,
    context: PredictionContext,
    run: {
      kind: 'rank' | 'percentile' | 'marks';
      rank: number | null;
      isEstimated: boolean;
      score: number | null;
      maxScore: number | null;
      resultCount: number;
      userId?: number;
    },
  ): Promise<{ id: bigint; uuid: string }> {
    const [row] = await this.prisma.$queryRaw<Array<{ id: bigint; uuid: string }>>`
      INSERT INTO prediction_requests (
        user_id, exam_id, academic_year, input_kind, input_rank, input_percentile,
        input_marks, resolved_rank, resolved_rank_is_estimated, resolved_max_score,
        category_id, applicant_gender,
        is_pwd, home_state_id, filter_branch_ids, filter_state_ids, filter_college_types,
        result_count
      ) VALUES (
        ${run.userId ?? null}, ${context.examId}::SMALLINT, ${context.academicYear}::SMALLINT,
        ${run.kind}::prediction_input_kind,
        ${dto.rank ?? null}, ${dto.percentile ?? null}, ${run.score},
        ${run.rank}::BIGINT, ${run.isEstimated}, ${run.maxScore},
        ${context.categoryId}::SMALLINT,
        ${dto.gender}::applicant_gender, ${dto.isPwd}, ${context.homeStateId}::SMALLINT,
        ${context.branchIds}::SMALLINT[], ${context.stateIds}::SMALLINT[],
        ${context.collegeTypes}::college_type[], ${run.resultCount}
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
  private async persistResults(requestId: bigint, rows: AnyPredictionRow[]): Promise<void> {
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
        years_available: row.years_available,
        trend_slope: row.trend_slope,
        cutoff_history: row.cutoff_history,
        display_rank: index + 1,
        ...(isScoreRow(row)
          ? {
              weighted_closing_score: row.weighted_closing_score,
              toughest_closing_score: row.toughest_closing_score,
              easiest_closing_score: row.easiest_closing_score,
              latest_closing_score: row.latest_closing_score,
              max_score: row.max_score,
              score_margin: row.score_margin,
            }
          : {
              weighted_closing_rank: this.big(row.weighted_closing_rank),
              best_closing_rank: this.big(row.best_closing_rank),
              worst_closing_rank: this.big(row.worst_closing_rank),
              latest_closing_rank: this.big(row.latest_closing_rank),
              rank_margin: this.big(row.rank_margin),
            }),
      })),
      skipDuplicates: true,
    });
  }

  /** rank_margin is signed and can legitimately be 0, so no truthiness test. */
  private big(v: string | null): bigint | null {
    return v === null ? null : BigInt(v);
  }

  /** Replay a stored prediction. Reads the snapshot, never re-runs the engine. */
  async findSavedResult(requestUuid: string): Promise<PredictionResponse> {
    const request = await this.prisma.prediction_requests.findUnique({
      where: { uuid: requestUuid },
    });
    if (!request) throw new NotFoundException(`No prediction found for ${requestUuid}`);

    // input_kind is what the request was logged as, so the snapshot is read
    // back through the same measure it was written with -- not through
    // whatever the exam happens to be configured as today.
    const measure: PredictionMeasure = request.input_kind === 'marks' ? 'score' : 'rank';

    const stored =
      measure === 'score'
        ? await this.prisma.$queryRaw<PredictionScoreRow[]>`
            SELECT r.college_branch_id, r.college_id, r.branch_id,
                   r.counselling_authority_id,
                   r.seat_type_id, r.quota_id, r.gender_id,
                   r.grade, r.score::TEXT AS score,
                   r.weighted_closing_score::TEXT AS weighted_closing_score,
                   r.toughest_closing_score::TEXT AS toughest_closing_score,
                   r.easiest_closing_score::TEXT  AS easiest_closing_score,
                   r.latest_closing_score::TEXT   AS latest_closing_score,
                   r.max_score::TEXT              AS max_score,
                   r.score_margin::TEXT           AS score_margin,
                   r.years_available,
                   r.trend_slope::TEXT AS trend_slope, r.cutoff_history
            FROM prediction_results r
            WHERE r.prediction_request_id = ${request.id}
            ORDER BY r.display_rank NULLS LAST
          `
        : await this.prisma.$queryRaw<PredictionRow[]>`
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
    const matches = await this.decorate(stored, measure);

    return {
      requestId: request.uuid,
      exam,
      academicYear: request.academic_year,
      measure,
      rankUsed: request.resolved_rank === null ? null : Number(request.resolved_rank),
      rankIsEstimated: request.resolved_rank_is_estimated,
      scoreUsed: request.input_marks === null ? null : Number(request.input_marks),
      maxScoreUsed: request.resolved_max_score === null ? null : Number(request.resolved_max_score),
      category: String(request.category_id),
      gender: String(request.applicant_gender),
      homeState: request.home_state_id ? String(request.home_state_id) : null,
      // Counted from the snapshot, not from band_total: prediction_results
      // stores the rows that were shown and nothing about the ones that were
      // not, so this is the honest figure for a replay.
      counts: this.countStored(matches),
      matches,
      disclaimer: DISCLAIMER,
    };
  }

  private countStored(matches: PredictionMatch[]): Record<MatchGrade, number> {
    const counts: Record<MatchGrade, number> = {
      strong_historical_match: 0,
      historical_match: 0,
      borderline: 0,
      outside_historical_range: 0,
    };
    for (const m of matches) counts[m.grade] += 1;
    return counts;
  }
}
