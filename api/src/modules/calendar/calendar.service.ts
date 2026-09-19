import { Injectable } from '@nestjs/common';

import { PrismaService } from '../../database/prisma.service';

/** Month-grid calendar feed built on v_exam_calendar. */
@Injectable()
export class CalendarService {
  constructor(protected readonly prisma: PrismaService) {}
}
