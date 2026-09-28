import { MigrationInterface, QueryRunner } from "typeorm";

export class EnhanceBookingAndLockTables1790600000000 implements MigrationInterface {
    name = 'EnhanceBookingAndLockTables1790600000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // 1. Indices on bookings
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_bookings_userId_status" ON "bookings" ("userId", "status")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_bookings_type_date" ON "bookings" ("type", "date")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_bookings_partnerId_businessId" ON "bookings" ("partnerId", "businessId")`);

        // 2. seat_locks table for temporary movie seat locking
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "seat_locks" (
                "id" character varying NOT NULL,
                "theatreId" character varying NOT NULL,
                "showtimeId" character varying NOT NULL,
                "seatId" character varying NOT NULL,
                "userId" character varying NOT NULL,
                "expiresAt" TIMESTAMP WITH TIME ZONE NOT NULL,
                "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
                CONSTRAINT "PK_seat_locks_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_seat_locks_theatre_show_seat" ON "seat_locks" ("theatreId", "showtimeId", "seatId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_seat_locks_expiresAt" ON "seat_locks" ("expiresAt")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_seat_locks_userId" ON "seat_locks" ("userId")`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS "seat_locks"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_bookings_partnerId_businessId"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_bookings_type_date"`);
        await queryRunner.query(`DROP INDEX IF EXISTS "IDX_bookings_userId_status"`);
    }
}
