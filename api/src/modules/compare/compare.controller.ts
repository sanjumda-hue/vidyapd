import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CompareService } from './compare.service';

@ApiTags('compare')
@Controller('compare')
export class CompareController {
  constructor(protected readonly compare: CompareService) {}
}
