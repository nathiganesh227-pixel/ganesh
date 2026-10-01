import { MigrationInterface, QueryRunner } from 'typeorm';

export class EnhanceWebhookEventsTable1790800000000 implements MigrationInterface {
  name = 'EnhanceWebhookEventsTable1790800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "status" character varying NOT NULL DEFAULT 'RECEIVED'`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "providerPaymentId" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "providerOrderId" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "paymentId" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "bookingId" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "amount" numeric(10,2)`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "amountInMinorUnits" integer`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "currency" character varying(10) NOT NULL DEFAULT 'INR'`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "failureReason" text`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "receivedAt" TIMESTAMP NOT NULL DEFAULT now()`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP NOT NULL DEFAULT now()`,
    );

    // Alter processedAt to be nullable if it was NOT NULL
    await queryRunner.query(
      `ALTER TABLE "webhook_events" ALTER COLUMN "processedAt" DROP NOT NULL`,
    );

    // Indices for lookup and audit
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_webhook_events_eventType" ON "webhook_events" ("eventType")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_webhook_events_status" ON "webhook_events" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_webhook_events_providerPaymentId" ON "webhook_events" ("providerPaymentId")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_webhook_events_providerOrderId" ON "webhook_events" ("providerOrderId")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_webhook_events_bookingId" ON "webhook_events" ("bookingId")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_webhook_events_bookingId"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_webhook_events_providerOrderId"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_webhook_events_providerPaymentId"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_webhook_events_status"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_webhook_events_eventType"`);

    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "updatedAt"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "receivedAt"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "failureReason"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "currency"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "amountInMinorUnits"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "amount"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "bookingId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "paymentId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "providerOrderId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "providerPaymentId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "status"`,
    );
  }
}
