import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPublicationLifecycleToAllVerticals1790280000000 implements MigrationInterface {
  name = 'AddPublicationLifecycleToAllVerticals1790280000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "restaurants" ADD COLUMN IF NOT EXISTS "isPublished" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "isPublished" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "activities" ADD COLUMN IF NOT EXISTS "isPublished" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "products" ADD COLUMN IF NOT EXISTS "isPublished" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "hotels" ADD COLUMN IF NOT EXISTS "isPublished" boolean NOT NULL DEFAULT true`,
    );
    await queryRunner.query(
      `ALTER TABLE "sports_venues" ADD COLUMN IF NOT EXISTS "isPublished" boolean NOT NULL DEFAULT true`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "sports_venues" DROP COLUMN IF EXISTS "isPublished"`);
    await queryRunner.query(`ALTER TABLE "hotels" DROP COLUMN IF EXISTS "isPublished"`);
    await queryRunner.query(`ALTER TABLE "products" DROP COLUMN IF EXISTS "isPublished"`);
    await queryRunner.query(`ALTER TABLE "activities" DROP COLUMN IF EXISTS "isPublished"`);
    await queryRunner.query(`ALTER TABLE "events" DROP COLUMN IF EXISTS "isPublished"`);
    await queryRunner.query(`ALTER TABLE "restaurants" DROP COLUMN IF EXISTS "isPublished"`);
  }
}
