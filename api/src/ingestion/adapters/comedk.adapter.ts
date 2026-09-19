import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { BaseAdapter } from './base.adapter';
import { FetchContext, FetchResult, IngestionDataType } from './source-adapter.interface';

/**
 * COMEDK publishes counselling schedules, seat matrix and cutoffs as PDFs and
 * spreadsheets linked from the counselling-details page, so this adapter is a
 * link crawler plus a PDF/xlsx parser rather than an HTML table reader.
 *
 * STATUS: skeleton. Document-link discovery is not implemented.
 */
@Injectable()
export class ComedkAdapter extends BaseAdapter {
  readonly key = 'comedk';
  readonly authorityCode = 'COMEDK';
  readonly supports: IngestionDataType[] = ['cutoff', 'seat_matrix', 'schedule', 'fees'];

  private static readonly COUNSELLING_URL = 'https://www.comedk.org/counselling-document-2026';

  constructor(config: ConfigService) {
    super(
      config.get<string>('ingestion.userAgent', 'BTechAdmissionPredictor/0.1'),
      config.get<number>('ingestion.minRequestIntervalMs', 2000),
      config.get<string>('ingestion.artifactDir', './storage/artifacts'),
    );
  }

  async fetch(ctx: FetchContext): Promise<FetchResult> {
    const response = await this.politeFetch(ComedkAdapter.COUNSELLING_URL);
    const buffer = Buffer.from(await response.arrayBuffer());
    const contentHash = this.hash(buffer);

    if (contentHash === ctx.lastContentHash) {
      return { unchanged: true, contentHash };
    }

    const artifactPath = await this.archive(ctx, 'counselling-index.html', buffer);
    return {
      unchanged: false,
      contentHash,
      artifactPath,
      artifactUrl: ComedkAdapter.COUNSELLING_URL,
    };
  }
}
