import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { CollegesService } from './colleges.service';
import { CollegeQueryDto, CompareDto } from './dto/college-query.dto';

@ApiTags('colleges')
@Controller('colleges')
export class CollegesController {
  constructor(protected readonly colleges: CollegesService) {}

  @Get()
  @ApiOperation({ summary: 'Search colleges by name, state or type' })
  async search(@Query() q: CollegeQueryDto) {
    const { items, total } = await this.colleges.search({
      q: q.q,
      stateCode: q.stateCode,
      type: q.type,
      examCode: q.examCode,
      branchCode: q.branchCode,
      limit: q.limit,
      skip: q.skip,
    });
    return { items, page: q.page, limit: q.limit, total, totalPages: Math.ceil(total / q.limit) };
  }

  @Get('compare')
  @ApiOperation({ summary: 'Side-by-side comparison at one seat dimension' })
  compare(@Query() dto: CompareDto) {
    return this.colleges.compare(dto.slugs, {
      seatType: dto.seatType,
      quota: dto.quota,
      gender: dto.gender,
    });
  }

  // Declared after /compare so the literal route is not swallowed by :slug.
  @Get(':slug')
  @ApiOperation({ summary: 'One college with its programmes and counselling coverage' })
  detail(@Param('slug') slug: string) {
    return this.colleges.detail(slug);
  }
}
