import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * Prisma is the typed client for ordinary CRUD.
 *
 * The prediction path deliberately does NOT go through the Prisma query builder:
 * it calls fn_predict_colleges() with $queryRaw. The weighting, eligibility and
 * grading rules live in one place (SQL), and the API stays a thin caller.
 */
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit(): Promise<void> {
    await this.$connect();
    this.logger.log('Database connected');
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
