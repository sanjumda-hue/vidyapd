import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsOptional, IsString } from 'class-validator';

import { PaginationDto } from '../../../common/dto/pagination.dto';

export class CollegeQueryDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'Matches the full or short name' })
  @IsOptional()
  @IsString()
  q?: string;

  @ApiPropertyOptional({ example: 'KA' })
  @IsOptional()
  @IsString()
  stateCode?: string;

  @ApiPropertyOptional({ example: 'NIT', description: 'IIT, NIT, IIIT, GFTI, DEEMED, ...' })
  @IsOptional()
  @IsString()
  type?: string;

  @ApiPropertyOptional({
    example: 'JEE_ADVANCED',
    description: 'Colleges with a published cutoff for this exam.',
  })
  @IsOptional()
  @IsString()
  examCode?: string;

  @ApiPropertyOptional({ example: 'CSE', description: 'Colleges offering this branch.' })
  @IsOptional()
  @IsString()
  branchCode?: string;
}

export class CompareDto {
  @ApiPropertyOptional({ type: [String], example: ['iit-delhi', 'nit-trichy'] })
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(4)
  @IsString({ each: true })
  @Transform(({ value }) => (typeof value === 'string' ? value.split(',') : value))
  slugs!: string[];

  // Every column is read at the same seat dimension, or the comparison is
  // between different things.
  @ApiPropertyOptional({ default: 'OPEN' })
  @IsOptional()
  @IsString()
  seatType = 'OPEN';

  @ApiPropertyOptional({ default: 'AI' })
  @IsOptional()
  @IsString()
  quota = 'AI';

  @ApiPropertyOptional({ default: 'GENDER_NEUTRAL' })
  @IsOptional()
  @IsString()
  gender = 'GENDER_NEUTRAL';
}
