import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';

import { PrismaService } from '../../database/prisma.service';
import { AdapterRegistry } from '../adapters/adapter.registry';

/**
 * Design doc section 23. Every six hours, ask each active source whether
 * anything changed. Nothing here publishes: a change creates a queued
 * data_import_job, and an admin approves it (unless the source is tier-1 and
 * explicitly flagged auto_publish_allowed).
 */
@Injectable()
export class SourcePollerService implements OnModuleInit {
  private readonly logger = new Logger(SourcePollerService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly registry: AdapterRegistry,
    private readonly config: ConfigService,
  ) {}

  onModuleInit(): void {
    if (!this.config.get<boolean>('ingestion.enabled')) {
      this.logger.warn('Ingestion is disabled (INGESTION_ENABLED=false). No sources will be polled.');
    }
  }

  @Cron(CronExpression.EVERY_6_HOURS, { name: 'poll-data-sources' })
  async pollDueSources(): Promise<void> {
    if (!this.config.get<boolean>('ingestion.enabled')) return;

    const sources = await this.prisma.data_sources.findMany({
      where: { is_active: true },
      orderBy: { last_checked_at: { sort: 'asc', nulls: 'first' } },
    });

    for (const source of sources) {
      try {
        // Unknown adapter_key is a configuration error, not a transient one:
        // log it and move on rather than failing the whole sweep.
        this.registry.get(source.adapter_key);
      } catch {
        this.logger.error(`source ${source.code}: no adapter registered for "${source.adapter_key}"`);
        continue;
      }

      await this.prisma.data_import_jobs.create({
        data: {
          source_id: source.id,
          academic_year: new Date().getFullYear(),
          status: 'queued',
          trigger_kind: 'scheduler',
        },
      });
      this.logger.log(`queued import job for ${source.code}`);
    }
  }
}
