import { MigrationInterface, QueryRunner, Table, TableIndex } from 'typeorm';

export class CreatePaymentRecoveryTable1791000000000 implements MigrationInterface {
  name = 'CreatePaymentRecoveryTable1791000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.createTable(
      new Table({
        name: 'payment_recovery_records',
        columns: [
          {
            name: 'id',
            type: 'varchar',
            isPrimary: true,
          },
          {
            name: 'resourceType',
            type: 'varchar',
            default: "'payment'",
          },
          {
            name: 'resourceId',
            type: 'varchar',
            isNullable: false,
          },
          {
            name: 'paymentId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'bookingId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'providerOrderId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'providerPaymentId',
            type: 'varchar',
            isNullable: true,
          },
          {
            name: 'failureCategory',
            type: 'varchar',
            default: "'UNKNOWN_PROVIDER_OUTCOME'",
          },
          {
            name: 'recoveryStatus',
            type: 'varchar',
            default: "'REQUIRED'",
          },
          {
            name: 'safeFailureReason',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'retryCount',
            type: 'int',
            default: 0,
          },
          {
            name: 'requiresManualIntervention',
            type: 'boolean',
            default: false,
          },
          {
            name: 'resolutionNotes',
            type: 'text',
            isNullable: true,
          },
          {
            name: 'lastRetryAt',
            type: 'timestamp',
            isNullable: true,
          },
          {
            name: 'metadata',
            type: 'jsonb',
            isNullable: true,
          },
          {
            name: 'resolvedAt',
            type: 'timestamp',
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

    await queryRunner.createIndices('payment_recovery_records', [
      new TableIndex({
        name: 'IDX_payment_recovery_resourceId',
        columnNames: ['resourceId'],
      }),
      new TableIndex({
        name: 'IDX_payment_recovery_paymentId',
        columnNames: ['paymentId'],
      }),
      new TableIndex({
        name: 'IDX_payment_recovery_bookingId',
        columnNames: ['bookingId'],
      }),
      new TableIndex({
        name: 'IDX_payment_recovery_failureCategory',
        columnNames: ['failureCategory'],
      }),
      new TableIndex({
        name: 'IDX_payment_recovery_recoveryStatus',
        columnNames: ['recoveryStatus'],
      }),
    ]);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropTable('payment_recovery_records', true);
  }
}
