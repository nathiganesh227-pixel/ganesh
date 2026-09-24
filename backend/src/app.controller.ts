import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('system')
@Controller()
export class AppController {
  @Get('health')
  @ApiOperation({ summary: 'System health probe' })
  healthCheck() {
    return {
      status: 'UP',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      service: 'plaza-backend',
      version: '1.0.0',
    };
  }
}
