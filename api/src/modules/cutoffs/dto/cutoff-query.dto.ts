import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

import { PaginationDto } from '../../../common/dto/pagination.dto';

export class CutoffQueryDto extends PaginationDto {
  @ApiPropertyOptional({ example: 'JOSAA' })
  @IsOptional()
  @IsString()
  authorityCode?: string;

  @ApiPropertyOptional({ example: 2026 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2000)
  @Max(2100)
  year?: number;

  @ApiPropertyOptional({ example: 5, description: 'Omit for the last published round of each year.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  round?: number;

  @ApiPropertyOptional({ example: 'OPEN' })
  @IsOptional()
  @IsString()
  seatTypeCode?: string;

  @ApiPropertyOptional({ example: 'HS' })
  @IsOptional()
  @IsString()
  quotaCode?: string;

  @ApiPropertyOptional({ example: 'GENDER_NEUTRAL' })
  @IsOptional()
  @IsString()
  genderCode?: string;
}
