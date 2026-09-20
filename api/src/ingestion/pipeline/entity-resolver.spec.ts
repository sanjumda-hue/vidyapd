import { PrismaService } from '../../database/prisma.service';
import { RawCutoffRow } from '../adapters/source-adapter.interface';
import { EntityResolver, ResolveContext } from './entity-resolver';

/**
 * Resolver tests, against a stubbed Prisma.
 *
 * The resolver is where an authority's printed labels become our ids, and
 * getting that wrong is the most expensive kind of bug this project has: it
 * does not crash, it just files a cut-off under the wrong branch, the wrong
 * college or the wrong gender pool, and nobody notices until a student is
 * looking at it. Each case below is one that already happened.
 */

const JOSAA = 1;
const COMEDK = 2;
const UPTAC = 3;

/** Branch ids, matching the seeded codes they stand for. */
const BRANCH = { CSE: 1, CE: 2, ME: 3, PHARM: 4, PHY: 5, CHE: 6 };

interface Fixtures {
  colleges?: Array<{ id: number; name: string; short_name: string | null }>;
  collegeBranches?: Array<{
    id: bigint; college_id: number; branch_id: number; program_name: string;
  }>;
  dimensions?: Array<{ dimension: string; ref_id: number; source_label: string }>;
  aliases?: Array<{
    normalized_alias: string; branch_id: number; counselling_authority_id: number | null;
  }>;
  /** Trigram candidates the fuzzy fallback should see, best first. */
  fuzzy?: Array<{ id: number; name: string; sim: number }>;
}

/** The slice of Prisma the resolver actually touches. */
function stubPrisma(f: Fixtures) {
  const created: Array<Record<string, unknown>> = [];
  let nextId = 1000;

  const prisma = {
    created,
    college_institute_codes: {
      findMany: async () => [],
      create: async () => ({}),
    },
    colleges: {
      findMany: async () => f.colleges ?? [],
      create: async ({ data }: { data: Record<string, unknown> }) => {
        created.push({ table: 'colleges', ...data });
        return { id: (nextId += 1) };
      },
    },
    counselling_dimension_map: { findMany: async () => f.dimensions ?? [] },
    branch_aliases: { findMany: async () => f.aliases ?? [] },
    branches: {
      findMany: async () =>
        Object.entries(BRANCH).map(([code, id]) => ({ id, code, name: `${code} full name` })),
    },
    college_branches: {
      findMany: async () => f.collegeBranches ?? [],
      findFirst: async () => null,
      create: async ({ data }: { data: Record<string, unknown> }) => {
        created.push({ table: 'college_branches', ...data });
        return { id: BigInt((nextId += 1)), branch_id: data.branch_id as number };
      },
    },
    seat_types: {
      findMany: async () => [
        { id: 1, code: 'OPEN', name: 'Open' },
        { id: 2, code: 'OBC_NCL', name: 'OBC-NCL' },
      ],
    },
    quotas: {
      findMany: async () => [
        { id: 1, code: 'AI', name: 'All India' },
        { id: 2, code: 'HS', name: 'Home State' },
      ],
    },
    genders: {
      findMany: async () => [
        { id: 1, code: 'GENDER_NEUTRAL', name: 'Gender-Neutral' },
        { id: 2, code: 'FEMALE_ONLY', name: 'Female-Only (including Supernumerary)' },
      ],
    },
    $queryRaw: async () => f.fuzzy ?? [],
  };

  return prisma as unknown as PrismaService & { created: typeof created };
}

const ctx = (over: Partial<ResolveContext> = {}): ResolveContext => ({
  counsellingProcessId: 1,
  counsellingAuthorityId: JOSAA,
  createMissing: false,
  defaultStateId: 1,
  ...over,
});

const raw = (over: Partial<RawCutoffRow> = {}): RawCutoffRow => ({
  instituteName: 'National Institute of Technology Tiruchirappalli',
  programName: 'Computer Science and Engineering',
  seatTypeLabel: 'OPEN',
  quotaLabel: 'HS',
  genderLabel: 'Gender-Neutral',
  roundNo: 5,
  openingRank: 1200,
  closingRank: 4102,
  ...over,
});

async function makeResolver(f: Fixtures, c: ResolveContext = ctx()) {
  const prisma = stubPrisma(f);
  const resolver = new EntityResolver(prisma);
  await resolver.warmUp(c);
  return { resolver, prisma };
}

describe('EntityResolver', () => {
  describe('branch aliases', () => {
    const aliases = [
      // Everyone else: CE is Civil.
      { normalized_alias: 'ce', branch_id: BRANCH.CE, counselling_authority_id: null },
      // COMEDK: CE is Computer Engineering, and CV is Civil.
      { normalized_alias: 'ce', branch_id: BRANCH.CSE, counselling_authority_id: COMEDK },
      { normalized_alias: 'cv', branch_id: BRANCH.CE, counselling_authority_id: COMEDK },
    ];

    it('reads CE as Civil for JoSAA', async () => {
      const { resolver } = await makeResolver({ aliases }, ctx({ counsellingAuthorityId: JOSAA }));
      const out = await resolver.resolve(
        raw({ programName: 'CE' }),
        ctx({ counsellingAuthorityId: JOSAA, createMissing: true }),
      );
      expect(out.branchId).toBe(BRANCH.CE);
    });

    it('reads CE as Computer Engineering for COMEDK', async () => {
      // A single global alias table would have to make one authority wrong.
      // An alias tagged with an authority wins for that authority only.
      const c = ctx({ counsellingAuthorityId: COMEDK, createMissing: true });
      const { resolver } = await makeResolver({ aliases }, c);
      const out = await resolver.resolve(raw({ programName: 'CE' }), c);
      expect(out.branchId).toBe(BRANCH.CSE);
    });

    it('still reads CV as Civil for COMEDK', async () => {
      const c = ctx({ counsellingAuthorityId: COMEDK, createMissing: true });
      const { resolver } = await makeResolver({ aliases }, c);
      const out = await resolver.resolve(raw({ programName: 'CV' }), c);
      expect(out.branchId).toBe(BRANCH.CE);
    });
  });

  describe('compound dimension codes', () => {
    // UPTAC encodes seat type, quota and gender in one label: OPGL is an open
    // girls' seat. Its "Seat Gender" column separately says "Co-Education",
    // which describes the institute, not the seat.
    const dimensions = [
      { dimension: 'seat_type', ref_id: 1, source_label: 'OPGL' },
      { dimension: 'gender', ref_id: 2, source_label: 'OPGL' },
      { dimension: 'quota', ref_id: 2, source_label: 'OPGL' },
    ];

    it('lets the compound code beat the dedicated gender column', async () => {
      // Reading the column first collapsed every girls' seat onto the neutral
      // pool and lost 3,527 rows to natural-key collisions.
      const c = ctx({ counsellingAuthorityId: UPTAC, createMissing: true });
      const { resolver } = await makeResolver({ dimensions }, c);
      const out = await resolver.resolve(
        raw({ seatTypeLabel: 'OPGL', genderLabel: 'Co-Education', quotaLabel: 'Co-Education' }),
        c,
      );
      expect(out.genderId).toBe(2);
      expect(out.quotaId).toBe(2);
    });

    it('leaves a feed with a real gender column alone', async () => {
      // JoSAA's seat-type labels carry no gender mapping, so the lookup falls
      // straight through to the column.
      const c = ctx({ createMissing: true });
      const { resolver } = await makeResolver({}, c);
      const out = await resolver.resolve(raw({ genderLabel: 'Female-Only (including Supernumerary)' }), c);
      expect(out.genderId).toBe(2);
    });
  });

  describe('college matching', () => {
    const colleges = [
      { id: 1, name: 'Indian Institute of Technology Bombay', short_name: 'IIT Bombay' },
      { id: 2, name: 'National Institute of Technology Tiruchirappalli', short_name: 'NIT Trichy' },
    ];

    it('matches an exact printed name', async () => {
      const { resolver } = await makeResolver({ colleges, collegeBranches: [
        { id: 10n, college_id: 2, branch_id: BRANCH.CSE, program_name: 'Computer Science and Engineering' },
      ] });
      const out = await resolver.resolve(raw(), ctx());
      expect(out.collegeId).toBe(2);
      expect(out.collegeBranchId).toBe(10n);
    });

    it('matches on the short name too', async () => {
      const { resolver } = await makeResolver({ colleges, collegeBranches: [
        { id: 10n, college_id: 2, branch_id: BRANCH.CSE, program_name: 'Computer Science and Engineering' },
      ] });
      const out = await resolver.resolve(raw({ instituteName: 'NIT Trichy' }), ctx());
      expect(out.collegeId).toBe(2);
    });

    it('refuses an ambiguous near-match instead of merging two institutes', async () => {
      // A 0.55 similarity cut once merged IIT Delhi into IIT Bombay -- they
      // score 0.690 against each other, because Indian institute names share a
      // long common prefix -- and moved Delhi's Mechanical programme onto
      // Bombay. The row is parked for a human instead.
      const { resolver } = await makeResolver({
        colleges,
        fuzzy: [
          { id: 1, name: 'Indian Institute of Technology Bombay', sim: 0.69 },
          { id: 3, name: 'Indian Institute of Technology Madras', sim: 0.66 },
        ],
      });
      const out = await resolver.resolve(
        raw({ instituteName: 'Indian Institute of Technology Delhi' }),
        ctx(),
      );
      expect(out.collegeId).toBeUndefined();
      expect(resolver.unresolvedReport().some((u) => u.label.startsWith('ambiguous-college:')))
        .toBe(true);
    });

    it('accepts a near-exact match that clearly beats the runner-up', async () => {
      const { resolver } = await makeResolver({
        colleges,
        collegeBranches: [
          { id: 10n, college_id: 2, branch_id: BRANCH.CSE, program_name: 'Computer Science and Engineering' },
        ],
        fuzzy: [
          { id: 2, name: 'National Institute of Technology Tiruchirappalli', sim: 0.97 },
          { id: 1, name: 'Indian Institute of Technology Bombay', sim: 0.31 },
        ],
      });
      const out = await resolver.resolve(
        raw({ instituteName: 'National Institute of Technology, Tiruchirappalli.' }),
        ctx(),
      );
      expect(out.collegeId).toBe(2);
    });

    it('does not fuzzy match while bootstrapping an empty master', async () => {
      // During the first import the few colleges already present become
      // attractors that every new name is "ambiguous" against, which blocks
      // the whole run.
      const c = ctx({ createMissing: true });
      const { resolver, prisma } = await makeResolver({
        colleges,
        fuzzy: [{ id: 1, name: 'Indian Institute of Technology Bombay', sim: 0.69 }],
      }, c);
      const out = await resolver.resolve(
        raw({ instituteName: 'Indian Institute of Technology Delhi' }),
        c,
      );
      expect(out.collegeId).not.toBe(1);
      expect(prisma.created.some((r) => r.table === 'colleges' &&
        r.name === 'Indian Institute of Technology Delhi')).toBe(true);
    });
  });

  describe('degree from the programme name', () => {
    const c = ctx({ createMissing: true });
    const cases: Array<[string, number, string]> = [
      ['Civil Engineering (4 Years, Bachelor of Technology)', BRANCH.CE, 'BTech'],
      ['Civil Engineering (5 Years, Bachelor and Master of Technology (Dual Degree))', BRANCH.CE, 'Dual'],
      // BITS prints the degree as a prefix rather than a bracketed suffix.
      ['B.E. Civil', BRANCH.CE, 'BE'],
      ['B.Pharm.', BRANCH.PHARM, 'BPharm'],
      // A four-year first degree entered straight from school, not a PG one.
      ['M.Sc. Physics', BRANCH.PHY, 'Integrated'],
    ];

    it.each(cases)('reads %p as %#', async (programName, branchId, degree) => {
      const { resolver, prisma } = await makeResolver({
        colleges: [{ id: 1, name: 'BITS Pilani, Pilani Campus', short_name: 'BITS Pilani' }],
        aliases: [
          { normalized_alias: 'b e civil', branch_id: BRANCH.CE, counselling_authority_id: null },
          { normalized_alias: 'b pharm', branch_id: BRANCH.PHARM, counselling_authority_id: null },
          { normalized_alias: 'm sc physics', branch_id: BRANCH.PHY, counselling_authority_id: null },
          { normalized_alias: 'civil engineering', branch_id: BRANCH.CE, counselling_authority_id: null },
        ],
      }, c);

      const out = await resolver.resolve(
        raw({ instituteName: 'BITS Pilani, Pilani Campus', programName }),
        c,
      );
      expect(out.branchId).toBe(branchId);
      expect(prisma.created.find((r) => r.table === 'college_branches')?.degree).toBe(degree);
    });
  });

  describe('measures pass through untouched', () => {
    it('carries a score and its paper total', async () => {
      const c = ctx({ createMissing: true });
      const { resolver } = await makeResolver({}, c);
      const out = await resolver.resolve(
        raw({
          openingRank: null, closingRank: null,
          closingScore: 308, maxScore: 390,
        }),
        c,
      );
      expect(out.closingScore).toBe(308);
      expect(out.maxScore).toBe(390);
      expect(out.closingRank).toBeNull();
    });

    it('carries the preparatory flag', async () => {
      const c = ctx({ createMissing: true });
      const { resolver } = await makeResolver({}, c);
      const out = await resolver.resolve(raw({ isPreparatory: true }), c);
      expect(out.isPreparatory).toBe(true);
    });
  });
});
