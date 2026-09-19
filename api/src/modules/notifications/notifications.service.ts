import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** In-app inbox and reminder subscriptions. */
@Injectable()
export class NotificationsService {
  constructor(protected readonly prisma: PrismaService) {}
}
