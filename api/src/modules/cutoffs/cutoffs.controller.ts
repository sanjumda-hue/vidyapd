import { Controller, Get, Param, ParseIntPipe, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CutoffsService } from './cutoffs.service';
import { CutoffQueryDto } from './dto/cutoff-query.dto';

@ApiTags('cutoffs')
@Controller('cutoffs')
export class CutoffsController {
  constructor(protected readonly cutoffs: CutoffsService) {}

  @Get('program/:collegeBranchId')
  @ApiOperation({ summary: 'Year-by-year opening and closing ranks for one program' })
  history(
    @Param('collegeBranchId', ParseIntPipe) collegeBranchId: number,
    @Query() query: CutoffQueryDto,
  ) {
    return this.cutoffs.historyForProgram(BigInt(collegeBranchId), query);
  }

  @Get('program/:collegeBranchId/trend')
  @ApiOperation({ summary: 'Aggregated trend row used by the cutoff chart' })
  trend(
    @Param('collegeBranchId', ParseIntPipe) collegeBranchId: number,
    @Query('seatType') seatType = 'OPEN',
    @Query('quota') quota = 'AI',
    @Query('gender') gender = 'GENDER_NEUTRAL',
  ) {
    return this.cutoffs.trendForProgram(BigInt(collegeBranchId), seatType, quota, gender);
  }
}
