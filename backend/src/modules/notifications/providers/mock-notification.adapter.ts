import { Injectable, Logger } from '@nestjs/common';
import {
  INotificationProvider,
  SendSmsOptions,
  SendPushOptions,
  NotificationDeliveryResult,
} from '../interfaces/notification-provider.interface';

@Injectable()
export class MockNotificationAdapter implements INotificationProvider {
  readonly providerName = 'mock_local';
  private readonly logger = new Logger(MockNotificationAdapter.name);

  async sendSms(options: SendSmsOptions): Promise<NotificationDeliveryResult> {
    const messageId = `msg_mock_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    this.logger.log(`[Mock SMS] Sent to ${options.to}: "${options.message}" (ID: ${messageId})`);

    return {
      success: true,
      messageId,
      provider: this.providerName,
      timestamp: new Date().toISOString(),
    };
  }

  async sendPush(options: SendPushOptions): Promise<NotificationDeliveryResult> {
    const messageId = `push_mock_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    this.logger.log(`[Mock Push] Sent to token ${options.deviceToken.substring(0, 10)}...: "${options.title} - ${options.body}"`);

    return {
      success: true,
      messageId,
      provider: this.providerName,
      timestamp: new Date().toISOString(),
    };
  }
}
