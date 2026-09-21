import { Body, Controller, Get, Param, ParseIntPipe, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard, RequestUser } from '../../common/guards/jwt-auth.guard';
import { CreatePaperDto, SubmitAttemptDto } from './dto/mock.dto';
import { MockService } from './mock.service';

/**
 * Mock tests: upload a paper's answer key, then a response sheet, get a score.
 *
 * Both files arrive as text in the JSON body rather than as a multipart
 * upload. They are two small CSVs, the client already has them as strings, and
 * it keeps a file-upload dependency and its size and type handling out of the
 * API for no benefit.
 */
@ApiTags('mock')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('mock')
export class MockController {
  constructor(protected readonly mock: MockService) {}

  @Get('papers')
  @ApiOperation({ summary: 'Papers this student can use, newest first' })
  listPapers(@CurrentUser() user: RequestUser, @Query('examCode') examCode?: string) {
    return this.mock.listPapers(user.id, examCode);
  }

  @Post('papers')
  @ApiOperation({ summary: 'Create a paper from an answer key' })
  createPaper(@Body() dto: CreatePaperDto, @CurrentUser() user: RequestUser) {
    return this.mock.createPaper(dto, user.id);
  }

  @Post('papers/:id/attempts')
  @ApiOperation({ summary: 'Score a response sheet against a paper' })
  submit(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: SubmitAttemptDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.mock.submitAttempt(id, dto.responsesCsv, user.id);
  }

  @Get('attempts')
  @ApiOperation({ summary: 'This student\'s past attempts' })
  attempts(@CurrentUser() user: RequestUser) {
    return this.mock.listAttempts(user.id);
  }
}
