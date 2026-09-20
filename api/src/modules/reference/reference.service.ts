import { Injectable } from '@nestjs/common';

import { currentAdmissionYear } from '../../common/admission-year';
import { PrismaService } from '../../database/prisma.service';

export interface LookupItem {
  code: string;
  name: string;
}

export interface BootstrapPayload {
  exams: Array<
    LookupItem & {
      level: string;
      hasPercentile: boolean;
      /**
       * True when a percentile entered for THIS season could actually be
       * converted. `hasPercentile` only says the exam reports one.
       */
      hasPercentileData: boolean;
      /** True when the authority allots on marks, so the form must ask for a score. */
      usesMarks: boolean;
      /** Paper total for a marks-based exam, from the most recent year on record. */
      maxScore: number | null;
      homeStateCode: string | null;
      /** False when no cutoff has been imported for this exam yet. */
      hasCutoffData: boolean;
    }
  >;
  categories: LookupItem[];
  genders: LookupItem[];
  quotas: LookupItem[];
  states: LookupItem[];
  branches: Array<LookupItem & { isPopular: boolean }>;
  collegeTypes: string[];
  /**
   * True when db/seeds-dev invented colleges are loaded, so the app can warn
   * that the numbers on screen are made up.
   */
  hasDemoData: boolean;
}

/**
 * Everything the prediction form needs to render, in one request.
 *
 * The alternative -- six separate lookup calls on app start -- makes the first
 * screen depend on six round trips. These lists change a few times a year, so
 * the client can cache the whole payload.
 */
@Injectable()
export class ReferenceService {
  constructor(private readonly prisma: PrismaService) {}

  async bootstrap(): Promise<BootstrapPayload> {
    // Which exams the predictor can actually answer for. Read from the trend
    // view, not cutoff_data: that view IS what fn_predict_colleges queries, so
    // it is the honest answer to "will this exam return anything?" -- and it is
    // three orders of magnitude smaller than the partitioned base table.
    //
    // Both views, because there are two engines: a marks-based exam has no rows
    // in the rank view at all, and reading only that one marked BITSAT "no data
    // yet" with 402 cut-offs loaded.
    const examsWithData = await this.prisma.$queryRaw<Array<{ exam_id: number }>>`
      SELECT DISTINCT exam_id FROM mv_program_cutoff_trend
      UNION
      SELECT DISTINCT exam_id FROM mv_program_score_trend
    `;
    const withData = new Set(examsWithData.map((r) => r.exam_id));

    // The paper total a score would be marked out of. BITSAT moved from 450 to
    // 390 in 2022, so this is the latest year's, not a constant.
    const totals = await this.prisma.$queryRaw<Array<{ exam_id: number; max_score: string }>>`
      SELECT DISTINCT ON (exam_id) exam_id, max_score::TEXT AS max_score
      FROM cutoff_data
      WHERE max_score IS NOT NULL
      ORDER BY exam_id, academic_year DESC
    `;
    const maxScoreByExam = new Map(totals.map((r) => [r.exam_id, Number(r.max_score)] as const));

    // Which exams a PERCENTILE can be converted for this season.
    //
    // has_percentile alone says only that the exam reports a percentile, and
    // the form was offering the toggle on that basis while
    // fn_percentile_to_rank had nothing to work with -- so picking Percentile
    // on JEE Main and hitting Predict always returned a 400. A button that
    // cannot succeed should not be shown.
    //
    // The two branches below are exactly what the function tries, in the same
    // order, so the flag cannot claim more than the engine can deliver. It is
    // computed for the default season; a request that overrides academicYear to
    // a year with no data still gets the function's honest refusal.
    const admissionYear = currentAdmissionYear();
    const convertible = await this.prisma.$queryRaw<Array<{ exam_id: number }>>`
      SELECT DISTINCT exam_id
      FROM percentile_rank_mapping
      WHERE academic_year = ${admissionYear}
      UNION
      SELECT DISTINCT exam_id
      FROM exam_rank_data
      WHERE academic_year = ${admissionYear}
        AND category_id IS NULL
        AND appeared_candidates IS NOT NULL
    `;
    const canConvert = new Set(convertible.map((r) => r.exam_id));

    // Whether the invented seed-dev colleges are actually present.
    //
    // The app used to show a red "Development build ... (DEMO)" banner on the
    // predict screen unconditionally. Once real cut-offs replaced the demo
    // seeds it was warning about colleges that no longer existed, on every page
    // load -- and a warning that is always on is one people learn to ignore,
    // including on the day it is true. Their slugs are all prefixed demo-.
    const [demo] = await this.prisma.$queryRaw<Array<{ present: boolean }>>`
      SELECT EXISTS (SELECT 1 FROM colleges WHERE slug LIKE 'demo-%') AS present
    `;

    const [exams, categories, genders, quotas, states, branches] = await Promise.all([
      this.prisma.exams.findMany({
        where: { is_active: true },
        orderBy: [{ display_order: 'asc' }, { name: 'asc' }],
        select: {
          id: true,
          code: true,
          name: true,
          short_name: true,
          level: true,
          has_percentile: true,
          primary_score_type: true,
          states: { select: { code: true } },
        },
      }),
      this.prisma.categories.findMany({
        orderBy: { display_order: 'asc' },
        select: { code: true, name: true },
      }),
      this.prisma.genders.findMany({
        orderBy: { display_order: 'asc' },
        select: { code: true, name: true },
      }),
      this.prisma.quotas.findMany({
        orderBy: { display_order: 'asc' },
        select: { code: true, name: true },
      }),
      this.prisma.states.findMany({
        orderBy: { name: 'asc' },
        select: { code: true, name: true },
      }),
      this.prisma.branches.findMany({
        where: { is_active: true },
        orderBy: [{ display_order: 'asc' }, { name: 'asc' }],
        select: { code: true, name: true, is_popular: true },
      }),
    ]);

    return {
      exams: exams.map((e) => ({
        code: e.code,
        name: e.short_name ?? e.name,
        level: e.level,
        hasPercentile: e.has_percentile,
        hasPercentileData: e.has_percentile && canConvert.has(e.id),
        usesMarks: e.primary_score_type === 'marks',
        maxScore: maxScoreByExam.get(e.id) ?? null,
        homeStateCode: e.states?.code ?? null,
        hasCutoffData: withData.has(e.id),
      })),
      categories,
      genders,
      quotas,
      states,
      branches: branches.map((b) => ({ code: b.code, name: b.name, isPopular: b.is_popular })),
      collegeTypes: ['IIT', 'NIT', 'IIIT', 'GFTI', 'STATE_GOVT', 'GOVT_AIDED', 'PRIVATE', 'DEEMED'],
      hasDemoData: demo?.present ?? false,
    };
  }
}
