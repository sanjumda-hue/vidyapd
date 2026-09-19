import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Counselling authorities, processes and rounds. */
@Injectable()
export class CounsellingService {
  constructor(protected readonly prisma: PrismaService) {}
}
