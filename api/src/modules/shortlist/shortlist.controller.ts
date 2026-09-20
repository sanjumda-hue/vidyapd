import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard, RequestUser } from '../../common/guards/jwt-auth.guard';
import { ShortlistService } from './shortlist.service';

@ApiTags('shortlist')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('shortlist')
export class ShortlistController {
  constructor(protected readonly shortlist: ShortlistService) {}

  @Get()
  @ApiOperation({ summary: 'The saved programmes, in preference order' })
  list(@CurrentUser() user: RequestUser) {
    return this.shortlist.list(user.id);
  }

  @Get('ids')
  @ApiOperation({ summary: 'Just the saved programme ids, for rendering toggles' })
  ids(@CurrentUser() user: RequestUser) {
    return this.shortlist.ids(user.id);
  }

  @Post('reorder')
  @ApiOperation({ summary: 'Save a new preference order for the whole list' })
  reorder(@CurrentUser() user: RequestUser, @Body('ids') ids: (string | number)[]) {
    return this.shortlist.reorder(user.id, (ids ?? []).map((x) => BigInt(x)));
  }

  // Declared before :collegeBranchId so the literal route is not swallowed.
  @Post(':collegeBranchId')
  @ApiOperation({ summary: 'Save a programme (idempotent)' })
  add(
    @CurrentUser() user: RequestUser,
    @Param('collegeBranchId', ParseIntPipe) id: number,
    @Body('note') note?: string,
  ) {
    return this.shortlist.add(user.id, BigInt(id), note);
  }

  @Delete(':collegeBranchId')
  @ApiOperation({ summary: 'Remove a programme' })
  remove(
    @CurrentUser() user: RequestUser,
    @Param('collegeBranchId', ParseIntPipe) id: number,
  ) {
    return this.shortlist.remove(user.id, BigInt(id));
  }
}
