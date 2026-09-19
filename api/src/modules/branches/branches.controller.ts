import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { BranchesService } from './branches.service';

@ApiTags('branches')
@Controller('branches')
export class BranchesController {
  constructor(protected readonly branches: BranchesService) {}
}
