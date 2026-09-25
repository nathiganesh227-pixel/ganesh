import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddMovieShowManagementSchema1790270000000 implements MigrationInterface {
  name = 'AddMovieShowManagementSchema1790270000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Extend theatres table
    await queryRunner.query(
      `ALTER TABLE "theatres" ADD COLUMN IF NOT EXISTS "city" character varying NOT NULL DEFAULT 'Hyderabad'`,
    );
    await queryRunner.query(
      `ALTER TABLE "theatres" ADD COLUMN IF NOT EXISTS "address" character varying`,
    );
    await queryRunner.query(
      `ALTER TABLE "theatres" ADD COLUMN IF NOT EXISTS "isActive" boolean NOT NULL DEFAULT true`,
    );

    // 2. Create screens table
    await queryRunner.query(
      `CREATE TABLE IF NOT EXISTS "screens" (
        "id" character varying NOT NULL,
        "theatreId" character varying NOT NULL,
        "name" character varying NOT NULL,
        "screenType" character varying NOT NULL DEFAULT 'standard',
        "capacity" integer NOT NULL,
        "seatLayout" jsonb,
        "isActive" boolean NOT NULL DEFAULT true,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_screens_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_screens_theatreId" ON "screens" ("theatreId")`,
    );

    // 3. Create movie_shows table
    await queryRunner.query(
      `CREATE TABLE IF NOT EXISTS "movie_shows" (
        "id" character varying NOT NULL,
        "movieId" character varying NOT NULL,
        "theatreId" character varying NOT NULL,
        "screenId" character varying NOT NULL,
        "showDate" character varying NOT NULL,
        "startTime" character varying NOT NULL,
        "format" character varying NOT NULL DEFAULT '2D',
        "language" character varying NOT NULL DEFAULT 'Telugu',
        "pricing" jsonb NOT NULL,
        "seatAvailability" jsonb,
        "status" character varying NOT NULL DEFAULT 'active',
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_movie_shows_id" PRIMARY KEY ("id")
      )`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_movie_shows_movieId" ON "movie_shows" ("movieId")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_movie_shows_theatreId" ON "movie_shows" ("theatreId")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_movie_shows_screenId" ON "movie_shows" ("screenId")`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "IDX_movie_shows_showDate" ON "movie_shows" ("showDate")`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_movie_shows_showDate"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_movie_shows_screenId"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_movie_shows_theatreId"`);
    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_movie_shows_movieId"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "movie_shows"`);

    await queryRunner.query(`DROP INDEX IF EXISTS "IDX_screens_theatreId"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "screens"`);

    await queryRunner.query(`ALTER TABLE "theatres" DROP COLUMN IF EXISTS "isActive"`);
    await queryRunner.query(`ALTER TABLE "theatres" DROP COLUMN IF EXISTS "address"`);
    await queryRunner.query(`ALTER TABLE "theatres" DROP COLUMN IF EXISTS "city"`);
  }
}
