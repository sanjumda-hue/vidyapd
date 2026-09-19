export type MatchGrade =
  | 'strong_historical_match'
  | 'historical_match'
  | 'borderline'
  | 'outside_historical_range';

/** Raw shape returned by fn_predict_colleges(). Column names are snake_case. */
export interface PredictionRow {
  college_branch_id: string;
  college_id: number;
  branch_id: number;
  counselling_authority_id: number;
  seat_type_id: number;
  quota_id: number;
  gender_id: number;
  grade: MatchGrade;
  score: string;
  weighted_closing_rank: string | null;
  best_closing_rank: string | null;
  worst_closing_rank: string | null;
  latest_closing_rank: string | null;
  rank_margin: string | null;
  years_available: number;
  trend_slope: string | null;
  cutoff_history: Record<string, { opening: number | null; closing: number; round: number }>;
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
  weightedClosingRank: number | null;
  bestClosingRank: number | null;
  worstClosingRank: number | null;
  latestClosingRank: number | null;
  rankMargin: number | null;
  yearsAvailable: number;
  trend: 'tightening' | 'loosening' | 'stable' | 'unknown';
  cutoffHistory: Array<{ year: number; opening: number | null; closing: number; round: number }>;
}

export interface PredictionResponse {
  requestId: string;
  exam: { code: string; name: string };
  academicYear: number;
  rankUsed: number;
  /** True when the student gave a percentile and we converted it. */
  rankIsEstimated: boolean;
  rankEstimateMethod?: string;
  category: string;
  gender: string;
  homeState: string | null;
  counts: Record<MatchGrade, number>;
  matches: PredictionMatch[];
  /** Shown verbatim in the app under every result list. */
  disclaimer: string;
}
