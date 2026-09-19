import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { PredictDto } from './dto/predict.dto';
import { WhatIfDto } from './dto/what-if.dto';
import { PredictionService } from './prediction.service';

@ApiTags('prediction')
@Controller('prediction')
export class PredictionController {
  constructor(private readonly prediction: PredictionService) {}

  @Post()
  @ApiOperation({ summary: 'Match a rank or percentile against historical closing ranks' })
  predict(@Body() dto: PredictDto) {
    return this.prediction.predict(dto);
  }

  @Post('what-if')
  @ApiOperation({ summary: 'Run the same profile across several hypothetical ranks' })
  whatIf(@Body() dto: WhatIfDto) {
    return this.prediction.whatIf(dto);
  }

  @Get(':requestId')
  @ApiOperation({ summary: 'Re-open a saved prediction exactly as it was generated' })
  findOne(@Param('requestId') requestId: string) {
    return this.prediction.findSavedResult(requestId);
  }
}
