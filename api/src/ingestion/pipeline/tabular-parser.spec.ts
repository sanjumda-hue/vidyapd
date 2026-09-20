import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { TabularParser } from './tabular-parser';

/**
 * Regression tests for the cutoff parser.
 *
 * Every case here is a bug that reached the database, or came within one
 * check of reaching it. None is hypothetical.
 */
describe('TabularParser', () => {
  let parser: TabularParser;
  let dir: string;

  beforeAll(() => {
    dir = mkdtempSync(join(tmpdir(), 'tabular-parser-'));
  });

  beforeEach(() => {
    parser = new TabularParser();
  });

  /** Write a CSV and parse it, returning the rows. */
  function parse(name: string, csv: string, defaults: { roundNo?: number } = {}) {
    const path = join(dir, `${name}.csv`);
    writeFileSync(path, csv, 'utf8');
    return parser.parse(path, defaults);
  }

  const RANK_HEADER =
    'Institute,Academic Program Name,Quota,Seat Type,Gender,Round,Opening Rank,Closing Rank';
  const row = (opening: string, closing: string) =>
    `NIT Trichy,Computer Science and Engineering,HS,OPEN,Gender-Neutral,5,${opening},${closing}`;

  describe('rank cells', () => {
    it('reads a plain integer', () => {
      const { rows } = parse('plain', `${RANK_HEADER}\n${row('1200', '4102')}`);
      expect(rows[0].openingRank).toBe(1200);
      expect(rows[0].closingRank).toBe(4102);
    });

    it('does not multiply a decimal rank by ten', () => {
      // "1173808.0" once became 11738080 because non-digits were stripped
      // before parsing. Only the implausible-rank check caught that one --
      // "45821.0" would have become 458210 and passed as a real rank.
      const { rows } = parse('decimal', `${RANK_HEADER}\n${row('45821.0', '1173808.0')}`);
      expect(rows[0].openingRank).toBe(45821);
      expect(rows[0].closingRank).toBe(1173808);
    });

    it('expands scientific notation', () => {
      // CSAB emits seven-figure ranks this way. Reading the leading digits
      // turned a closing rank of 1,021,800 into 1.
      const { rows } = parse('sci', `${RANK_HEADER}\n${row('9.9e+005', '1.0218e+006')}`);
      expect(rows[0].openingRank).toBe(990000);
      expect(rows[0].closingRank).toBe(1021800);
    });

    it('strips thousands separators', () => {
      const { rows } = parse('commas', `${RANK_HEADER}\n${row('"1,200"', '"11,73,808"')}`);
      expect(rows[0].openingRank).toBe(1200);
      expect(rows[0].closingRank).toBe(1173808);
    });

    it('returns null for an unfilled seat rather than zero', () => {
      // 0 would be the best possible rank. Null is "no data".
      const { rows } = parse('blank', `${RANK_HEADER}\n${row('--', 'NA')}`);
      expect(rows[0].openingRank).toBeNull();
      expect(rows[0].closingRank).toBeNull();
    });
  });

  describe('preparatory ranks', () => {
    it('flags a trailing P and keeps the number', () => {
      // Preparatory-course seats are ranked on a separate list. 2,834 of these
      // were imported as regular ranks, which put a preparatory closing rank of
      // 109 next to a general one and made the programme look unreachable.
      const { rows } = parse('prep', `${RANK_HEADER}\n${row('26P', '109P')}`);
      expect(rows[0].isPreparatory).toBe(true);
      expect(rows[0].openingRank).toBe(26);
      expect(rows[0].closingRank).toBe(109);
    });

    it('leaves a regular row unflagged', () => {
      const { rows } = parse('noprep', `${RANK_HEADER}\n${row('1200', '4102')}`);
      expect(rows[0].isPreparatory).toBe(false);
    });

    it('flags the row when only one of the two columns carries the marker', () => {
      const { rows } = parse('halfprep', `${RANK_HEADER}\n${row('26P', '109')}`);
      expect(rows[0].isPreparatory).toBe(true);
    });
  });

  describe('header matching', () => {
    it('ignores case, spacing and punctuation', () => {
      const { rows } = parse(
        'messy',
        'INSTITUTE,Academic  Program   Name,quota,SEAT_TYPE,Gender,Round,OPENING RANK,Closing  Rank\n' +
          'NIT Trichy,CSE,HS,OPEN,Gender-Neutral,5,1200,4102',
      );
      expect(rows).toHaveLength(1);
      expect(rows[0].instituteName).toBe('NIT Trichy');
      expect(rows[0].closingRank).toBe(4102);
    });

    it('names the missing columns when a required one is absent', () => {
      expect(() =>
        parse('missing', 'Institute,Round,Closing Rank\nNIT Trichy,5,4102'),
      ).toThrow(/Could not find columns for:.*programName/);
    });
  });

  describe('score cells', () => {
    const SCORE_HEADER =
      'Institute,Academic Program Name,Quota,Seat Type,Gender,Round,Closing Score,Max Marks';

    it('reads a BITSAT score with its paper total', () => {
      const { rows } = parse(
        'score',
        `${SCORE_HEADER}\n"BITS Pilani, Pilani Campus",B.E. Computer Science,AI,OPEN,Gender-Neutral,1,308,390`,
      );
      expect(rows[0].closingScore).toBe(308);
      expect(rows[0].maxScore).toBe(390);
      // A score feed has no ranks, and inventing one would put it on the wrong
      // engine entirely.
      expect(rows[0].closingRank).toBeNull();
      expect(rows[0].openingRank).toBeNull();
    });

    it('keeps the older 450 total distinct from the current 390', () => {
      const { rows } = parse(
        'score450',
        `${SCORE_HEADER}\n` +
          `"BITS Pilani, Pilani Campus",B.E. Computer Science,AI,OPEN,Gender-Neutral,1,306,450\n` +
          `"BITS Pilani, Pilani Campus",B.E. Chemical,AI,OPEN,Gender-Neutral,1,226,390`,
      );
      expect(rows.map((r) => [r.closingScore, r.maxScore])).toEqual([
        [306, 450],
        [226, 390],
      ]);
    });
  });

  describe('row skipping', () => {
    it('drops spacer and partial rows without failing the import', () => {
      const { rows, skipped } = parse(
        'spacers',
        `${RANK_HEADER}\n` +
          `${row('1200', '4102')}\n` +
          `,,,,,,,\n` +
          `NIT Trichy,,HS,OPEN,Gender-Neutral,5,1,2\n` +
          `${row('1300', '4500')}`,
      );
      expect(rows).toHaveLength(2);
      // One, not two. A wholly blank line never becomes a record -- the sheet
      // reader discards it before the parser sees it -- so only the row with a
      // missing programme is counted. `skipped` is what the review screen shows
      // as "rows the file contained but we did not import", so it tracks rows
      // the parser actually rejected, not whitespace in the file.
      expect(skipped).toBe(1);
    });
  });

  describe('round number', () => {
    it('prefers the column over the caller default', () => {
      const { rows } = parse('roundcol', `${RANK_HEADER}\n${row('1200', '4102')}`, { roundNo: 1 });
      expect(rows[0].roundNo).toBe(5);
    });

    it('falls back to the caller default when the feed has no round column', () => {
      // UPTAC carries the round in a column; BITS has none at all.
      const { rows } = parse(
        'noround',
        'Institute,Academic Program Name,Quota,Seat Type,Gender,Closing Rank\n' +
          'NIT Trichy,CSE,HS,OPEN,Gender-Neutral,4102',
        { roundNo: 3 },
      );
      expect(rows[0].roundNo).toBe(3);
    });
  });
});
