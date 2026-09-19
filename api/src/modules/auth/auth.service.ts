import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Login, registration and JWT issuance. */
@Injectable()
export class AuthService {
  constructor(protected readonly prisma: PrismaService) {}
}
