import { ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';

import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  const config = app.get(ConfigService);

  const isProduction = config.get<string>('nodeEnv') === 'production';
  const corsOrigins = config.get<string[]>('cors.origins') ?? [];
  // `flutter run -d chrome` picks a random port on every launch, so pinning the
  // dev origin list is a guaranteed CORS failure. Development trusts any
  // loopback origin; production stays restricted to CORS_ORIGINS.
  const isLoopback = (origin: string): boolean => {
    try {
      const { protocol, hostname } = new URL(origin);
      return (
        (protocol === 'http:' || protocol === 'https:') &&
        (hostname === 'localhost' || hostname === '127.0.0.1')
      );
    } catch {
      return false;
    }
  };

  app.use(helmet());
  app.enableCors({
    origin: isProduction
      ? corsOrigins
      : (origin, callback) =>
          !origin || corsOrigins.includes(origin) || isLoopback(origin)
            ? callback(null, true)
            : callback(new Error(`Origin ${origin} is not allowed by CORS`)),
    credentials: true,
  });
  app.setGlobalPrefix(config.get<string>('apiPrefix', 'api'));
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new TransformInterceptor());
  app.enableShutdownHooks();

  if (!isProduction) {
    const swagger = new DocumentBuilder()
      .setTitle('B.Tech Admission Predictor API')
      .setDescription('Exams, colleges, historical cutoffs and the prediction engine.')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, swagger));
  }

  await app.listen(config.get<number>('port', 3000));
}

void bootstrap();
