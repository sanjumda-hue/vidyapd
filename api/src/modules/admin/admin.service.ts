import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Import review, approval and data administration. */
@Injectable()
export class AdminService {
  constructor(protected readonly prisma: PrismaService) {}
}
