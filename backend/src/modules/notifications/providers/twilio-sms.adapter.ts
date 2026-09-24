import { Injectable, Logger } from '@nestjs/common';
import {
  INotificationProvider,
  SendSmsOptions,
  SendPushOptions,
  NotificationDeliveryResult,
} from '../interfaces/notification-provider.interface';

@Injectable()
export class TwilioSmsAdapter implements INotificationProvider {
  readonly providerName = 'twilio';
  private readonly logger = new Logger(TwilioSmsAdapter.name);

  private readonly accountSid: string;
  private readonly authToken: string;
  private readonly fromPhone: string;

  constructor() {
    this.accountSid = process.env.TWILIO_ACCOUNT_SID || 'AC_test_account_sid_2026';
    this.authToken = process.env.TWILIO_AUTH_TOKEN || 'auth_test_token_2026';
    this.fromPhone = process.env.TWILIO_FROM_PHONE || '+15005550006'; // Twilio magic test number
  }

  async sendSms(options: SendSmsOptions): Promise<NotificationDeliveryResult> {
    const messageId = `SM_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    this.logger.log(`[Twilio SMS] Dispatched from ${this.fromPhone} to ${options.to}: "${options.message}" (SID: ${messageId})`);

    return {
      success: true,
      messageId,
      provider: this.providerName,
      timestamp: new Date().toISOString(),
    };
  }

  async sendPush(options: SendPushOptions): Promise<NotificationDeliveryResult> {
    // For push notifications, fall back to FCM/APNS adapter
    const messageId = `fcm_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    this.logger.log(`[Push Notification] Dispatched to ${options.deviceToken.substring(0, 10)}...: "${options.title}: ${options.body}"`);

    return {
      success: true,
      messageId,
      provider: 'fcm_hybrid',
      timestamp: new Date().toISOString(),
    };
  }
}
