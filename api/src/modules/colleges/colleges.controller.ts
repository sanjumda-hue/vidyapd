import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CollegesService } from './colleges.service';

@ApiTags('colleges')
@Controller('colleges')
export class CollegesController {
  constructor(protected readonly colleges: CollegesService) {}
}
