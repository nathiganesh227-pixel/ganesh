import { MigrationInterface, QueryRunner } from "typeorm";

export class AddIdempotencyRecordsTable1790258057619 implements MigrationInterface {
    name = 'AddIdempotencyRecordsTable1790258057619'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "idempotency_records" ("key" character varying NOT NULL, "userId" character varying NOT NULL, "idempotencyKey" character varying NOT NULL, "endpoint" character varying NOT NULL, "responseBody" jsonb NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_f97e644e78e639ac55614cbaffe" PRIMARY KEY ("key"))`);
        await queryRunner.query(`CREATE INDEX "IDX_e6104a0526ff65649a16c236dd" ON "idempotency_records" ("userId") `);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP INDEX "public"."IDX_e6104a0526ff65649a16c236dd"`);
        await queryRunner.query(`DROP TABLE "idempotency_records"`);
    }

}
