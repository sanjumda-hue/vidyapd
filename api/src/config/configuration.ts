export interface AppConfig {
  nodeEnv: string;
  port: number;
  apiPrefix: string;
  cors: { origins: string[] };
  database: { url: string; poolMax: number };
  redis: { url: string; ttlSeconds: number };
  jwt: { secret: string; expiresIn: string };
  ingestion: {
    enabled: boolean;
    userAgent: string;
    minRequestIntervalMs: number;
    artifactDir: string;
  };
}

export default (): AppConfig => ({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: parseInt(process.env.PORT ?? '3000', 10),
  apiPrefix: process.env.API_PREFIX ?? 'api',
  cors: {
    origins: (process.env.CORS_ORIGINS ?? '').split(',').filter(Boolean),
  },
  database: {
    url: process.env.DATABASE_URL as string,
    poolMax: parseInt(process.env.DB_POOL_MAX ?? '20', 10),
  },
  redis: {
    // Empty string means "no Redis"; CacheModule then uses memory.
    url: process.env.REDIS_URL ?? '',
    ttlSeconds: parseInt(process.env.CACHE_TTL_SECONDS ?? '300', 10),
  },
  jwt: {
    secret: process.env.JWT_SECRET as string,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  },
  ingestion: {
    enabled: process.env.INGESTION_ENABLED === 'true',
    userAgent: process.env.INGESTION_USER_AGENT ?? 'BTechAdmissionPredictor/0.1',
    minRequestIntervalMs: parseInt(process.env.INGESTION_MIN_REQUEST_INTERVAL_MS ?? '2000', 10),
    artifactDir: process.env.INGESTION_ARTIFACT_DIR ?? './storage/artifacts',
  },
});
