import { Injectable, NotFoundException } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

export interface CollegeListItem {
  slug: string;
  name: string;
  short_name: string | null;
  college_type: string;
  state_name: string;
  city_name: string | null;
  nirf_rank_latest: number | null;
  programme_count: number;
}

/** College search, detail and programmes. */
@Injectable()
export class CollegesService {
  constructor(protected readonly prisma: PrismaService) {}

  /**
   * Search and filter.
   *
   * Substring first, then a trigram fallback so a misspelling still lands
   * ("Tiruchirapalli" with one l finds Tiruchirappalli). It does NOT resolve
   * nicknames: "trichy" shares too few trigrams with the official name to
   * match, and pretending otherwise would just be a worse kind of miss. A
   * nickname index is a separate piece of work.
   */
  async search(params: {
    q?: string;
    stateCode?: string;
    type?: string;
    limit: number;
    skip: number;
  }): Promise<{ items: CollegeListItem[]; total: number }> {
    const { q = null, stateCode = null, type = null, limit, skip } = params;

    const items = await this.prisma.$queryRaw<CollegeListItem[]>`
      SELECT c.slug, c.name, c.short_name, c.college_type::TEXT, s.name AS state_name,
             ct.name AS city_name, c.nirf_rank_latest,
             (SELECT count(*)::int FROM college_branches cb
               WHERE cb.college_id = c.id AND cb.is_active) AS programme_count
      FROM colleges c
      JOIN states s ON s.id = c.state_id
      LEFT JOIN cities ct ON ct.id = c.city_id
      WHERE c.is_active
        AND (${q}::TEXT IS NULL
             OR c.name ILIKE '%' || ${q}::TEXT || '%'
             OR c.short_name ILIKE '%' || ${q}::TEXT || '%'
             OR c.name % ${q}::TEXT
             OR c.short_name % ${q}::TEXT)
        AND (${stateCode}::TEXT IS NULL OR s.code = ${stateCode}::TEXT)
        AND (${type}::TEXT IS NULL OR c.college_type::TEXT = ${type}::TEXT)
      ORDER BY
        -- Exact substring hits before fuzzy ones, then ranked colleges first.
        CASE WHEN ${q}::TEXT IS NULL THEN 0
             WHEN c.name ILIKE '%' || ${q}::TEXT || '%'
               OR c.short_name ILIKE '%' || ${q}::TEXT || '%' THEN 0
             ELSE 1 END,
        c.nirf_rank_latest NULLS LAST, c.name
      LIMIT ${limit} OFFSET ${skip}
    `;

    const [{ total }] = await this.prisma.$queryRaw<Array<{ total: number }>>`
      SELECT count(*)::int AS total
      FROM colleges c
      JOIN states s ON s.id = c.state_id
      WHERE c.is_active
        AND (${q}::TEXT IS NULL
             OR c.name ILIKE '%' || ${q}::TEXT || '%'
             OR c.short_name ILIKE '%' || ${q}::TEXT || '%'
             OR c.name % ${q}::TEXT
             OR c.short_name % ${q}::TEXT)
        AND (${stateCode}::TEXT IS NULL OR s.code = ${stateCode}::TEXT)
        AND (${type}::TEXT IS NULL OR c.college_type::TEXT = ${type}::TEXT)
    `;

    return { items, total };
  }

  /** Everything the college detail page needs, in one call. */
  async detail(slug: string) {
    const college = await this.prisma.colleges.findUnique({
      where: { slug },
      select: {
        id: true, slug: true, name: true, short_name: true, about: true,
        college_type: true, ownership: true, affiliated_university: true,
        established_year: true, website: true, has_hostel: true,
        nirf_rank_latest: true, nirf_year_latest: true,
        states: { select: { code: true, name: true } },
        cities: { select: { name: true } },
      },
    });
    if (!college) throw new NotFoundException(`No college with slug "${slug}"`);

    // Programmes with their most recent closing rank, so the page can show
    // "CSE - closed at 4,102 last year" without a second round trip.
    const programmes = await this.prisma.$queryRaw<Array<{
      college_branch_id: bigint; program_name: string; branch_code: string;
      branch_name: string; degree: string; duration_years: string;
      total_intake: number | null; measure: string | null;
      latest_closing: string | null; latest_max_score: string | null;
      latest_year: number | null; years_available: number | null;
    }>>`
      SELECT cb.id AS college_branch_id, cb.program_name, b.code AS branch_code,
             b.name AS branch_name, cb.degree::TEXT, cb.duration_years::TEXT,
             cb.total_intake,
             -- Open general seat is the headline number students look for.
             -- Read through v_program_latest_cutoff rather than the rank trend
             -- view: BITS admits on a score and has no row in the latter.
             t.measure, t.latest_closing::TEXT, t.latest_max_score::TEXT,
             t.latest_year, t.years_available
      FROM college_branches cb
      JOIN branches b ON b.id = cb.branch_id
      LEFT JOIN LATERAL (
        SELECT mt.measure, mt.latest_closing, mt.latest_max_score,
               mt.latest_year, mt.years_available
        FROM v_program_latest_cutoff mt
        JOIN seat_types st ON st.id = mt.seat_type_id AND st.code = 'OPEN'
        JOIN quotas q      ON q.id  = mt.quota_id     AND q.code IN ('AI', 'HS')
        JOIN genders g     ON g.id  = mt.gender_id    AND g.code = 'GENDER_NEUTRAL'
        WHERE mt.college_branch_id = cb.id
        ORDER BY mt.latest_year DESC, q.code
        LIMIT 1
      ) t ON true
      WHERE cb.college_id = ${college.id} AND cb.is_active
      -- Ranks ascend and scores descend, so one ORDER BY cannot rank both.
      -- Sort ranks the way students expect and leave scores in branch order
      -- behind them, rather than interleaving two incomparable scales.
      ORDER BY (t.measure = 'rank') DESC NULLS LAST,
               CASE WHEN t.measure = 'rank' THEN t.latest_closing END NULLS LAST,
               CASE WHEN t.measure = 'score' THEN t.latest_closing END DESC NULLS LAST,
               b.display_order, cb.program_name
    `;

    // Which counselling bodies admit to this college, and for how many years.
    const authorities = await this.prisma.$queryRaw<Array<{
      code: string; name: string; years: number[]; rows: number;
    }>>`
      SELECT a.code, a.name,
             array_agg(DISTINCT cd.academic_year ORDER BY cd.academic_year DESC) AS years,
             count(*)::int AS rows
      FROM cutoff_data cd
      JOIN counselling_processes cp ON cp.id = cd.counselling_process_id
      JOIN counselling_authorities a ON a.id = cp.counselling_authority_id
      WHERE cd.college_id = ${college.id}
      GROUP BY a.code, a.name
      ORDER BY rows DESC
    `;

    return { college, programmes, authorities };
  }

  /**
   * Side-by-side comparison, design doc section 16.
   *
   * Every column is fetched for the same seat dimension so the numbers are
   * actually comparable: a general open All-India seat unless the caller says
   * otherwise. Comparing one college's OPEN cutoff against another's SC cutoff
   * would look like a comparison and be meaningless.
   */
  async compare(slugs: string[], opts: { seatType: string; quota: string; gender: string }) {
    if (slugs.length < 2) {
      throw new NotFoundException('Give at least two college slugs to compare.');
    }

    const colleges = await this.prisma.$queryRaw<Array<{
      id: number; slug: string; name: string; short_name: string | null;
      college_type: string; ownership: string; state_name: string;
      city_name: string | null; established_year: number | null;
      has_hostel: boolean | null; nirf_rank_latest: number | null;
      website: string | null; programme_count: number;
    }>>`
      SELECT c.id, c.slug, c.name, c.short_name, c.college_type::TEXT, c.ownership::TEXT,
             s.name AS state_name, ct.name AS city_name, c.established_year,
             c.has_hostel, c.nirf_rank_latest, c.website,
             (SELECT count(*)::int FROM college_branches cb
               WHERE cb.college_id = c.id AND cb.is_active) AS programme_count
      FROM colleges c
      JOIN states s ON s.id = c.state_id
      LEFT JOIN cities ct ON ct.id = c.city_id
      WHERE c.slug = ANY(${slugs}::TEXT[])
    `;

    const found = new Set(colleges.map((c) => c.slug));
    const missing = slugs.filter((s) => !found.has(s));
    if (missing.length) {
      throw new NotFoundException(`Unknown college slug(s): ${missing.join(', ')}`);
    }

    // Branches offered by at least one of them, with each college's cutoff.
    const cutoffs = await this.prisma.$queryRaw<Array<{
      slug: string; branch_code: string; branch_name: string;
      measure: string; latest_closing: string | null;
      latest_max_score: string | null;
      latest_year: number | null; years_available: number;
    }>>`
      SELECT c.slug, b.code AS branch_code, b.name AS branch_name,
             t.measure, t.latest_closing::TEXT, t.latest_max_score::TEXT,
             t.latest_year, t.years_available
      FROM v_program_latest_cutoff t
      JOIN colleges c   ON c.id = t.college_id
      JOIN branches b   ON b.id = t.branch_id
      JOIN seat_types st ON st.id = t.seat_type_id AND st.code = ${opts.seatType}
      JOIN quotas q     ON q.id  = t.quota_id     AND q.code  = ${opts.quota}
      JOIN genders g    ON g.id  = t.gender_id    AND g.code  = ${opts.gender}
      WHERE c.slug = ANY(${slugs}::TEXT[])
      ORDER BY b.display_order, c.slug
    `;

    return {
      seatDimension: opts,
      colleges,
      // Grouped by branch so the client renders one row per branch.
      branches: [...new Map(cutoffs.map((r) => [r.branch_code, {
        code: r.branch_code,
        name: r.branch_name,
        byCollege: Object.fromEntries(
          cutoffs
            .filter((x) => x.branch_code === r.branch_code)
            // Each cell carries its own measure. Putting a BITSAT score of
            // 308/390 in the same column as an NIT closing rank of 4,102 is
            // fine to LOOK at side by side and meaningless to compare as
            // numbers, so the client is told which each one is and never asked
            // to pick a winner across them.
            .map((x) => [x.slug, {
              measure: x.measure,
              latestClosing: x.latest_closing === null ? null : Number(x.latest_closing),
              maxScore: x.latest_max_score === null ? null : Number(x.latest_max_score),
              latestYear: x.latest_year,
              yearsAvailable: x.years_available,
            }]),
        ),
      }])).values()],
    };
  }
}
