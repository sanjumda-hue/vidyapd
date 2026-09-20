import { readFileSync } from 'node:fs';
import { extname } from 'node:path';

import { Injectable, Logger } from '@nestjs/common';
import * as XLSX from 'xlsx';

import { RawCutoffRow } from '../adapters/source-adapter.interface';

export interface ParsedFile {
  rows: RawCutoffRow[];
  /** Header labels exactly as they appeared, for the review screen. */
  sourceHeaders: string[];
  skipped: number;
}

/**
 * Reads a JoSAA-shaped cutoff export (CSV or XLSX) into raw rows.
 *
 * This exists because scraping is the slow path. An authority's own download,
 * saved by hand once, gets real data into the database today; the adapter can
 * replace it later without anything downstream changing -- both produce the
 * same RawCutoffRow.
 *
 * Header matching is deliberately loose. The same column is printed as
 * "Closing Rank", "CLOSING RANK" and "Closing  Rank" across years, and a strict
 * match would fail the import for a cosmetic reason.
 */
@Injectable()
export class TabularParser {
  private readonly logger = new Logger(TabularParser.name);

  /** Candidate header labels per field, normalised, first match wins. */
  private static readonly COLUMNS: Record<string, string[]> = {
    instituteName: ['institute', 'institute name', 'college', 'college name'],
    instituteCode: ['institute code', 'institute id', 'college code'],
    programName: [
      'academic program name', 'academic programme name', 'program name',
      'programme name', 'branch', 'branch name', 'course', 'course name',
    ],
    quotaLabel: ['quota'],
    seatTypeLabel: ['seat type', 'category', 'seat category'],
    genderLabel: ['gender', 'gender pool'],
    roundNo: ['round', 'round no', 'round number'],
    openingRank: ['opening rank', 'or', 'open rank'],
    closingRank: ['closing rank', 'cr', 'close rank'],
    openingPercentile: ['opening percentile'],
    closingPercentile: ['closing percentile'],
    // BITS admits on marks, not a rank, so its feed carries a score instead.
    openingScore: ['opening score', 'opening marks'],
    closingScore: ['closing score', 'closing marks', 'cut off score', 'cutoff score'],
    maxScore: ['max marks', 'maximum marks', 'bitsat maximum marks'],
  };

  private static norm(s: string): string {
    return s.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  }

  parse(filePath: string, defaults: { roundNo?: number } = {}): ParsedFile {
    const ext = extname(filePath).toLowerCase();
    const book =
      ext === '.csv' || ext === '.txt'
        ? XLSX.read(readFileSync(filePath, 'utf8'), { type: 'string', raw: true })
        : XLSX.read(readFileSync(filePath), { type: 'buffer' });

    const sheet = book.Sheets[book.SheetNames[0]];
    const table = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, { defval: null });

    if (table.length === 0) {
      return { rows: [], sourceHeaders: [], skipped: 0 };
    }

    const sourceHeaders = Object.keys(table[0]);
    const map = this.mapHeaders(sourceHeaders);

    const missing = ['instituteName', 'programName', 'seatTypeLabel', 'quotaLabel', 'genderLabel']
      .filter((k) => !map[k]);
    if (missing.length > 0) {
      throw new Error(
        `Could not find columns for: ${missing.join(', ')}. ` +
          `Headers present: ${sourceHeaders.join(' | ')}`,
      );
    }

    const rows: RawCutoffRow[] = [];
    let skipped = 0;

    for (const record of table) {
      const pick = (k: string) => (map[k] ? record[map[k]] : null);
      const instituteName = this.str(pick('instituteName'));
      const programName = this.str(pick('programName'));

      // Authority exports carry blank spacer rows and repeated header rows.
      if (!instituteName || !programName) {
        skipped += 1;
        continue;
      }

      rows.push({
        instituteName,
        instituteCode: this.str(pick('instituteCode')) || undefined,
        programName,
        seatTypeLabel: this.str(pick('seatTypeLabel')),
        quotaLabel: this.str(pick('quotaLabel')),
        genderLabel: this.str(pick('genderLabel')),
        roundNo: this.int(pick('roundNo')) ?? defaults.roundNo ?? 1,
        openingRank: this.int(pick('openingRank')),
        closingRank: this.int(pick('closingRank')),
        isPreparatory: this.isPrep(pick('openingRank')) || this.isPrep(pick('closingRank')),
        openingPercentile: this.num(pick('openingPercentile')),
        closingPercentile: this.num(pick('closingPercentile')),
        openingScore: this.num(pick('openingScore')),
        closingScore: this.num(pick('closingScore')),
        maxScore: this.num(pick('maxScore')),
        extra: record as Record<string, unknown>,
      });
    }

    this.logger.log(`parsed ${rows.length} rows from ${filePath} (${skipped} skipped)`);
    return { rows, sourceHeaders, skipped };
  }

  private mapHeaders(headers: string[]): Record<string, string> {
    const map: Record<string, string> = {};
    for (const [field, candidates] of Object.entries(TabularParser.COLUMNS)) {
      const hit = headers.find((h) => candidates.includes(TabularParser.norm(h)));
      if (hit) map[field] = hit;
    }
    return map;
  }

  private str(v: unknown): string {
    return v == null ? '' : String(v).replace(/\s+/g, ' ').trim();
  }

  /**
   * Parse a rank cell.
   *
   * The source is messier than it looks:
   *   "4102"       plain
   *   "1173808.0"  decimal. Stripping non-digits turned this into 11738080 --
   *                a silent 10x corruption. Only the implausible-rank check
   *                caught it; "45821.0" would have become 458210 and passed.
   *   "1.0218e+006" scientific notation, which CSAB emits for seven-figure
   *                ranks. Reading only the leading digits gave 1, turning a
   *                closing rank of 1,021,800 into 1.
   *   "109P"       preparatory-course rank, a different series (see isPrep)
   *   "--" / "NA"  unfilled seat
   */
  private int(v: unknown): number | null {
    if (v == null) return null;
    const s = String(v).replace(/[,\s]/g, '');
    const m = /^(\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/.exec(s);
    if (!m) return null;
    const n = Math.round(Number.parseFloat(m[1]));
    return Number.isFinite(n) && n > 0 ? n : null;
  }

  /**
   * A trailing P marks a preparatory-course rank. Those are ranked on a
   * separate list from the main one, so a preparatory closing rank must never
   * be compared against a regular opening rank.
   */
  private isPrep(v: unknown): boolean {
    return v != null && /\d\s*P\s*$/i.test(String(v));
  }

  private num(v: unknown): number | null {
    if (v == null) return null;
    const n = Number.parseFloat(String(v).replace(/[^0-9.]/g, ''));
    return Number.isFinite(n) ? n : null;
  }
}
