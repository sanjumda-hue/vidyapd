import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsInt, IsNumber, IsOptional, Min } from 'class-validator';

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

  @ApiPropertyOptional({
    type: [Number],
    example: [255, 285, 300, 315, 345],
    description:
      'Scores to evaluate, for marks-based exams. Omit to let the engine pick a band around the real score. Ignored when the exam is ranked.',
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @Type(() => Number)
  @IsNumber({}, { each: true })
  @Min(1, { each: true })
  scores?: number[];
}
