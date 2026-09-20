import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';

import { PrismaService } from '../../database/prisma.service';
import { LoginDto, RegisterDto } from './dto/auth.dto';

export interface AuthUser {
  id: string;
  uuid: string;
  email: string | null;
  fullName: string | null;
  role: string;
}

/** Registration, login and JWT issuance. */
@Injectable()
export class AuthService {
  private static readonly SALT_ROUNDS = 12;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto): Promise<{ token: string; user: AuthUser }> {
    const existing = await this.prisma.users.findFirst({
      where: { email: dto.email },
      select: { id: true },
    });
    if (existing) throw new ConflictException('An account with that email already exists.');

    const user = await this.prisma.users.create({
      data: {
        email: dto.email,
        password_hash: await bcrypt.hash(dto.password, AuthService.SALT_ROUNDS),
        full_name: dto.fullName,
        role: 'student',
      },
      select: { id: true, uuid: true, email: true, full_name: true, role: true },
    });
    return this.issue(user);
  }

  async login(dto: LoginDto): Promise<{ token: string; user: AuthUser }> {
    const user = await this.prisma.users.findFirst({
      where: { email: dto.email, is_active: true },
      select: { id: true, uuid: true, email: true, full_name: true, role: true, password_hash: true },
    });

    // One message for "no such account" and "wrong password", so the endpoint
    // cannot be used to discover which emails are registered.
    const invalid = new UnauthorizedException('Email or password is incorrect.');
    if (!user?.password_hash) throw invalid;
    if (!(await bcrypt.compare(dto.password, user.password_hash))) throw invalid;

    await this.prisma.users.update({
      where: { id: user.id },
      data: { last_login_at: new Date() },
    });
    return this.issue(user);
  }

  async me(userId: bigint): Promise<AuthUser> {
    const user = await this.prisma.users.findUniqueOrThrow({
      where: { id: userId },
      select: { id: true, uuid: true, email: true, full_name: true, role: true },
    });
    return this.toAuthUser(user);
  }

  private issue(user: {
    id: bigint; uuid: string; email: string | null; full_name: string | null; role: string;
  }): { token: string; user: AuthUser } {
    return {
      token: this.jwt.sign({ sub: user.id.toString(), role: user.role }),
      user: this.toAuthUser(user),
    };
  }

  private toAuthUser(user: {
    id: bigint; uuid: string; email: string | null; full_name: string | null; role: string;
  }): AuthUser {
    return {
      id: user.id.toString(),
      uuid: user.uuid,
      email: user.email,
      fullName: user.full_name,
      role: user.role,
    };
  }
}
