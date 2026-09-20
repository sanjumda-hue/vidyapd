import { ExecutionContext, createParamDecorator } from '@nestjs/common';
import { Request } from 'express';

import { RequestUser } from '../guards/jwt-auth.guard';

/** The user attached by JwtAuthGuard. Only valid on guarded routes. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): RequestUser => {
    const req = ctx.switchToHttp().getRequest<Request>();
    if (!req.user) throw new Error('CurrentUser used on a route without JwtAuthGuard');
    return req.user;
  },
);
