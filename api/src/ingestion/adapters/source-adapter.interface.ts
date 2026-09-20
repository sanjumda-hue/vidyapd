/**
 * One adapter per counselling authority.
 *
 * The design doc is explicit about this: a single shared scraper would break
 * the entire product the first time one portal changes its markup. Each
 * authority gets its own class, registered under `key`, and a failure is
 * contained to that authority's data.
 *
 * An adapter NEVER writes to a live table. It returns raw rows; the pipeline
 * normalises, validates and stages them, and only an approved import job
 * publishes.
 */

export type IngestionDataType =
  | 'cutoff'
  | 'seat_matrix'
  | 'schedule'
  | 'college'
  | 'fees'
  | 'placement'
  | 'percentile_rank';

export interface FetchContext {
  sourceId: number;
  importJobId: bigint;
  academicYear: number;
  /** Set when re-running a single round instead of a full year. */
  roundNo?: number;
  /** Hash of the last successful fetch; return `unchanged` to skip parsing. */
  lastContentHash?: string | null;
}

export interface FetchResult {
  unchanged: boolean;
  contentHash?: string;
  /** Where the artifact was archived, so a parser fix can be replayed offline. */
  artifactPath?: string;
  artifactUrl?: string;
}

/** A cutoff row exactly as printed by the authority. No ids resolved yet. */
export interface RawCutoffRow {
  instituteName: string;
  instituteCode?: string;
  programName: string;
  /** Authority's own labels; mapped through counselling_dimension_map. */
  seatTypeLabel: string;
  quotaLabel: string;
  genderLabel: string;
  roundNo: number;
  openingRank?: number | null;
  closingRank?: number | null;
  openingPercentile?: number | null;
  closingPercentile?: number | null;
  /** Marks-based exams (BITSAT) publish a score rather than a rank. */
  openingScore?: number | null;
  closingScore?: number | null;
  /** The paper total, which changed from 450 to 390 in 2022. */
  maxScore?: number | null;
  /**
   * True when either rank carried a trailing "P". Preparatory-course seats are
   * ranked on their own list, so these must not be mixed into the main trend.
   */
  isPreparatory?: boolean;
  /** Everything else the source gave us, kept for the staging `raw` column. */
  extra?: Record<string, unknown>;
}

export interface RawScheduleRow {
  eventType: string;
  eventName: string;
  startDate?: string | null;
  endDate?: string | null;
  isTentative: boolean;
  notes?: string | null;
}

export interface SourceAdapter {
  /** Matches data_sources.adapter_key. */
  readonly key: string;
  readonly authorityCode: string;
  readonly supports: IngestionDataType[];

  /** Download and archive. Must respect the per-host rate limit. */
  fetch(ctx: FetchContext): Promise<FetchResult>;

  parseCutoffs?(ctx: FetchContext, artifactPath: string): AsyncIterable<RawCutoffRow>;
  parseSchedule?(ctx: FetchContext, artifactPath: string): Promise<RawScheduleRow[]>;
}
