import { Injectable, Logger, NotFoundException } from '@nestjs/common';

import { SourceAdapter } from './source-adapter.interface';

/**
 * Resolves data_sources.adapter_key to a concrete adapter. Adding support for a
 * new state counselling means writing one class and registering it here; no
 * other file in the pipeline changes.
 */
@Injectable()
export class AdapterRegistry {
  private readonly logger = new Logger(AdapterRegistry.name);
  private readonly adapters = new Map<string, SourceAdapter>();

  register(adapter: SourceAdapter): void {
    if (this.adapters.has(adapter.key)) {
      throw new Error(`Duplicate adapter key: ${adapter.key}`);
    }
    this.adapters.set(adapter.key, adapter);
    this.logger.log(`registered adapter "${adapter.key}" (${adapter.supports.join(', ')})`);
  }

  get(key: string): SourceAdapter {
    const adapter = this.adapters.get(key);
    if (!adapter) {
      throw new NotFoundException(`No ingestion adapter registered for key "${key}"`);
    }
    return adapter;
  }

  keys(): string[] {
    return [...this.adapters.keys()];
  }
}
