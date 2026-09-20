export type MatchGrade =
  | 'strong_historical_match'
  | 'historical_match'
  | 'borderline'
  | 'outside_historical_range';

/**
 * Which measure the engine compared on.
 *
 * Almost every authority allots on a rank. BITS allots on a BITSAT score, and
 * the two run in opposite directions, so a client cannot tell from the numbers
 * alone which way "better" points. This says so explicitly.
 */
export type PredictionMeasure = 'rank' | 'score';

interface PredictionRowBase {
  college_branch_id: string;
  college_id: number;
  branch_id: number;
  counselling_authority_id: number;
  seat_type_id: number;
  quota_id: number;
  gender_id: number;
  grade: MatchGrade;
  score: string;
  years_available: number;
  trend_slope: string | null;
}

/** Raw shape returned by fn_predict_colleges(). Column names are snake_case. */
export interface PredictionRow extends PredictionRowBase {
  weighted_closing_rank: string | null;
  best_closing_rank: string | null;
  worst_closing_rank: string | null;
  latest_closing_rank: string | null;
  rank_margin: string | null;
  cutoff_history: Record<string, { opening: number | null; closing: number; round: number }>;
}

/** Raw shape returned by fn_predict_colleges_by_score(). */
export interface PredictionScoreRow extends PredictionRowBase {
  weighted_closing_score: string | null;
  toughest_closing_score: string | null;
  easiest_closing_score: string | null;
  latest_closing_score: string | null;
  max_score: string | null;
  score_margin: string | null;
  cutoff_history: Record<
    string,
    { opening: number | null; closing: number; max: number; pct: number; round: number }
  >;
}

export type AnyPredictionRow = PredictionRow | PredictionScoreRow;

export function isScoreRow(row: AnyPredictionRow): row is PredictionScoreRow {
  return 'weighted_closing_score' in row;
}

/**
 * The cut-off figures for a marks-based programme, all out of the candidate's
 * own paper total so they can be printed beside the score they entered.
 */
export interface ScoreBand {
  weightedClosing: number | null;
  /** Strictest year on record: the HIGHEST cut-off. */
  toughestClosing: number | null;
  /** Most lenient year: the LOWEST cut-off. */
  easiestClosing: number | null;
  latestClosing: number | null;
  maxScore: number | null;
  /** Candidate score minus the weighted cut-off. Positive = ahead of it. */
  margin: number | null;
}

export interface PredictionMatch {
  collegeBranchId: number;
  college: { id: number; name: string; shortName: string | null; type: string; state: string };
  branch: { id: number; code: string; name: string };
  programName: string;
  seatType: string;
  quota: string;
  genderPool: string;
  grade: MatchGrade;
  /** Plain-language label. Never the words "guaranteed" or "sure". */
  gradeLabel: string;
  score: number;
  /** Rank fields are null on a marks-based exam; read scoreBand instead. */
  weightedClosingRank: number | null;
  bestClosingRank: number | null;
  worstClosingRank: number | null;
  latestClosingRank: number | null;
  rankMargin: number | null;
  /** Null on a rank-based exam. */
  scoreBand: ScoreBand | null;
  yearsAvailable: number;
  trend: 'tightening' | 'loosening' | 'stable' | 'unknown';
  /**
   * `max` and `pct` are present only on marks-based exams, where a raw cut-off
   * means nothing without the total it was out of: BITSAT went from 450 to 390
   * in 2022, so 306 and 226 are the same standard.
   */
  cutoffHistory: Array<{
    year: number;
    opening: number | null;
    closing: number;
    round: number;
    max?: number;
    pct?: number;
  }>;
}

export interface PredictionResponse {
  requestId: string;
  exam: { code: string; name: string };
  academicYear: number;
  /** Which measure this run compared on. Decides whether to read ranks or scores. */
  measure: PredictionMeasure;
  /** Null when the exam is marks-based. */
  rankUsed: number | null;
  /** True when the student gave a percentile and we converted it. */
  rankIsEstimated: boolean;
  rankEstimateMethod?: string;
  /** Both null unless the exam is marks-based. */
  scoreUsed: number | null;
  maxScoreUsed: number | null;
  category: string;
  gender: string;
  homeState: string | null;
  counts: Record<MatchGrade, number>;
  matches: PredictionMatch[];
  /** Shown verbatim in the app under every result list. */
  disclaimer: string;
}

/** One hypothetical run of a what-if sweep. `rank` and `score` are exclusive. */
export interface WhatIfScenario {
  rank: number | null;
  score: number | null;
  counts: Record<MatchGrade, number>;
  topMatches: PredictionMatch[];
}
