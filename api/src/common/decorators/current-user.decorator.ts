import { ExecutionContext, createParamDecorator } from '@nestjs/common';
// A type-only import: express itself arrives through @nestjs/platform-express
// and is not a direct dependency, so nothing here should reach for it at runtime.
import type { Request } from 'express';

import { RequestUser } from '../guards/jwt-auth.guard';

/** The user attached by JwtAuthGuard. Only valid on guarded routes. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): RequestUser => {
    const req = ctx.switchToHttp().getRequest<Request>();
    if (!req.user) throw new Error('CurrentUser used on a route without JwtAuthGuard');
    return req.user;
  },
);
