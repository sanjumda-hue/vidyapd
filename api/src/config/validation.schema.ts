import * as Joi from 'joi';

// Fail at boot, not at the first request, if the environment is incomplete.
export const validationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().default(3000),
  API_PREFIX: Joi.string().default('api'),
  CORS_ORIGINS: Joi.string().allow('').default(''),

  DATABASE_URL: Joi.string().uri({ scheme: ['postgresql', 'postgres'] }).required(),
  DB_POOL_MAX: Joi.number().default(20),

  // Empty is allowed: the app falls back to an in-memory cache.
  REDIS_URL: Joi.string().allow('').default(''),
  CACHE_TTL_SECONDS: Joi.number().default(300),

  JWT_SECRET: Joi.string().min(16).required(),
  JWT_EXPIRES_IN: Joi.string().default('7d'),

  INGESTION_ENABLED: Joi.boolean().default(false),
  INGESTION_USER_AGENT: Joi.string().default('BTechAdmissionPredictor/0.1'),
  INGESTION_MIN_REQUEST_INTERVAL_MS: Joi.number().min(0).default(2000),
  INGESTION_ARTIFACT_DIR: Joi.string().default('./storage/artifacts'),
});
