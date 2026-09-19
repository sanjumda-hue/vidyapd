import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Side-by-side college comparison. */
@Injectable()
export class CompareService {
  constructor(protected readonly prisma: PrismaService) {}
}
