import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsInt, IsOptional, Min } from 'class-validator';

import { PredictDto } from './predict.dto';

/** Design doc section 29: run the same profile at several hypothetical ranks. */
export class WhatIfDto extends PredictDto {
  @ApiPropertyOptional({
    type: [Number],
    example: [30000, 40000, 45821, 50000, 60000],
    description: 'Ranks to evaluate. Omit to let the engine pick a band around the real rank.',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @Type(() => Number)
  @IsInt({ each: true })
  @Min(1, { each: true })
  ranks?: number[];
}
