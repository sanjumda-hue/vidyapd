import { Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Exam master, sessions and per-exam schedule. */
@Injectable()
export class ExamsService {
  constructor(protected readonly prisma: PrismaService) {}

  findAll(level?: string, stateCode?: string) {
    return this.prisma.exams.findMany({
      where: {
        is_active: true,
        ...(level ? { level: level as never } : {}),
        ...(stateCode ? { states: { code: stateCode } } : {}),
      },
      orderBy: [{ display_order: 'asc' }, { name: 'asc' }],
      select: {
        code: true,
        name: true,
        short_name: true,
        level: true,
        conducting_authority: true,
        official_website: true,
        has_percentile: true,
        is_multi_session: true,
        logo_url: true,
        states: { select: { code: true, name: true } },
      },
    });
  }

  async findOne(code: string) {
    const exam = await this.prisma.exams.findUnique({
      where: { code },
      select: {
        code: true,
        name: true,
        short_name: true,
        level: true,
        conducting_authority: true,
        official_website: true,
        eligibility_summary: true,
        description: true,
        has_rank: true,
        has_percentile: true,
        is_multi_session: true,
        states: { select: { code: true, name: true } },
      },
    });
    if (!exam) throw new NotFoundException(`Unknown exam code: ${code}`);
    return exam;
  }

  /**
   * Schedule for one exam. Returns an empty array until an import runs -- dates
   * are never seeded, so an empty list here means "not published yet", not "bug".
   */
  findSchedule(code: string, year?: number) {
    return this.prisma.exam_schedules.findMany({
      where: {
        exams: { code },
        ...(year ? { academic_year: year } : {}),
      },
      orderBy: [{ start_date: 'asc' }],
      select: {
        event_type: true,
        event_name: true,
        start_date: true,
        end_date: true,
        is_tentative: true,
        detail_url: true,
        notes: true,
        academic_year: true,
      },
    });
  }
}
