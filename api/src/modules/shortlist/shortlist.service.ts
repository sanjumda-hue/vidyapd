import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** A student saved list of programs. */
@Injectable()
export class ShortlistService {
  constructor(protected readonly prisma: PrismaService) {}
}
