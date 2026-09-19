import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { BaseAdapter } from './base.adapter';
import {
  FetchContext,
  FetchResult,
  IngestionDataType,
  RawCutoffRow,
} from './source-adapter.interface';

/**
 * JoSAA opening/closing rank adapter.
 *
 * The OR-CR portal is a server-rendered form: you pick year, round, institute
 * type, program and seat type, then it renders an HTML table. There is no API,
 * so this adapter drives the form and reads the table.
 *
 * STATUS: skeleton. fetch() and the row reader below are wired end to end but
 * the selectors are placeholders -- they must be filled in against the live
 * page before this adapter is enabled. Until then the source row for JoSAA
 * should stay is_active = false.
 */
@Injectable()
export class JosaaAdapter extends BaseAdapter {
  readonly key = 'josaa';
  readonly authorityCode = 'JOSAA';
  readonly supports: IngestionDataType[] = ['cutoff', 'seat_matrix', 'schedule'];

  private static readonly ORCR_URL = 'https://josaa.nic.in/or-cr/';

  constructor(config: ConfigService) {
    super(
      config.get<string>('ingestion.userAgent', 'BTechAdmissionPredictor/0.1'),
      config.get<number>('ingestion.minRequestIntervalMs', 2000),
      config.get<string>('ingestion.artifactDir', './storage/artifacts'),
    );
  }

  async fetch(ctx: FetchContext): Promise<FetchResult> {
    const response = await this.politeFetch(JosaaAdapter.ORCR_URL);
    const buffer = Buffer.from(await response.arrayBuffer());
    const contentHash = this.hash(buffer);

    // Identical bytes mean nothing was republished. Skip the parse entirely --
    // this is what keeps a 6-hourly poll cheap.
    if (contentHash === ctx.lastContentHash) {
      return { unchanged: true, contentHash };
    }

    const artifactPath = await this.archive(ctx, `orcr-${ctx.roundNo ?? 'all'}.html`, buffer);
    return {
      unchanged: false,
      contentHash,
      artifactPath,
      artifactUrl: JosaaAdapter.ORCR_URL,
    };
  }

  /**
   * Yields rows one at a time rather than returning an array: a full JoSAA year
   * across all rounds is well over a million rows and must never be held in
   * memory at once.
   */
  async *parseCutoffs(_ctx: FetchContext, _artifactPath: string): AsyncIterable<RawCutoffRow> {
    throw new Error(
      'JosaaAdapter.parseCutoffs is not implemented yet. ' +
        'Fill in the OR-CR table selectors, then enable the josaa data_source.',
    );
    // Shape the pipeline expects, for reference:
    // yield {
    //   instituteName: 'Indian Institute of Technology Bombay',
    //   programName: 'Computer Science and Engineering (4 Years, Bachelor of Technology)',
    //   seatTypeLabel: 'OBC-NCL',
    //   quotaLabel: 'AI',
    //   genderLabel: 'Gender-Neutral',
    //   roundNo: 5,
    //   openingRank: 2500,
    //   closingRank: 4200,
    // };
  }
}
