import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import { ReferenceService } from './reference.service';

@ApiTags('reference')
@Controller('reference')
export class ReferenceController {
  constructor(private readonly reference: ReferenceService) {}

  @Get('bootstrap')
  @ApiOperation({ summary: 'Every lookup list the client needs, in one call' })
  bootstrap() {
    return this.reference.bootstrap();
  }
}
