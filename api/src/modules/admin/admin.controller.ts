import { Body, Controller, Get, Param, ParseIntPipe, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { AdminService } from './admin.service';

/**
 * NOT AUTHENTICATED YET. These endpoints publish cutoff data and must sit
 * behind the admin role guard before this service is exposed publicly.
 */
@ApiTags('admin')
@Controller('admin')
export class AdminController {
  constructor(protected readonly admin: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Dashboard counters' })
  stats() {
    return this.admin.stats();
  }

  @Get('imports')
  @ApiOperation({ summary: 'Import jobs, newest first' })
  list(@Query('status') status?: string) {
    return this.admin.listJobs(status);
  }

  @Get('imports/:id')
  @ApiOperation({ summary: 'One job with its validation failures and a sample of valid rows' })
  detail(@Param('id', ParseIntPipe) id: number) {
    return this.admin.jobDetail(BigInt(id));
  }

  @Post('imports/:id/approve')
  @ApiOperation({ summary: 'Mark a pending job approved (does not publish)' })
  approve(@Param('id', ParseIntPipe) id: number, @Body('note') note?: string) {
    return this.admin.approve(BigInt(id), note);
  }

  @Post('imports/:id/reject')
  @ApiOperation({ summary: 'Reject a pending job' })
  reject(@Param('id', ParseIntPipe) id: number, @Body('note') note?: string) {
    return this.admin.reject(BigInt(id), note);
  }

  @Post('imports/:id/publish')
  @ApiOperation({ summary: 'Write an approved job into cutoff_data and refresh the trend view' })
  publish(@Param('id', ParseIntPipe) id: number) {
    return this.admin.publish(BigInt(id));
  }
}
