import { Injectable, Logger } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';
import { RawCutoffRow } from '../adapters/source-adapter.interface';
import { NormalizedCutoffRow } from './cutoff-validator';

/** Mirrors the degree_type enum in 001_extensions_and_enums.sql. */
type DegreeType = 'BTech' | 'BE' | 'BArch' | 'BPlan' | 'Dual' | 'Integrated' | 'BPharm';

export interface ResolveContext {
  counsellingProcessId: number;
  counsellingAuthorityId: number;
  /**
   * Bootstrap mode. The very first import has an empty college master, so
   * there is nothing to match against. With this on, an unknown institute or
   * programme is created instead of parked for review.
   *
   * Only ever turn it on for a tier-1 official source: it lets a typo in the
   * feed become a permanent college row.
   */
  createMissing: boolean;
  defaultStateId: number;
}

/**
 * Turns the authority's printed labels into our ids.
 *
 * Resolution is tiered, strictest first, and never guesses silently: anything
 * that falls through returns undefined and the row is parked as invalid with a
 * message naming the exact label that could not be matched.
 *
 * Everything is cached per import. A JoSAA year is ~1.5M rows over ~120
 * institutes, so without caching this would be a million redundant queries.
 */
@Injectable()
export class EntityResolver {
  private readonly logger = new Logger(EntityResolver.name);

  /** Near-exact: tolerates punctuation and spacing, not a different city. */
  private static readonly NAME_MATCH_MIN = 0.92;
  /** The runner-up must be clearly worse, or the match is a coin flip. */
  private static readonly NAME_MATCH_MARGIN = 0.08;
  /** Above this but failing the bar above = ambiguous, park it for review. */
  private static readonly NAME_AMBIGUOUS_FLOOR = 0.6;

  private collegeByKey = new Map<string, number>();
  private programByKey = new Map<string, { id: bigint; branchId: number }>();
  private seatTypeByLabel = new Map<string, number>();
  private quotaByLabel = new Map<string, number>();
  private genderByLabel = new Map<string, number>();
  private branchByAlias = new Map<string, number>();
  private unresolved = new Map<string, number>();

  constructor(private readonly prisma: PrismaService) {}

  static norm(s: string): string {
    return s.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  }

  /** Load every lookup this import could need, once. */
  async warmUp(ctx: ResolveContext): Promise<void> {
    this.collegeByKey.clear();
    this.programByKey.clear();
    this.branchByAlias.clear();
    this.unresolved.clear();

    const [codes, colleges, dimensions, aliases, branches, programs] = await Promise.all([
      this.prisma.college_institute_codes.findMany({
        where: { counselling_authority_id: ctx.counsellingAuthorityId },
        select: { institute_code: true, institute_name_as_printed: true, college_id: true },
      }),
      this.prisma.colleges.findMany({ select: { id: true, name: true, short_name: true } }),
      this.prisma.counselling_dimension_map.findMany({
        where: { counselling_process_id: ctx.counsellingProcessId, is_active: true },
        select: { dimension: true, ref_id: true, source_label: true },
      }),
      this.prisma.branch_aliases.findMany({
        select: { normalized_alias: true, branch_id: true, counselling_authority_id: true },
      }),
      this.prisma.branches.findMany({ select: { id: true, code: true, name: true } }),
      this.prisma.college_branches.findMany({
        select: { id: true, college_id: true, branch_id: true, program_name: true },
      }),
    ]);

    for (const c of codes) {
      if (c.institute_code) this.collegeByKey.set(`code:${c.institute_code}`, c.college_id);
      if (c.institute_name_as_printed) {
        this.collegeByKey.set(`name:${EntityResolver.norm(c.institute_name_as_printed)}`, c.college_id);
      }
    }
    for (const c of colleges) {
      this.collegeByKey.set(`name:${EntityResolver.norm(c.name)}`, c.id);
      if (c.short_name) this.collegeByKey.set(`name:${EntityResolver.norm(c.short_name)}`, c.id);
    }
    for (const p of programs) {
      this.programByKey.set(
        `${p.college_id}|${EntityResolver.norm(p.program_name)}`,
        { id: p.id, branchId: p.branch_id },
      );
    }
    // Three layers, weakest first, because the last write wins.
    //
    //   1. our own branch codes and names -- the fallback for a feed that
    //      happens to print the same thing we call it
    //   2. global aliases
    //   3. this authority's own aliases, which are the most specific thing we
    //      know and must beat both
    //
    // The order matters and used to be the other way round. COMEDK writes "CE"
    // for Computer Engineering and "CV" for Civil, while everyone else uses CE
    // for Civil, so its aliases are tagged with the authority -- but the
    // canonical loop ran last and put "ce" back to Civil before any row was
    // read. COMEDK's CE, EE and ECE were all filed under the wrong branch;
    // CV, CS, EC and CH survived only because we have no branch whose code
    // spells those.
    for (const b of branches) {
      this.branchByAlias.set(EntityResolver.norm(b.code), b.id);
      this.branchByAlias.set(EntityResolver.norm(b.name), b.id);
    }
    for (const a of aliases) {
      if (a.counselling_authority_id === null) this.branchByAlias.set(a.normalized_alias, a.branch_id);
    }
    for (const a of aliases) {
      if (a.counselling_authority_id === ctx.counsellingAuthorityId) {
        this.branchByAlias.set(a.normalized_alias, a.branch_id);
      }
    }

    // Authority labels first; they win over canonical codes when both exist.
    const canonical = await Promise.all([
      this.prisma.seat_types.findMany({ select: { id: true, code: true, name: true } }),
      this.prisma.quotas.findMany({ select: { id: true, code: true, name: true } }),
      this.prisma.genders.findMany({ select: { id: true, code: true, name: true } }),
    ]);
    const [seatTypes, quotas, genders] = canonical;
    for (const s of seatTypes) {
      this.seatTypeByLabel.set(EntityResolver.norm(s.code), s.id);
      this.seatTypeByLabel.set(EntityResolver.norm(s.name), s.id);
    }
    for (const q of quotas) {
      this.quotaByLabel.set(EntityResolver.norm(q.code), q.id);
      this.quotaByLabel.set(EntityResolver.norm(q.name), q.id);
    }
    for (const g of genders) {
      this.genderByLabel.set(EntityResolver.norm(g.code), g.id);
      this.genderByLabel.set(EntityResolver.norm(g.name), g.id);
    }
    for (const d of dimensions) {
      const key = EntityResolver.norm(d.source_label);
      if (d.dimension === 'seat_type') this.seatTypeByLabel.set(key, d.ref_id);
      if (d.dimension === 'quota') this.quotaByLabel.set(key, d.ref_id);
      if (d.dimension === 'gender') this.genderByLabel.set(key, d.ref_id);
    }

    this.logger.log(
      `resolver warm: ${this.collegeByKey.size} college keys, ${this.programByKey.size} programmes, ` +
        `${this.branchByAlias.size} branch aliases`,
    );
  }

  async resolve(
    raw: RawCutoffRow,
    ctx: ResolveContext,
  ): Promise<Partial<NormalizedCutoffRow>> {
    const out: Partial<NormalizedCutoffRow> = {
      roundNo: raw.roundNo,
      openingRank: raw.openingRank ?? null,
      closingRank: raw.closingRank ?? null,
      openingPercentile: raw.openingPercentile ?? null,
      closingPercentile: raw.closingPercentile ?? null,
      openingScore: raw.openingScore ?? null,
      closingScore: raw.closingScore ?? null,
      maxScore: raw.maxScore ?? null,
      isPreparatory: raw.isPreparatory ?? false,
    };

    const seatKey = EntityResolver.norm(raw.seatTypeLabel);
    out.seatTypeId = this.seatTypeByLabel.get(seatKey);

    // Some authorities encode several dimensions in one code. UPTAC writes
    // "BCGL" for a Backward Class girls' seat and "EWSAF" for an EWS armed
    // forces seat -- one label that is simultaneously a seat type, a gender
    // pool and a quota. counselling_dimension_map expresses that by mapping
    // the same label under more than one dimension.
    //
    // The compound code wins over the dedicated column, because where both
    // exist the column is the less specific of the two: UPTAC's "Seat Gender"
    // says "Co-Education", which describes the institute, while the GL in
    // "OPGL" is what actually marks the seat as a girls' seat. Reading the
    // column first silently collapsed every girls' seat onto the neutral pool
    // and lost 3,527 rows to key collisions.
    //
    // Feeds with a real gender column are unaffected: their seat-type labels
    // have no gender mapping, so the lookup falls straight through.
    out.quotaId =
      this.quotaByLabel.get(seatKey) ??
      this.quotaByLabel.get(EntityResolver.norm(raw.quotaLabel));
    out.genderId =
      this.genderByLabel.get(seatKey) ??
      this.genderByLabel.get(EntityResolver.norm(raw.genderLabel));

    if (!out.seatTypeId) this.note(`seat_type:${raw.seatTypeLabel}`);
    if (!out.quotaId) this.note(`quota:${raw.quotaLabel}`);
    if (!out.genderId) this.note(`gender:${raw.genderLabel}`);

    const collegeId = await this.resolveCollege(raw, ctx);
    if (!collegeId) return out;
    out.collegeId = collegeId;

    const program = await this.resolveProgram(raw, collegeId, ctx);
    if (!program) return out;
    out.collegeBranchId = program.id;
    out.branchId = program.branchId;

    return out;
  }

  private async resolveCollege(
    raw: RawCutoffRow,
    ctx: ResolveContext,
  ): Promise<number | undefined> {
    if (raw.instituteCode) {
      const byCode = this.collegeByKey.get(`code:${raw.instituteCode}`);
      if (byCode) return byCode;
    }

    const key = EntityResolver.norm(raw.instituteName);
    const exact = this.collegeByKey.get(`name:${key}`);
    if (exact) return exact;

    // Bootstrap mode does NOT fuzzy match.
    //
    // A single authority feed is internally consistent: JoSAA prints
    // "Indian Institute of Technology Kharagpur" the same way in every row and
    // every round. Fuzzy matching is for reconciling ACROSS sources, and using
    // it while the master is still being built is actively harmful -- the few
    // colleges already present become attractors that every new name is
    // "ambiguous" against, which blocks the whole import.
    if (ctx.createMissing) {
      return this.createCollege(raw, ctx, key);
    }

    // Reconciliation mode: the master is populated, so a near-match is worth
    // considering -- but only if it is unmistakable.
    //
    // A plain threshold does NOT work. Indian institute names share a long
    // common prefix, so genuinely different institutes score high:
    //
    //   IIT Delhi   vs IIT Bombay   -> 0.690
    //   NIT Calicut vs NIT Silchar  -> 0.673
    //
    // An earlier 0.55 cut silently merged IIT Delhi into IIT Bombay and moved
    // Delhi's Mechanical programme onto Bombay. So: demand a near-exact score
    // AND demand the runner-up is clearly worse. Anything between is ambiguous
    // and gets parked for a human, who fixes it once in college_institute_codes.
    const candidates = await this.prisma.$queryRaw<Array<{ id: number; name: string; sim: number }>>`
      SELECT id, name, similarity(lower(name), ${key}) AS sim
      FROM colleges
      WHERE lower(name) % ${key}
      ORDER BY sim DESC
      LIMIT 2
    `;
    const best = candidates[0];
    const runnerUp = candidates[1];

    if (best) {
      const margin = best.sim - (runnerUp?.sim ?? 0);
      if (best.sim >= EntityResolver.NAME_MATCH_MIN && margin >= EntityResolver.NAME_MATCH_MARGIN) {
        this.collegeByKey.set(`name:${key}`, best.id);
        return best.id;
      }
      if (best.sim >= EntityResolver.NAME_AMBIGUOUS_FLOOR) {
        this.note(
          `ambiguous-college:${raw.instituteName} -> "${best.name}" (${best.sim.toFixed(3)})` +
            (runnerUp ? ` vs "${runnerUp.name}" (${runnerUp.sim.toFixed(3)})` : ''),
        );
        return undefined;
      }
    }

    this.note(`college:${raw.instituteName}`);
    return undefined;
  }

  private async createCollege(
    raw: RawCutoffRow,
    ctx: ResolveContext,
    key: string,
  ): Promise<number> {
    const created = await this.prisma.colleges.create({
      data: {
        slug: this.slug(raw.instituteName),
        name: raw.instituteName,
        short_name: this.shortName(raw.instituteName),
        college_type: this.guessCollegeType(raw.instituteName),
        ownership: 'government',
        state_id: ctx.defaultStateId,
      },
      select: { id: true },
    });
    if (raw.instituteCode) {
      await this.prisma.college_institute_codes.create({
        data: {
          college_id: created.id,
          counselling_authority_id: ctx.counsellingAuthorityId,
          institute_code: raw.instituteCode,
          institute_name_as_printed: raw.instituteName,
        },
      });
      this.collegeByKey.set(`code:${raw.instituteCode}`, created.id);
    }
    this.collegeByKey.set(`name:${key}`, created.id);

    // The feed does not carry a state, so the college lands on the fallback.
    // That is not cosmetic: home-state quota eligibility is decided by
    // colleges.state_id, so until a reviewer corrects it this institute will
    // offer HS seats to the wrong students. Surface it loudly.
    this.note(`created-college-needs-state:${raw.instituteName}`);
    return created.id;
  }

  private async resolveProgram(
    raw: RawCutoffRow,
    collegeId: number,
    ctx: ResolveContext,
  ): Promise<{ id: bigint; branchId: number } | undefined> {
    const key = `${collegeId}|${EntityResolver.norm(raw.programName)}`;
    const exact = this.programByKey.get(key);
    if (exact) return exact;

    const branchId = this.resolveBranch(raw.programName);
    if (!branchId) {
      this.note(`branch:${raw.programName}`);
      return undefined;
    }

    // The college exists and the branch is known, but this college has not
    // offered this programme before. That is normal -- programmes open and
    // close every year -- so create it rather than rejecting the row.
    if (!ctx.createMissing) {
      const existing = await this.prisma.college_branches.findFirst({
        where: { college_id: collegeId, branch_id: branchId },
        select: { id: true, branch_id: true },
      });
      if (existing) {
        const v = { id: existing.id, branchId: existing.branch_id };
        this.programByKey.set(key, v);
        return v;
      }
      this.note(`programme:${raw.programName}`);
      return undefined;
    }

    const { degree, durationYears } = this.readProgramSuffix(raw.programName);
    const created = await this.prisma.college_branches.create({
      data: {
        college_id: collegeId,
        branch_id: branchId,
        program_name: raw.programName,
        degree,
        duration_years: durationYears,
      },
      select: { id: true, branch_id: true },
    });
    const value = { id: created.id, branchId: created.branch_id };
    this.programByKey.set(key, value);
    return value;
  }

  /**
   * Map a printed programme name onto a branch.
   *
   * JoSAA writes the discipline in three different places:
   *
   *   "Computer Science and Engineering (4 Years, Bachelor of Technology)"
   *      -> before the bracket
   *   "B.Tech (Computer Science and Engineering)"
   *      -> INSIDE the bracket; stripping brackets leaves only "B.Tech"
   *   "B.Tech in Electronics & Communication Engineering"
   *      -> after a degree prefix
   *
   * So build a list of candidate strings and try each against the alias table
   * before falling back to the longest contained alias.
   */
  private resolveBranch(programName: string): number | undefined {
    for (const candidate of this.branchCandidates(programName)) {
      const hit = this.branchByAlias.get(EntityResolver.norm(candidate));
      if (hit) return hit;
    }

    // Last resort: the longest alias contained in the full string. Six
    // characters minimum, otherwise "design" style fragments match everything.
    const key = EntityResolver.norm(programName.replace(/\(.*?\)/g, ' '));
    let best: { id: number; len: number } | undefined;
    for (const [alias, id] of this.branchByAlias) {
      if (alias.length >= 6 && key.includes(alias) && (!best || alias.length > best.len)) {
        best = { id, len: alias.length };
      }
    }
    return best?.id;
  }

  private branchCandidates(programName: string): string[] {
    // WBJEEB repeats the Tuition Fee Waiver marker in the programme name
    // ("PRINTING ENGINEERING-TFW", "Jute & Fibre Technology (TFW)") although it
    // is already carried in the category column. Strip it so the discipline
    // matches, rather than aliasing every -TFW variant separately.
    const cleaned = programName.replace(/[\s(-]*TFW[\s)]*/gi, ' ').replace(/\s+/g, ' ').trim();

    const out: string[] = [];
    const outside = cleaned.replace(/\(.*?\)/g, ' ').replace(/\s+/g, ' ').trim();
    if (outside) out.push(outside);

    // Everything inside brackets, longest first: the discipline is usually the
    // longest group, with "(4 Years, Bachelor of Technology)" the shorter one.
    const inside = [...cleaned.matchAll(/\(([^()]*)\)/g)]
      .map((m) => m[1].trim())
      .filter((t) => t && !/\d\s*year|bachelor|master|dual degree|integrated/i.test(t))
      .sort((a, b) => b.length - a.length);
    out.push(...inside);

    // "B.Tech in X", "BS in X", "Bachelor of Technology in X".
    const after = /(?:^|\s)(?:b\.?\s*tech\.?|b\.?\s*e\.?|bs|bachelor(?:\s+of\s+\w+)?)\s+in\s+(.+)$/i
      .exec(outside);
    if (after) out.push(after[1].replace(/\(.*$/, '').trim());

    return out.filter(Boolean);
  }

  /**
   * JoSAA prints the degree and duration inside the programme name:
   *
   *   "... (4 Years, Bachelor of Technology)"
   *   "... (5 Years, Bachelor and Master of Technology (Dual Degree))"
   *
   * Reading them keeps a 4-year BTech and a 5-year dual degree distinguishable
   * on the college page, where showing both as plain "BTech" would be wrong.
   */
  private readProgramSuffix(programName: string): {
    degree: DegreeType;
    durationYears: number;
  } {
    const n = programName.toLowerCase();
    const years = /(\d)\s*year/.exec(n);
    const durationYears = years ? Number.parseInt(years[1], 10) : 4;

    let degree: DegreeType = 'BTech';
    if (n.includes('dual degree')) degree = 'Dual';
    else if (n.includes('integrated')) degree = 'Integrated';
    else if (n.includes('bachelor of architecture')) degree = 'BArch';
    else if (n.includes('bachelor of planning')) degree = 'BPlan';
    else if (n.includes('bachelor of engineering')) degree = 'BE';
    // BITS prints the degree as a prefix instead: "B.E. Civil", "M.Sc. Physics".
    // Its M.Sc. programmes are four-year FIRST degrees entered straight from
    // school on the same BITSAT merit list, not postgraduate ones, so they are
    // 'Integrated' rather than a degree type we do not model.
    else if (/^b\.?\s?e\.?\s/.test(n)) degree = 'BE';
    else if (/^b\.?\s?tech/.test(n)) degree = 'BTech';
    else if (/^b\.?\s?pharm/.test(n)) degree = 'BPharm';
    else if (/^m\.?\s?sc/.test(n)) degree = 'Integrated';

    return { degree, durationYears };
  }

  private guessCollegeType(name: string) {
    const n = name.toLowerCase();
    if (n.includes('indian institute of technology')) return 'IIT' as const;
    if (n.includes('national institute of technology')) return 'NIT' as const;
    if (n.includes('information technology')) return 'IIIT' as const;
    return 'GFTI' as const;
  }

  /**
   * "Indian Institute of Technology Bombay" -> "IIT Bombay".
   * Every list and card in the app shows this; the full legal name wraps to
   * three lines on a phone.
   */
  private shortName(name: string): string | undefined {
    const abbreviations: Array<[RegExp, string]> = [
      [/^indian institute of technology\s+/i, 'IIT '],
      [/^national institute of technology\s+/i, 'NIT '],
      [/^indian institute of information technology\s+/i, 'IIIT '],
    ];
    for (const [pattern, prefix] of abbreviations) {
      if (pattern.test(name)) return prefix + name.replace(pattern, '');
    }
    return name.length <= 40 ? name : undefined;
  }

  private slug(name: string): string {
    return EntityResolver.norm(name).replace(/ /g, '-').slice(0, 80) + '-' + Date.now().toString(36).slice(-4);
  }

  private note(what: string): void {
    this.unresolved.set(what, (this.unresolved.get(what) ?? 0) + 1);
  }

  /** Most common unmatched labels, so the review screen can rank the fixes. */
  unresolvedReport(limit = 25): Array<{ label: string; rows: number }> {
    return [...this.unresolved.entries()]
      .map(([label, rows]) => ({ label, rows }))
      .sort((a, b) => b.rows - a.rows)
      .slice(0, limit);
  }
}
