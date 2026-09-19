import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Branch and specialization master. */
@Injectable()
export class BranchesService {
  constructor(protected readonly prisma: PrismaService) {}
}
