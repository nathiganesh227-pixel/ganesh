export interface SendSmsOptions {
  to: string; // E.164 phone format, e.g. +919876543210
  message: string;
  templateId?: string;
}

export interface SendPushOptions {
  deviceToken: string;
  title: string;
  body: string;
  data?: Record<string, any>;
}

export interface NotificationDeliveryResult {
  success: boolean;
  messageId: string;
  provider: string;
  timestamp: string;
  error?: string;
}

export interface INotificationProvider {
  readonly providerName: string;
  sendSms(options: SendSmsOptions): Promise<NotificationDeliveryResult>;
  sendPush(options: SendPushOptions): Promise<NotificationDeliveryResult>;
}
