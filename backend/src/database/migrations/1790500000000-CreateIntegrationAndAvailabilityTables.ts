import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateIntegrationAndAvailabilityTables1790500000000 implements MigrationInterface {
    name = 'CreateIntegrationAndAvailabilityTables1790500000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // 1. integration_mappings table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "integration_mappings" (
                "id" character varying NOT NULL,
                "provider" character varying NOT NULL,
                "providerEntityId" character varying NOT NULL,
                "plazaEntityId" character varying NOT NULL,
                "vertical" character varying NOT NULL,
                "partnerId" character varying,
                "syncStatus" character varying NOT NULL DEFAULT 'SYNCED',
                "lastSyncedAt" TIMESTAMP WITH TIME ZONE,
                "lastSuccessfulSyncAt" TIMESTAMP WITH TIME ZONE,
                "metadata" jsonb,
                "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
                CONSTRAINT "PK_integration_mappings_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_integration_mappings_provider" ON "integration_mappings" ("provider")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_integration_mappings_providerEntityId" ON "integration_mappings" ("providerEntityId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_integration_mappings_plazaEntityId" ON "integration_mappings" ("plazaEntityId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_integration_mappings_vertical" ON "integration_mappings" ("vertical")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_integration_mappings_partnerId" ON "integration_mappings" ("partnerId")`);

        // 2. integration_sync_runs table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "integration_sync_runs" (
                "id" character varying NOT NULL,
                "provider" character varying NOT NULL,
                "vertical" character varying NOT NULL,
                "status" character varying NOT NULL DEFAULT 'IN_PROGRESS',
                "recordsRead" integer NOT NULL DEFAULT 0,
                "recordsCreated" integer NOT NULL DEFAULT 0,
                "recordsUpdated" integer NOT NULL DEFAULT 0,
                "recordsSkipped" integer NOT NULL DEFAULT 0,
                "recordsFailed" integer NOT NULL DEFAULT 0,
                "errorSummary" text,
                "correlationId" character varying,
                "startedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
                "completedAt" TIMESTAMP WITH TIME ZONE,
                "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
                CONSTRAINT "PK_integration_sync_runs_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_integration_sync_runs_provider" ON "integration_sync_runs" ("provider")`);

        // 3. Add canonical source and availability metadata to catalog tables idempotently
        const tables = ['restaurants', 'events', 'activities', 'hotels', 'sports_venues', 'products', 'movie_shows'];
        for (const table of tables) {
            await queryRunner.query(`
                ALTER TABLE "${table}"
                ADD COLUMN IF NOT EXISTS "source" character varying DEFAULT 'ADMIN',
                ADD COLUMN IF NOT EXISTS "availabilityStatus" character varying DEFAULT 'AVAILABLE',
                ADD COLUMN IF NOT EXISTS "availabilityUpdatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now()
            `);
        }
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        const tables = ['restaurants', 'events', 'activities', 'hotels', 'sports_venues', 'products', 'movie_shows'];
        for (const table of tables) {
            await queryRunner.query(`ALTER TABLE "${table}" DROP COLUMN IF EXISTS "availabilityUpdatedAt"`);
            await queryRunner.query(`ALTER TABLE "${table}" DROP COLUMN IF EXISTS "availabilityStatus"`);
            await queryRunner.query(`ALTER TABLE "${table}" DROP COLUMN IF EXISTS "source"`);
        }
        await queryRunner.query(`DROP TABLE IF EXISTS "integration_sync_runs"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "integration_mappings"`);
    }
}
