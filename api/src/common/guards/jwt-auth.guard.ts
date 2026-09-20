import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

export const IS_PUBLIC_KEY = 'isPublic';

export interface RequestUser {
  id: bigint;
  role: string;
}

declare module 'express' {
  interface Request {
    user?: RequestUser;
  }
}

/**
 * Reads the bearer token and attaches the user, or rejects.
 *
 * Applied per controller rather than globally: most of this API is deliberately
 * open (a student can predict without signing in), and only the endpoints that
 * store something personal need a user.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Sign in to use this.');
    }
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string; role: string }>(
        header.slice(7),
      );
      req.user = { id: BigInt(payload.sub), role: payload.role };
      return true;
    } catch {
      throw new UnauthorizedException('Your session has expired. Sign in again.');
    }
  }
}
