import { MigrationInterface, QueryRunner } from 'typeorm';

export class EnhanceIdempotencyRecordsTable1790900000000 implements MigrationInterface {
  name = 'EnhanceIdempotencyRecordsTable1790900000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" ADD COLUMN IF NOT EXISTS "operation" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" ADD COLUMN IF NOT EXISTS "requestHash" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" ADD COLUMN IF NOT EXISTS "resourceId" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" ADD COLUMN IF NOT EXISTS "status" character varying NOT NULL DEFAULT 'COMPLETED'`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" ADD COLUMN IF NOT EXISTS "failureReason" text`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP NOT NULL DEFAULT now()`,
    );

    // Make responseBody nullable in case of in-flight PROCESSING state
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" ALTER COLUMN "responseBody" DROP NOT NULL`,
    );

    // Indices for query performance and auditability
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_idempotency_records_operation" ON "idempotency_records" ("operation")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_idempotency_records_resourceId" ON "idempotency_records" ("resourceId")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_idempotency_records_status" ON "idempotency_records" ("status")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_idempotency_records_idempotencyKey" ON "idempotency_records" ("idempotencyKey")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_idempotency_records_idempotencyKey"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_idempotency_records_status"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_idempotency_records_resourceId"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_idempotency_records_operation"`);

    await queryRunner.query(
      `ALTER TABLE "idempotency_records" DROP COLUMN IF EXISTS "updatedAt"`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" DROP COLUMN IF EXISTS "failureReason"`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" DROP COLUMN IF EXISTS "status"`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" DROP COLUMN IF EXISTS "resourceId"`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" DROP COLUMN IF EXISTS "requestHash"`,
    );
    await queryRunner.query(
      `ALTER TABLE "idempotency_records" DROP COLUMN IF EXISTS "operation"`,
    );
  }
}
