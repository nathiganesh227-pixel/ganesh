import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddAuditLogsTable1790260000000 implements MigrationInterface {
  name = 'AddAuditLogsTable1790260000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "audit_logs" ("id" character varying NOT NULL, "actorUserId" character varying NOT NULL, "actorEmail" character varying NOT NULL, "action" character varying NOT NULL, "resourceType" character varying NOT NULL, "resourceId" character varying NOT NULL, "metadata" jsonb, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_audit_logs_id" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_audit_logs_actorUserId" ON "audit_logs" ("actorUserId")`,
    );
    await queryRunner.query(
      `CREATE INDEX "IDX_audit_logs_createdAt" ON "audit_logs" ("createdAt")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX "public"."IDX_audit_logs_createdAt"`);
    await queryRunner.query(`DROP INDEX "public"."IDX_audit_logs_actorUserId"`);
    await queryRunner.query(`DROP TABLE "audit_logs"`);
  }
}
