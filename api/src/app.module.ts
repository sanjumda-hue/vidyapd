import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

import { CacheModule } from './cache/cache.module';
import configuration from './config/configuration';
import { validationSchema } from './config/validation.schema';
import { PrismaModule } from './database/prisma.module';
import { IngestionModule } from './ingestion/ingestion.module';
import { AdminModule } from './modules/admin/admin.module';
import { AuthModule } from './modules/auth/auth.module';
import { BranchesModule } from './modules/branches/branches.module';
import { CalendarModule } from './modules/calendar/calendar.module';
import { CollegesModule } from './modules/colleges/colleges.module';
import { CompareModule } from './modules/compare/compare.module';
import { CounsellingModule } from './modules/counselling/counselling.module';
import { CutoffsModule } from './modules/cutoffs/cutoffs.module';
import { ExamsModule } from './modules/exams/exams.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { PredictionModule } from './modules/prediction/prediction.module';
import { ReferenceModule } from './modules/reference/reference.module';
import { ShortlistModule } from './modules/shortlist/shortlist.module';
import { UsersModule } from './modules/users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validationSchema,
      validationOptions: { abortEarly: false },
    }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    PrismaModule,
    CacheModule,

    AuthModule,
    UsersModule,
    ExamsModule,
    ReferenceModule,
    CalendarModule,
    CounsellingModule,
    CollegesModule,
    BranchesModule,
    CutoffsModule,
    PredictionModule,
    CompareModule,
    ShortlistModule,
    NotificationsModule,
    AdminModule,

    IngestionModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
