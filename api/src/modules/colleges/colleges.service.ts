import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** College search, detail and programs. */
@Injectable()
export class CollegesService {
  constructor(protected readonly prisma: PrismaService) {}
}
