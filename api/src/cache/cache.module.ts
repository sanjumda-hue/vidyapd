import { CacheModuleOptions, CacheModule as NestCacheModule } from '@nestjs/cache-manager';
import { Global, Logger, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { redisInsStore } from 'cache-manager-ioredis-yet';
import Redis from 'ioredis';

/**
 * Redis is optional.
 *
 * Leave REDIS_URL empty and the app falls back to cache-manager's in-memory
 * store. That matters on Windows, where there is no official Redis build, and
 * it means a developer can run the API with nothing but PostgreSQL.
 *
 * In production REDIS_URL should always be set: the in-memory store is
 * per-process, so it neither survives a restart nor is shared across instances.
 */
@Global()
@Module({
  imports: [
    NestCacheModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService): CacheModuleOptions => {
        const logger = new Logger('CacheModule');
        const url = config.get<string>('redis.url');
        const ttl = config.get<number>('redis.ttlSeconds', 300) * 1000;

        if (!url) {
          logger.warn('REDIS_URL is not set - using in-memory cache (single process only).');
          return { ttl };
        }

        // ioredis throws on an unhandled 'error' event, which would take the
        // whole process down every time Redis blips. Log and let it reconnect.
        const client = new Redis(url, { maxRetriesPerRequest: 3 });
        client.on('error', (err) => logger.error(`Redis: ${err.message}`));

        return { store: redisInsStore(client, { ttl }) };
      },
      isGlobal: true,
    }),
  ],
})
export class CacheModule {}
