import { Injectable } from '@nestjs/common';

import { RawCutoffRow } from '../adapters/source-adapter.interface';

export interface ValidationError {
  code: string;
  field: string;
  message: string;
}

export interface NormalizedCutoffRow {
  collegeId: number;
  collegeBranchId: bigint;
  branchId: number;
  seatTypeId: number;
  quotaId: number;
  genderId: number;
  roundNo: number;
  openingRank: number | null;
  closingRank: number | null;
  openingPercentile: number | null;
  closingPercentile: number | null;
  openingScore: number | null;
  closingScore: number | null;
  maxScore: number | null;
  isPreparatory: boolean;
}

/**
 * Design doc section 25. Every rule here has a failure mode behind it:
 *
 *  - opening > closing  usually means the two columns were swapped by a layout
 *                       change, which would silently invert every prediction.
 *  - absurd ranks       catch a footnote or page number parsed as a rank.
 *  - unresolved labels  are NOT guessed at. An unmapped seat type means a new
 *                       category exists that nobody has reviewed yet.
 */
@Injectable()
export class CutoffValidator {
  /** No Indian entrance exam has ever had this many candidates. */
  private static readonly MAX_PLAUSIBLE_RANK = 5_000_000;

  validate(
    raw: RawCutoffRow,
    resolved: Partial<NormalizedCutoffRow>,
  ): ValidationError[] {
    const errors: ValidationError[] = [];

    if (!resolved.collegeId) {
      errors.push({
        code: 'UNRESOLVED_COLLEGE',
        field: 'instituteName',
        message: `Could not match institute "${raw.instituteName}" to a college.`,
      });
    }

    if (!resolved.collegeBranchId) {
      errors.push({
        code: 'UNRESOLVED_PROGRAM',
        field: 'programName',
        message: `Could not match program "${raw.programName}" at "${raw.instituteName}".`,
      });
    }

    for (const [key, label, field] of [
      ['seatTypeId', raw.seatTypeLabel, 'seatTypeLabel'],
      ['quotaId', raw.quotaLabel, 'quotaLabel'],
      ['genderId', raw.genderLabel, 'genderLabel'],
    ] as const) {
      if (!resolved[key]) {
        errors.push({
          code: 'UNRESOLVED_DIMENSION',
          field,
          message: `"${label}" is not mapped in counselling_dimension_map. Add the mapping, then re-run.`,
        });
      }
    }

    if (!Number.isInteger(raw.roundNo) || raw.roundNo < 1 || raw.roundNo > 20) {
      errors.push({
        code: 'BAD_ROUND',
        field: 'roundNo',
        message: `Round number ${raw.roundNo} is out of range.`,
      });
    }

    const hasRank = raw.openingRank != null || raw.closingRank != null;
    const hasPercentile = raw.openingPercentile != null || raw.closingPercentile != null;
    const hasScore = raw.openingScore != null || raw.closingScore != null;
    if (!hasRank && !hasPercentile && !hasScore) {
      errors.push({
        code: 'NO_MEASURE',
        field: 'closingRank',
        message: 'Row has no rank, percentile or score.',
      });
    }

    for (const [field, value] of [
      ['openingRank', raw.openingRank],
      ['closingRank', raw.closingRank],
    ] as const) {
      if (value == null) continue;
      if (!Number.isInteger(value) || value < 1) {
        errors.push({ code: 'BAD_RANK', field, message: `${field}=${value} is not a positive integer.` });
      } else if (value > CutoffValidator.MAX_PLAUSIBLE_RANK) {
        errors.push({
          code: 'IMPLAUSIBLE_RANK',
          field,
          message: `${field}=${value} exceeds the plausible maximum; the column was probably misread.`,
        });
      }
    }

    if (
      !raw.isPreparatory &&
      raw.openingRank != null &&
      raw.closingRank != null &&
      raw.openingRank > raw.closingRank
    ) {
      errors.push({
        code: 'RANK_ORDER',
        field: 'openingRank',
        message: `Opening rank ${raw.openingRank} is worse than closing rank ${raw.closingRank}; columns may be swapped.`,
      });
    }

    // Percentiles run the other way round: closing is the LOWER percentile.
    if (
      raw.openingPercentile != null &&
      raw.closingPercentile != null &&
      raw.openingPercentile < raw.closingPercentile
    ) {
      errors.push({
        code: 'PERCENTILE_ORDER',
        field: 'openingPercentile',
        message: `Opening percentile ${raw.openingPercentile} is below closing ${raw.closingPercentile}.`,
      });
    }

    // Scores mirror the rank rules, and mirror the CHECK constraints added in
    // 021_cutoff_score_measure.sql. Duplicating them here is the point: the
    // database aborts the whole batched INSERT on a violation, so a single bad
    // row would fail an entire round's import. Caught here it is parked as one
    // invalid row and the other 400 publish.
    for (const [field, value] of [
      ['openingScore', raw.openingScore],
      ['closingScore', raw.closingScore],
    ] as const) {
      if (value != null && !(value > 0)) {
        errors.push({ code: 'BAD_SCORE', field, message: `${field}=${value} is not a positive score.` });
      }
    }

    if (raw.closingScore != null && raw.maxScore == null) {
      errors.push({
        code: 'SCORE_NEEDS_MAX',
        field: 'maxScore',
        message:
          'A score needs the paper total it is out of; without it the row cannot be compared across years.',
      });
    }

    if (raw.maxScore != null) {
      for (const [field, value] of [
        ['openingScore', raw.openingScore],
        ['closingScore', raw.closingScore],
      ] as const) {
        if (value != null && value > raw.maxScore) {
          errors.push({
            code: 'SCORE_ABOVE_MAX',
            field,
            message: `${field}=${value} is above the paper total of ${raw.maxScore}.`,
          });
        }
      }
    }

    // Like a percentile, the closing score is the LOWER of the pair.
    if (
      raw.openingScore != null &&
      raw.closingScore != null &&
      raw.openingScore < raw.closingScore
    ) {
      errors.push({
        code: 'SCORE_ORDER',
        field: 'openingScore',
        message: `Opening score ${raw.openingScore} is below closing ${raw.closingScore}; columns may be swapped.`,
      });
    }

    return errors;
  }
}
