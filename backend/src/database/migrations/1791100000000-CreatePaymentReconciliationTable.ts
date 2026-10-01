import { MigrationInterface, QueryRunner, Table, TableIndex } from 'typeorm';

export class CreatePaymentReconciliationTable1791100000000 implements MigrationInterface {
  name = 'CreatePaymentReconciliationTable1791100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'payment_reconciliation_records',
        columns: [
          {
            name: 'id',
            type: 'varchar',
            isPrimary: true,
          },
          {
            name: 'paymentId',
            type: 'varchar',
            isNullable: false,
          },
          {
            name: 'bookingId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'quoteId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'provider',
            type: 'varchar',
            default: "'simulated'",
          },
          {
            name: 'providerPaymentId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'providerOrderId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'canonicalPaymentStatus',
            type: 'varchar',
            default: "'PENDING'",
          },
          {
            name: 'observedProviderStatus',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'canonicalAmount',
            type: 'float',
            default: 0,
          },
          {
            name: 'canonicalAmountInMinorUnits',
            type: 'int',
            default: 0,
          },
          {
            name: 'observedAmountInMinorUnits',
            type: 'int',
            isNullable: true,
          },
          {
            name: 'canonicalCurrency',
            type: 'varchar',
            default: "'INR'",
          },
          {
            name: 'observedCurrency',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'mismatchCategory',
            type: 'varchar',
            default: "'NO_MISMATCH'",
          },
          {
            name: 'status',
            type: 'varchar',
            default: "'REQUIRED'",
          },
          {
            name: 'attemptCount',
            type: 'int',
            default: 0,
          },
          {
            name: 'lastAttemptedAt',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'nextRetryAt',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'resolvedAt',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'resolutionAction',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'sanitizedResolutionReason',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'requiresManualIntervention',
            type: 'boolean',
            default: false,
          },
          {
            name: 'metadata',
            type: 'jsonb',
            isNullable: true,
          },
          {
            name: 'createdAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
          {
            name: 'updatedAt',
            type: 'timestamp',
            default: 'CURRENT_TIMESTAMP',
          },
        ],
      }),
      true,
    );

    await queryRunner.createIndices('payment_reconciliation_records', [
      new TableIndex({
        name: 'IDX_payment_reconciliation_paymentId',
        columnNames: ['paymentId'],
      }),
      new TableIndex({
        name: 'IDX_payment_reconciliation_bookingId',
        columnNames: ['bookingId'],
      }),
      new TableIndex({
        name: 'IDX_payment_reconciliation_providerPaymentId',
        columnNames: ['providerPaymentId'],
      }),
      new TableIndex({
        name: 'IDX_payment_reconciliation_providerOrderId',
        columnNames: ['providerOrderId'],
      }),
      new TableIndex({
        name: 'IDX_payment_reconciliation_mismatchCategory',
        columnNames: ['mismatchCategory'],
      }),
      new TableIndex({
        name: 'IDX_payment_reconciliation_status',
        columnNames: ['status'],
      }),
    ]);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('payment_reconciliation_records', true);
  }
}
