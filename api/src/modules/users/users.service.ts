import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Account and student profile. */
@Injectable()
export class UsersService {
  constructor(protected readonly prisma: PrismaService) {}
}
