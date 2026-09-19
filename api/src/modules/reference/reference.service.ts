import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

export interface LookupItem {
  code: string;
  name: string;
}

export interface BootstrapPayload {
  exams: Array<LookupItem & { level: string; hasPercentile: boolean; homeStateCode: string | null }>;
  categories: LookupItem[];
  genders: LookupItem[];
  quotas: LookupItem[];
  states: LookupItem[];
  branches: Array<LookupItem & { isPopular: boolean }>;
  collegeTypes: string[];
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
    const [exams, categories, genders, quotas, states, branches] = await Promise.all([
      this.prisma.exams.findMany({
        where: { is_active: true },
        orderBy: [{ display_order: 'asc' }, { name: 'asc' }],
        select: {
          code: true,
          name: true,
          short_name: true,
          level: true,
          has_percentile: true,
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
        homeStateCode: e.states?.code ?? null,
      })),
      categories,
      genders,
      quotas,
      states,
      branches: branches.map((b) => ({ code: b.code, name: b.name, isPopular: b.is_popular })),
      collegeTypes: ['IIT', 'NIT', 'IIIT', 'GFTI', 'STATE_GOVT', 'GOVT_AIDED', 'PRIVATE', 'DEEMED'],
    };
  }
}
