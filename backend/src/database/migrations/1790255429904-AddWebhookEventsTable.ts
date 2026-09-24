import { MigrationInterface, QueryRunner } from "typeorm";

export class AddWebhookEventsTable1790255429904 implements MigrationInterface {
    name = 'AddWebhookEventsTable1790255429904'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE "webhook_events" ("id" character varying NOT NULL, "provider" character varying NOT NULL, "eventType" character varying NOT NULL, "payload" jsonb NOT NULL, "status" character varying NOT NULL DEFAULT 'PROCESSED', "processedAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_4cba37e6a0acb5e1fc49c34ebfd" PRIMARY KEY ("id"))`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE "webhook_events"`);
    }

}
