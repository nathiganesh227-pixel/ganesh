import { Controller, Get, Optional } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PaymentConfigService } from './modules/payments/payment-config.service';

@ApiTags('system')
@Controller()
export class AppController {
  constructor(
    @Optional()
    private readonly paymentConfigService?: PaymentConfigService,
  ) {}

  @Get('health')
  @ApiOperation({ summary: 'System health probe' })
  healthCheck() {
    const configService = this.paymentConfigService ?? new PaymentConfigService();
    const summary = configService.getSafeSummary();

    return {
      status: 'UP',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      service: 'plaza-backend',
      version: '1.0.0',
      paymentMode: summary.paymentMode,
    };
  }
}
