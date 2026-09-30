import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddQuoteIdToPaymentsTable1790700000000 implements MigrationInterface {
  name = 'AddQuoteIdToPaymentsTable1790700000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "payments" ADD COLUMN IF NOT EXISTS "quoteId" character varying`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_payments_quoteId" ON "payments" ("quoteId")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_payments_providerPaymentId" ON "payments" ("providerPaymentId")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_payments_providerPaymentId"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_payments_quoteId"`);
    await queryRunner.query(`ALTER TABLE "payments" DROP COLUMN IF EXISTS "quoteId"`);
  }
}
