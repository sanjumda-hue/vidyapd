import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { ShortlistService } from './shortlist.service';

@ApiTags('shortlist')
@Controller('shortlist')
export class ShortlistController {
  constructor(protected readonly shortlist: ShortlistService) {}
}
