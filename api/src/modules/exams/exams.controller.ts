import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { ExamsService } from './exams.service';

@ApiTags('exams')
@Controller('exams')
export class ExamsController {
  constructor(protected readonly exams: ExamsService) {}

  @Get()
  @ApiOperation({ summary: 'All active entrance exams' })
  findAll(@Query('level') level?: string, @Query('state') stateCode?: string) {
    return this.exams.findAll(level, stateCode);
  }

  @Get(':code')
  @ApiOperation({ summary: 'One exam by code' })
  findOne(@Param('code') code: string) {
    return this.exams.findOne(code);
  }

  @Get(':code/schedule')
  @ApiOperation({ summary: 'Published and tentative dates for one exam' })
  schedule(
    @Param('code') code: string,
    @Query('year', new ParseIntPipe({ optional: true })) year?: number,
  ) {
    return this.exams.findSchedule(code, year);
  }
}
