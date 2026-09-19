import { Module, OnModuleInit } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';

import { AdapterRegistry } from './adapters/adapter.registry';
import { ComedkAdapter } from './adapters/comedk.adapter';
import { JosaaAdapter } from './adapters/josaa.adapter';
import { CutoffValidator } from './pipeline/cutoff-validator';
import { SourcePollerService } from './scheduler/source-poller.service';

/**
 * Registering a new counselling authority: write the adapter, add it to
 * `ADAPTERS` below, and seed a data_sources row pointing at its key.
 */
const ADAPTERS = [JosaaAdapter, ComedkAdapter];

@Module({
  imports: [ConfigModule, ScheduleModule.forRoot()],
  providers: [AdapterRegistry, CutoffValidator, SourcePollerService, ...ADAPTERS],
  exports: [AdapterRegistry, CutoffValidator],
})
export class IngestionModule implements OnModuleInit {
  constructor(
    private readonly registry: AdapterRegistry,
    private readonly josaa: JosaaAdapter,
    private readonly comedk: ComedkAdapter,
  ) {}

  onModuleInit(): void {
    this.registry.register(this.josaa);
    this.registry.register(this.comedk);
  }
}
