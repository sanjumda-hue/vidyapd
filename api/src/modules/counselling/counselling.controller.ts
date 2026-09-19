import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CounsellingService } from './counselling.service';

@ApiTags('counselling')
@Controller('counselling')
export class CounsellingController {
  constructor(protected readonly counselling: CounsellingService) {}
}
