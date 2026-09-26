import { MigrationInterface, QueryRunner } from "typeorm";

export class AddPaymentsTable1790290000000 implements MigrationInterface {
    name = 'AddPaymentsTable1790290000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "payments" (
                "id" character varying NOT NULL,
                "bookingId" character varying NOT NULL,
                "userId" character varying NOT NULL DEFAULT 'usr_default_1',
                "amount" double precision NOT NULL,
                "currency" character varying NOT NULL DEFAULT 'INR',
                "provider" character varying NOT NULL DEFAULT 'razorpay',
                "providerOrderId" character varying,
                "providerPaymentId" character varying,
                "providerSignature" character varying,
                "status" character varying NOT NULL DEFAULT 'CREATED',
                "paymentMethod" character varying,
                "failureReason" character varying,
                "refundAmount" double precision DEFAULT 0,
                "refundId" character varying,
                "metadata" jsonb,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_payments_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_payments_bookingId" ON "payments" ("bookingId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_payments_providerOrderId" ON "payments" ("providerOrderId")`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_payments_providerOrderId"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_payments_bookingId"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "payments"`);
    }
}
