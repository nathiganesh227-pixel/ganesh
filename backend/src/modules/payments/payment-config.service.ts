import { Injectable, Logger, Optional, ServiceUnavailableException } from '@nestjs/common';

export enum PaymentMode {
  SIMULATED = 'SIMULATED',
  RAZORPAY = 'RAZORPAY',
}

export enum PaymentConfigStatus {
  SIMULATED_READY = 'SIMULATED_READY',
  RAZORPAY_DISABLED = 'RAZORPAY_DISABLED',
  RAZORPAY_READY = 'RAZORPAY_READY',
  RAZORPAY_MISCONFIGURED = 'RAZORPAY_MISCONFIGURED',
}

export interface SafePaymentConfigSummary {
  paymentMode: PaymentMode;
  razorpayLiveEnabled: boolean;
  razorpayConfigured: boolean;
  paymentConfigStatus: PaymentConfigStatus;
  activeProvider: 'simulated' | 'razorpay' | 'none';
  liveOperationsAllowed: boolean;
  webhookConfigured: boolean;
}

export interface PaymentConfigEvaluation {
  summary: SafePaymentConfigSummary;
  isPaymentModeValid: boolean;
  isLiveFlagValid: boolean;
  missingVariables: string[];
}

const REQUIRED_RAZORPAY_ENV_VARS = [
  'RAZORPAY_KEY_ID',
  'RAZORPAY_KEY_SECRET',
  'RAZORPAY_WEBHOOK_SECRET',
] as const;

@Injectable()
export class PaymentConfigService {
  private readonly logger = new Logger(PaymentConfigService.name);

  constructor(@Optional() private readonly envOverride?: NodeJS.ProcessEnv) {
    this.validateConfiguration();
  }

  private getEnv(): NodeJS.ProcessEnv {
    return this.envOverride ?? process.env;
  }

  private isNonEmptyCredential(value: string | undefined): boolean {
    if (typeof value !== 'string') return false;
    const trimmed = value.trim();
    if (trimmed.length === 0) return false;
    if (trimmed.includes('REPLACE_WITH_')) return false;
    return true;
  }

  /**
   * Evaluates the payment configuration state without throwing,
   * nunca exposing secret values.
   */
  evaluate(env: NodeJS.ProcessEnv = this.getEnv()): PaymentConfigEvaluation {
    const rawPaymentMode =
      env.PAYMENT_MODE !== undefined
        ? env.PAYMENT_MODE
        : env.PAYMENT_PROVIDER !== undefined
        ? env.PAYMENT_PROVIDER.toUpperCase()
        : undefined;
    let paymentMode: PaymentMode = PaymentMode.SIMULATED;
    let isPaymentModeValid = true;

    if (rawPaymentMode !== undefined) {
      const normalizedMode = String(rawPaymentMode).trim().toUpperCase();
      if (
        normalizedMode === PaymentMode.SIMULATED ||
        normalizedMode === PaymentMode.RAZORPAY
      ) {
        paymentMode = normalizedMode as PaymentMode;
      } else {
        isPaymentModeValid = false;
      }
    }

    const rawLiveEnabled = env.RAZORPAY_LIVE_ENABLED;
    let razorpayLiveEnabled = false;
    let isLiveFlagValid = true;

    if (rawLiveEnabled !== undefined && String(rawLiveEnabled).trim() !== '') {
      const normalizedLive = String(rawLiveEnabled).trim().toLowerCase();
      if (normalizedLive === 'true') {
        razorpayLiveEnabled = true;
      } else if (normalizedLive === 'false') {
        razorpayLiveEnabled = false;
      } else {
        isLiveFlagValid = false;
      }
    }

    const missingVariables: string[] = [];
    for (const varName of REQUIRED_RAZORPAY_ENV_VARS) {
      if (!this.isNonEmptyCredential(env[varName])) {
        missingVariables.push(varName);
      }
    }

    const razorpayConfigured = missingVariables.length === 0;
    const webhookConfigured = this.isNonEmptyCredential(env.RAZORPAY_WEBHOOK_SECRET);
    const isProductionEnv =
      String(env.NODE_ENV || '')
        .trim()
        .toLowerCase() === 'production';

    let paymentConfigStatus: PaymentConfigStatus;
    if (!isPaymentModeValid || !isLiveFlagValid) {
      paymentConfigStatus = PaymentConfigStatus.RAZORPAY_MISCONFIGURED;
    } else if (paymentMode === PaymentMode.SIMULATED) {
      if (razorpayLiveEnabled) {
        paymentConfigStatus = PaymentConfigStatus.RAZORPAY_MISCONFIGURED;
      } else {
        paymentConfigStatus = PaymentConfigStatus.SIMULATED_READY;
      }
    } else {
      // paymentMode === PaymentMode.RAZORPAY
      if (!razorpayLiveEnabled) {
        if (isProductionEnv && !razorpayConfigured) {
          paymentConfigStatus = PaymentConfigStatus.RAZORPAY_MISCONFIGURED;
        } else {
          paymentConfigStatus = PaymentConfigStatus.RAZORPAY_DISABLED;
        }
      } else {
        // razorpayLiveEnabled === true
        if (razorpayConfigured) {
          paymentConfigStatus = PaymentConfigStatus.RAZORPAY_READY;
        } else {
          paymentConfigStatus = PaymentConfigStatus.RAZORPAY_MISCONFIGURED;
        }
      }
    }

    const liveOperationsAllowed =
      paymentConfigStatus === PaymentConfigStatus.RAZORPAY_READY &&
      paymentMode === PaymentMode.RAZORPAY &&
      razorpayLiveEnabled &&
      razorpayConfigured;

    const activeProvider: 'simulated' | 'razorpay' | 'none' =
      paymentConfigStatus === PaymentConfigStatus.SIMULATED_READY
        ? 'simulated'
        : paymentConfigStatus === PaymentConfigStatus.RAZORPAY_READY
        ? 'razorpay'
        : 'none';

    return {
      summary: {
        paymentMode,
        razorpayLiveEnabled,
        razorpayConfigured,
        paymentConfigStatus,
        activeProvider,
        liveOperationsAllowed,
        webhookConfigured,
      },
      isPaymentModeValid,
      isLiveFlagValid,
      missingVariables,
    };
  }

  /**
   * Validates configuration and fails closed on invalid or unsafe states.
   * Logs only variable names and safe status labels — never secret values.
   */
  validateConfiguration(env: NodeJS.ProcessEnv = this.getEnv()): SafePaymentConfigSummary {
    const evaluation = this.evaluate(env);
    const { summary, isPaymentModeValid, isLiveFlagValid, missingVariables } = evaluation;

    if (!isPaymentModeValid) {
      this.logger.error('Payment configuration error: Invalid PAYMENT_MODE value. Supported: SIMULATED, RAZORPAY');
      throw new Error('Invalid PAYMENT_MODE configuration. Supported values: SIMULATED, RAZORPAY');
    }

    if (!isLiveFlagValid) {
      this.logger.error('Payment configuration error: Invalid RAZORPAY_LIVE_ENABLED value. Supported: true, false');
      throw new Error('Invalid RAZORPAY_LIVE_ENABLED configuration. Supported values: true, false');
    }

    if (summary.paymentMode === PaymentMode.SIMULATED && summary.razorpayLiveEnabled) {
      if (missingVariables.length > 0) {
        for (const varName of missingVariables) {
          this.logger.error(`Missing required payment configuration: ${varName}`);
        }
        throw new Error(`Missing required payment configuration: ${missingVariables.join(', ')}`);
      }
      this.logger.error('Payment configuration error: RAZORPAY_LIVE_ENABLED=true is forbidden when PAYMENT_MODE=SIMULATED');
      throw new Error('Configuration conflict: RAZORPAY_LIVE_ENABLED=true requires PAYMENT_MODE=RAZORPAY');
    }

    if (summary.paymentConfigStatus === PaymentConfigStatus.RAZORPAY_MISCONFIGURED) {
      this.logger.error('Razorpay configuration: incomplete');
      for (const varName of missingVariables) {
        this.logger.error(`Missing required payment configuration: ${varName}`);
      }
      throw new Error(`Missing required payment configuration: ${missingVariables.join(', ')}`);
    }

    this.logger.log(
      `Payment mode: ${summary.paymentMode} | Razorpay live payments: ${
        summary.razorpayLiveEnabled ? 'enabled' : 'disabled'
      } | Status: ${summary.paymentConfigStatus}`,
    );

    return summary;
  }

  getSafeSummary(): SafePaymentConfigSummary {
    return this.evaluate().summary;
  }

  getPaymentMode(): PaymentMode {
    return this.evaluate().summary.paymentMode;
  }

  isRazorpayLiveEnabled(): boolean {
    return this.evaluate().summary.razorpayLiveEnabled;
  }

  isRazorpayConfigured(): boolean {
    return this.evaluate().summary.razorpayConfigured;
  }

  getConfigStatus(): PaymentConfigStatus {
    return this.evaluate().summary.paymentConfigStatus;
  }

  /**
   * Asserts that live Razorpay operations are explicitly allowed.
   * Rejects safely if RAZORPAY_LIVE_ENABLED=false or credentials are missing.
   */
  assertRazorpayLiveOperationAllowed(): void {
    const evaluation = this.evaluate();
    const { summary, isPaymentModeValid, isLiveFlagValid, missingVariables } = evaluation;

    if (!isPaymentModeValid || !isLiveFlagValid) {
      throw new ServiceUnavailableException(
        'Payment configuration is invalid (RAZORPAY_MISCONFIGURED). Operation rejected.',
      );
    }

    if (summary.paymentMode !== PaymentMode.RAZORPAY) {
      throw new ServiceUnavailableException(
        'Razorpay operations cannot execute while PAYMENT_MODE is SIMULATED (PAYMENT_MODE_MISMATCH).',
      );
    }

    if (!summary.razorpayLiveEnabled) {
      throw new ServiceUnavailableException(
        'Razorpay live payments are disabled (RAZORPAY_LIVE_DISABLED). Simulated fallback is forbidden.',
      );
    }

    if (!summary.razorpayConfigured || missingVariables.length > 0) {
      throw new ServiceUnavailableException(
        `Missing required payment configuration: ${missingVariables.join(', ')} (RAZORPAY_MISCONFIGURED).`,
      );
    }
  }

  /**
   * Internal server-only credential accessors (never exposed in any DTO/health/log).
   */
  getRazorpayKeyId(): string {
    const env = this.getEnv();
    return this.isNonEmptyCredential(env.RAZORPAY_KEY_ID) ? env.RAZORPAY_KEY_ID!.trim() : '';
  }

  getRazorpayKeySecret(): string {
    const env = this.getEnv();
    return this.isNonEmptyCredential(env.RAZORPAY_KEY_SECRET) ? env.RAZORPAY_KEY_SECRET!.trim() : '';
  }

  getRazorpayWebhookSecret(): string {
    const env = this.getEnv();
    return this.isNonEmptyCredential(env.RAZORPAY_WEBHOOK_SECRET) ? env.RAZORPAY_WEBHOOK_SECRET!.trim() : '';
  }
}
