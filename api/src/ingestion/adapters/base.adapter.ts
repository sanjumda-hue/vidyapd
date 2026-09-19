import { createHash } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';

import { Logger } from '@nestjs/common';

import { FetchContext, IngestionDataType, SourceAdapter } from './source-adapter.interface';

/**
 * Shared plumbing: polite fetching, content hashing and artifact archiving.
 *
 * The rate limiter is per HOST and process-wide. These are public education
 * portals run on modest infrastructure; hammering them is both rude and the
 * fastest way to get the IP blocked, which takes the whole product down.
 */
export abstract class BaseAdapter implements SourceAdapter {
  protected readonly logger = new Logger(this.constructor.name);

  abstract readonly key: string;
  abstract readonly authorityCode: string;
  abstract readonly supports: IngestionDataType[];

  private static readonly lastRequestByHost = new Map<string, number>();

  protected constructor(
    protected readonly userAgent: string,
    protected readonly minRequestIntervalMs: number,
    protected readonly artifactDir: string,
  ) {}

  abstract fetch(ctx: FetchContext): Promise<import('./source-adapter.interface').FetchResult>;

  /** Wait out the per-host cooldown, then fetch. */
  protected async politeFetch(url: string, init?: RequestInit): Promise<Response> {
    const host = new URL(url).host;
    const last = BaseAdapter.lastRequestByHost.get(host) ?? 0;
    const wait = this.minRequestIntervalMs - (Date.now() - last);
    if (wait > 0) {
      await new Promise((resolve) => setTimeout(resolve, wait));
    }
    BaseAdapter.lastRequestByHost.set(host, Date.now());

    const response = await fetch(url, {
      ...init,
      headers: { 'User-Agent': this.userAgent, ...(init?.headers ?? {}) },
    });

    if (!response.ok) {
      throw new Error(`${this.key}: ${url} returned ${response.status} ${response.statusText}`);
    }
    return response;
  }

  protected hash(buffer: Buffer): string {
    return createHash('sha256').update(buffer).digest('hex');
  }

  /**
   * Keep the exact bytes we parsed. When a parser bug surfaces three months
   * later the original PDF is usually gone from the portal, and without the
   * archive the only fix is re-typing the data by hand.
   */
  protected async archive(ctx: FetchContext, filename: string, buffer: Buffer): Promise<string> {
    const path = join(
      this.artifactDir,
      this.key,
      String(ctx.academicYear),
      String(ctx.importJobId),
      filename,
    );
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, buffer);
    this.logger.debug(`archived ${path} (${buffer.byteLength} bytes)`);
    return path;
  }
}
