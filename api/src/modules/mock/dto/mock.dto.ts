import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsNumber, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

/** A CSV pasted whole. Big enough for a 300-question key, small enough to refuse a file. */
const MAX_CSV = 200_000;

export class CreatePaperDto {
  @ApiProperty({ example: 'JEE_MAIN' })
  @IsString()
  examCode!: string;

  @ApiProperty({ example: 'JEE Main 2025 Session 1, Shift 1' })
  @IsString()
  @MinLength(3)
  @MaxLength(160)
  title!: string;

  @ApiPropertyOptional({ description: 'Left blank, one is generated from the exam and year.' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  code?: string;

  @ApiPropertyOptional({ example: 2025 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2000)
  @Max(2100)
  academicYear?: number;

  // Omitted, the exam's published scheme is used; there is no default for an
  // exam whose marking changes year to year, and the upload is refused instead.
  @ApiPropertyOptional({ example: 4 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  marksCorrect?: number;

  @ApiPropertyOptional({ example: 1, description: 'Deducted, so give it as a positive number.' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  marksWrong?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  marksSkipped?: number;

  @ApiPropertyOptional({ default: 0, description: 'How far a numerical answer may be off.' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  numericTolerance?: number;

  @ApiPropertyOptional({ description: 'Where the key came from, so a wrong one can be traced.' })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  sourceNote?: string;

  @ApiProperty({ description: 'The answer key file, as text.' })
  @IsString()
  @MaxLength(MAX_CSV)
  answerKeyCsv!: string;
}

export class SubmitAttemptDto {
  @ApiProperty({ description: 'The response sheet, as text.' })
  @IsString()
  @MaxLength(MAX_CSV)
  responsesCsv!: string;
}
