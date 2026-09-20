import { Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** A student's saved list of programmes. */
@Injectable()
export class ShortlistService {
  constructor(protected readonly prisma: PrismaService) {}

  /**
   * The saved list, with enough detail to render without a second call and
   * with each programme's latest open-seat closing rank for context.
   */
  list(userId: bigint) {
    return this.prisma.$queryRaw<Array<{
      id: bigint; college_branch_id: bigint; preference_order: number | null;
      note: string | null; college_slug: string; college_name: string;
      college_short_name: string | null; state_name: string;
      branch_code: string; program_name: string;
      measure: string | null; latest_closing: string | null;
      latest_max_score: string | null; latest_year: number | null;
    }>>`
      SELECT sl.id, sl.college_branch_id, sl.preference_order, sl.note,
             v.college_slug, v.college_name, v.college_short_name, v.state_name,
             v.branch_code, v.program_name,
             -- Through the unified view: a saved BITS programme showed no
             -- cut-off at all while it read the rank trend view alone.
             t.measure, t.latest_closing::TEXT, t.latest_max_score::TEXT,
             t.latest_year
      FROM user_shortlists sl
      JOIN v_program_summary v ON v.college_branch_id = sl.college_branch_id
      LEFT JOIN LATERAL (
        SELECT mt.measure, mt.latest_closing, mt.latest_max_score, mt.latest_year
        FROM v_program_latest_cutoff mt
        JOIN seat_types st ON st.id = mt.seat_type_id AND st.code = 'OPEN'
        JOIN genders g     ON g.id  = mt.gender_id    AND g.code = 'GENDER_NEUTRAL'
        WHERE mt.college_branch_id = sl.college_branch_id
        ORDER BY mt.latest_year DESC
        LIMIT 1
      ) t ON true
      WHERE sl.user_id = ${userId}
      ORDER BY sl.preference_order NULLS LAST, sl.created_at
    `;
  }

  async add(userId: bigint, collegeBranchId: bigint, note?: string) {
    const exists = await this.prisma.college_branches.findUnique({
      where: { id: collegeBranchId },
      select: { id: true },
    });
    if (!exists) throw new NotFoundException(`No programme with id ${collegeBranchId}`);

    // Adding something already saved is a no-op, not an error: the app fires
    // this from a toggle and a double tap should not surface a failure.
    return this.prisma.user_shortlists.upsert({
      where: {
        user_id_college_branch_id: { user_id: userId, college_branch_id: collegeBranchId },
      },
      create: { user_id: userId, college_branch_id: collegeBranchId, note },
      update: { note },
      select: { id: true, college_branch_id: true, preference_order: true, note: true },
    });
  }

  async remove(userId: bigint, collegeBranchId: bigint): Promise<{ removed: number }> {
    const r = await this.prisma.user_shortlists.deleteMany({
      where: { user_id: userId, college_branch_id: collegeBranchId },
    });
    return { removed: r.count };
  }

  /** Reorder the whole list in one call, the way a drag-and-drop list saves. */
  async reorder(userId: bigint, orderedIds: bigint[]): Promise<{ updated: number }> {
    let updated = 0;
    for (const [index, id] of orderedIds.entries()) {
      const r = await this.prisma.user_shortlists.updateMany({
        where: { user_id: userId, college_branch_id: id },
        data: { preference_order: index + 1 },
      });
      updated += r.count;
    }
    return { updated };
  }

  /** Just the ids, so the client can render toggles without loading the list. */
  async ids(userId: bigint): Promise<string[]> {
    const rows = await this.prisma.user_shortlists.findMany({
      where: { user_id: userId },
      select: { college_branch_id: true },
    });
    return rows.map((r) => r.college_branch_id.toString());
  }
}
