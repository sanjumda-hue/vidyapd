import { RawCutoffRow } from '../adapters/source-adapter.interface';
import { CutoffValidator, NormalizedCutoffRow } from './cutoff-validator';

/**
 * The validator is the last thing between a misread column and 300,000 rows of
 * quietly wrong cut-offs, so its job is to be suspicious. These tests pin the
 * rules that have already caught something real.
 */
describe('CutoffValidator', () => {
  let validator: CutoffValidator;

  beforeEach(() => {
    validator = new CutoffValidator();
  });

  const raw = (over: Partial<RawCutoffRow> = {}): RawCutoffRow => ({
    instituteName: 'NIT Trichy',
    programName: 'Computer Science and Engineering',
    seatTypeLabel: 'OPEN',
    quotaLabel: 'HS',
    genderLabel: 'Gender-Neutral',
    roundNo: 5,
    openingRank: 1200,
    closingRank: 4102,
    ...over,
  });

  const resolved = (over: Partial<NormalizedCutoffRow> = {}): Partial<NormalizedCutoffRow> => ({
    collegeId: 1,
    collegeBranchId: 10n,
    branchId: 1,
    seatTypeId: 1,
    quotaId: 1,
    genderId: 1,
    ...over,
  });

  const codes = (r: RawCutoffRow, res = resolved()) =>
    validator.validate(r, res).map((e) => e.code);

  it('passes a well-formed rank row', () => {
    expect(codes(raw())).toEqual([]);
  });

  describe('unresolved references', () => {
    it('never guesses at an unmapped seat type', () => {
      // WBJEEB prints "OBC - A", which no other authority has. Guessing it to
      // be plain OBC would have put 731 rows in the wrong reservation pool.
      expect(codes(raw({ seatTypeLabel: 'OBC - A' }), resolved({ seatTypeId: undefined })))
        .toContain('UNRESOLVED_DIMENSION');
    });

    it('reports the unmatched institute and programme separately', () => {
      const errors = validator.validate(
        raw(),
        resolved({ collegeId: undefined, collegeBranchId: undefined }),
      );
      expect(errors.map((e) => e.code)).toEqual(
        expect.arrayContaining(['UNRESOLVED_COLLEGE', 'UNRESOLVED_PROGRAM']),
      );
    });

    it('quotes the offending label so the review screen can show it', () => {
      const [error] = validator.validate(
        raw({ quotaLabel: 'DASA-CIWG' }),
        resolved({ quotaId: undefined }),
      );
      expect(error.message).toContain('DASA-CIWG');
    });
  });

  describe('implausible ranks', () => {
    it('rejects a rank larger than any Indian entrance exam', () => {
      // This is the check that caught all 45 of the 10x decimal corruptions
      // before they reached the database.
      expect(codes(raw({ closingRank: 11_738_080 }))).toContain('IMPLAUSIBLE_RANK');
    });

    it('accepts a genuine seven-figure rank', () => {
      expect(codes(raw({ openingRank: 1_000_000, closingRank: 1_021_800 }))).toEqual([]);
    });

    it('rejects a non-positive rank', () => {
      expect(codes(raw({ closingRank: 0 }))).toContain('BAD_RANK');
    });
  });

  describe('column-order sanity', () => {
    it('rejects a row whose opening rank is worse than its closing rank', () => {
      expect(codes(raw({ openingRank: 4102, closingRank: 1200 }))).toContain('RANK_ORDER');
    });

    it('exempts preparatory rows, which are ranked on a separate list', () => {
      expect(codes(raw({ openingRank: 109, closingRank: 26, isPreparatory: true })))
        .not.toContain('RANK_ORDER');
    });

    it('knows percentiles run the other way round', () => {
      expect(
        codes(raw({
          openingRank: null, closingRank: null,
          openingPercentile: 91.2, closingPercentile: 94.8,
        })),
      ).toContain('PERCENTILE_ORDER');
    });
  });

  describe('measures', () => {
    it('rejects a row with no rank, percentile or score', () => {
      expect(codes(raw({ openingRank: null, closingRank: null }))).toContain('NO_MEASURE');
    });

    it('accepts a score-only row', () => {
      // BITSAT rows carry no rank at all. Before the score path existed these
      // were rejected outright as having no measure.
      expect(
        codes(raw({
          openingRank: null, closingRank: null,
          closingScore: 308, maxScore: 390,
        })),
      ).toEqual([]);
    });

    it('rejects a score with no paper total', () => {
      // chk_cutoff_score_needs_max refuses this at the database. Catching it
      // here parks the one bad row instead of aborting the whole batch insert.
      expect(codes(raw({ openingRank: null, closingRank: null, closingScore: 308 })))
        .toContain('SCORE_NEEDS_MAX');
    });

    it('rejects a score above its paper total', () => {
      expect(
        codes(raw({
          openingRank: null, closingRank: null,
          closingScore: 400, maxScore: 390,
        })),
      ).toContain('SCORE_ABOVE_MAX');
    });

    it('rejects a score pair in the wrong order', () => {
      // Like percentiles, the closing score is the LOWER one.
      expect(
        codes(raw({
          openingRank: null, closingRank: null,
          openingScore: 280, closingScore: 308, maxScore: 390,
        })),
      ).toContain('SCORE_ORDER');
    });
  });

  describe('round number', () => {
    it.each([0, 21, 1.5])('rejects round %p', (roundNo) => {
      expect(codes(raw({ roundNo }))).toContain('BAD_ROUND');
    });
  });
});
