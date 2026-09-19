import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';

export enum ApplicantGender {
  MALE = 'male',
  FEMALE = 'female',
  OTHER = 'other',
}

export class PredictDto {
  @ApiProperty({ example: 'JEE_MAIN' })
  @IsString()
  examCode!: string;

  @ApiPropertyOptional({ example: 2026, description: 'Admission year. Defaults to the current season.' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2000)
  @Max(2100)
  academicYear?: number;

  // Exactly one of rank / percentile is required. A percentile is converted
  // through fn_percentile_to_rank and the response says the rank was derived.
  @ApiPropertyOptional({ example: 45821 })
  @ValidateIf((o: PredictDto) => o.percentile === undefined)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  rank?: number;

  @ApiPropertyOptional({ example: 94.2 })
  @ValidateIf((o: PredictDto) => o.rank === undefined)
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  @Max(100)
  percentile?: number;

  @ApiProperty({ example: 'OBC_NCL' })
  @IsString()
  categoryCode!: string;

  @ApiProperty({ enum: ApplicantGender })
  @IsEnum(ApplicantGender)
  gender!: ApplicantGender;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @Type(() => Boolean)
  @IsBoolean()
  isPwd = false;

  @ApiPropertyOptional({ example: 'UP', description: 'Required for home-state quota matching.' })
  @IsOptional()
  @IsString()
  homeStateCode?: string;

  @ApiPropertyOptional({ type: [String], example: ['CSE', 'IT', 'ECE'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(30)
  @IsString({ each: true })
  branchCodes?: string[];

  @ApiPropertyOptional({ type: [String], example: ['KA', 'MH'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(40)
  @IsString({ each: true })
  stateCodes?: string[];

  @ApiPropertyOptional({ type: [String], example: ['NIT', 'IIIT'] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  collegeTypes?: string[];

  @ApiPropertyOptional({ default: 200, maximum: 500 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(500)
  limit = 200;
}
