import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';
import { CutoffQueryDto } from './dto/cutoff-query.dto';

export interface CutoffHistoryRow {
  academic_year: number;
  round_no: number;
  authority_code: string;
  opening_rank: string | null;
  closing_rank: string | null;
  seat_type: string;
  quota: string;
  gender_pool: string;
}

/** Historical opening/closing rank queries for the college and branch screens. */
@Injectable()
export class CutoffsService {
  constructor(protected readonly prisma: PrismaService) {}

  /**
   * Cutoff history for one program.
   *
   * Every filter is optional and applied with `IS NULL OR`, which lets the
   * screen start wide ("all categories, all rounds") and narrow down without a
   * different query per combination. The partition key (academic_year) is in
   * the index prefix, so the planner still prunes partitions.
   */
  async historyForProgram(
    collegeBranchId: bigint,
    query: CutoffQueryDto,
  ): Promise<CutoffHistoryRow[]> {
    return this.prisma.$queryRaw<CutoffHistoryRow[]>`
      SELECT c.academic_year,
             c.round_no,
             ca.code       AS authority_code,
             c.opening_rank,
             c.closing_rank,
             st.name       AS seat_type,
             q.name        AS quota,
             g.name        AS gender_pool
      FROM cutoff_data c
      JOIN counselling_processes   cp ON cp.id = c.counselling_process_id
      JOIN counselling_authorities ca ON ca.id = cp.counselling_authority_id
      JOIN seat_types st ON st.id = c.seat_type_id
      JOIN quotas     q  ON q.id  = c.quota_id
      JOIN genders    g  ON g.id  = c.gender_id
      WHERE c.college_branch_id = ${collegeBranchId}
        AND (${query.year ?? null}::SMALLINT       IS NULL OR c.academic_year = ${query.year ?? null}::SMALLINT)
        AND (${query.round ?? null}::SMALLINT      IS NULL OR c.round_no      = ${query.round ?? null}::SMALLINT)
        AND (${query.authorityCode ?? null}::TEXT  IS NULL OR ca.code         = ${query.authorityCode ?? null}::TEXT)
        AND (${query.seatTypeCode ?? null}::TEXT   IS NULL OR st.code         = ${query.seatTypeCode ?? null}::TEXT)
        AND (${query.quotaCode ?? null}::TEXT      IS NULL OR q.code          = ${query.quotaCode ?? null}::TEXT)
        AND (${query.genderCode ?? null}::TEXT     IS NULL OR g.code          = ${query.genderCode ?? null}::TEXT)
      ORDER BY c.academic_year DESC, c.round_no DESC
      LIMIT ${query.limit} OFFSET ${query.skip}
    `;
  }

  /** Pre-aggregated trend row backing the cutoff chart. */
  async trendForProgram(collegeBranchId: bigint, seatTypeCode: string, quotaCode: string, genderCode: string) {
    return this.prisma.$queryRaw`
      SELECT t.*
      FROM mv_program_cutoff_trend t
      JOIN seat_types st ON st.id = t.seat_type_id AND st.code = ${seatTypeCode}
      JOIN quotas     q  ON q.id  = t.quota_id     AND q.code  = ${quotaCode}
      JOIN genders    g  ON g.id  = t.gender_id    AND g.code  = ${genderCode}
      WHERE t.college_branch_id = ${collegeBranchId}
    `;
  }
}
