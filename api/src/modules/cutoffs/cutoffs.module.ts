import { Module } from '@nestjs/common';

import { CutoffsController } from './cutoffs.controller';
import { CutoffsService } from './cutoffs.service';

@Module({
  controllers: [CutoffsController],
  providers: [CutoffsService],
  exports: [CutoffsService],
})
export class CutoffsModule {}
