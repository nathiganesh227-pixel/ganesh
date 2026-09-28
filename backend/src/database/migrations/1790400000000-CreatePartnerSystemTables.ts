import { MigrationInterface, QueryRunner } from "typeorm";

export class CreatePartnerSystemTables1790400000000 implements MigrationInterface {
    name = 'CreatePartnerSystemTables1790400000000'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // 1. partners table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partners" (
                "id" character varying NOT NULL,
                "legalName" character varying NOT NULL,
                "displayName" character varying NOT NULL,
                "partnerType" character varying NOT NULL DEFAULT 'restaurant',
                "status" character varying NOT NULL DEFAULT 'draft',
                "email" character varying NOT NULL,
                "phone" character varying NOT NULL,
                "city" character varying NOT NULL DEFAULT 'Hyderabad',
                "state" character varying NOT NULL DEFAULT 'Telangana',
                "address" text NOT NULL,
                "pinCode" character varying NOT NULL DEFAULT '500081',
                "website" character varying,
                "gstNumber" character varying,
                "panNumber" character varying,
                "rejectionReason" text,
                "suspensionReason" text,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partners_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partners_status" ON "partners" ("status")`);

        // 2. partner_users table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partner_users" (
                "id" character varying NOT NULL,
                "partnerId" character varying NOT NULL,
                "userId" character varying NOT NULL,
                "role" character varying NOT NULL DEFAULT 'partner_owner',
                "isActive" boolean NOT NULL DEFAULT true,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partner_users_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_users_partnerId" ON "partner_users" ("partnerId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_users_userId" ON "partner_users" ("userId")`);

        // 3. partner_businesses table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partner_businesses" (
                "id" character varying NOT NULL,
                "partnerId" character varying NOT NULL,
                "vertical" character varying NOT NULL,
                "name" character varying NOT NULL,
                "description" text NOT NULL,
                "address" text NOT NULL,
                "city" character varying NOT NULL DEFAULT 'Hyderabad',
                "contactPhone" character varying NOT NULL,
                "contactEmail" character varying NOT NULL,
                "status" character varying NOT NULL DEFAULT 'draft',
                "catalogEntityId" character varying,
                "rejectionReason" text,
                "metadata" jsonb,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partner_businesses_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_businesses_partnerId" ON "partner_businesses" ("partnerId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_businesses_status" ON "partner_businesses" ("status")`);

        // 4. partner_documents table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partner_documents" (
                "id" character varying NOT NULL,
                "partnerId" character varying NOT NULL,
                "documentType" character varying NOT NULL,
                "fileUrl" character varying NOT NULL,
                "fileName" character varying NOT NULL,
                "fileSize" integer NOT NULL DEFAULT 0,
                "status" character varying NOT NULL DEFAULT 'pending',
                "rejectionReason" text,
                "submittedAt" TIMESTAMP NOT NULL,
                "reviewedAt" TIMESTAMP,
                "reviewedBy" character varying,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partner_documents_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_documents_partnerId" ON "partner_documents" ("partnerId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_documents_status" ON "partner_documents" ("status")`);

        // 5. partner_approvals table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partner_approvals" (
                "id" character varying NOT NULL,
                "partnerId" character varying NOT NULL,
                "targetType" character varying NOT NULL,
                "targetId" character varying NOT NULL,
                "action" character varying NOT NULL,
                "actorId" character varying NOT NULL,
                "actorEmail" character varying NOT NULL,
                "actorRole" character varying NOT NULL,
                "reason" text,
                "comments" text,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partner_approvals_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_approvals_partnerId" ON "partner_approvals" ("partnerId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_approvals_targetId" ON "partner_approvals" ("targetId")`);

        // 6. partner_invitations table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partner_invitations" (
                "id" character varying NOT NULL,
                "partnerId" character varying NOT NULL,
                "invitedEmail" character varying NOT NULL,
                "invitedRole" character varying NOT NULL DEFAULT 'partner_staff',
                "invitationCode" character varying NOT NULL,
                "status" character varying NOT NULL DEFAULT 'pending',
                "invitedBy" character varying NOT NULL,
                "expiresAt" TIMESTAMP NOT NULL,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partner_invitations_id" PRIMARY KEY ("id"),
                CONSTRAINT "UQ_partner_invitations_code" UNIQUE ("invitationCode")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_invitations_partnerId" ON "partner_invitations" ("partnerId")`);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_invitations_invitedEmail" ON "partner_invitations" ("invitedEmail")`);

        // 7. partner_payout_profiles table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partner_payout_profiles" (
                "id" character varying NOT NULL,
                "partnerId" character varying NOT NULL,
                "accountHolderName" character varying NOT NULL,
                "bankName" character varying NOT NULL,
                "accountNumberMasked" character varying NOT NULL,
                "accountNumberEncrypted" character varying NOT NULL,
                "ifscCode" character varying NOT NULL,
                "payoutStatus" character varying NOT NULL DEFAULT 'pending_verification',
                "verifiedAt" TIMESTAMP,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partner_payout_profiles_id" PRIMARY KEY ("id"),
                CONSTRAINT "UQ_partner_payout_profiles_partnerId" UNIQUE ("partnerId")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_payout_profiles_partnerId" ON "partner_payout_profiles" ("partnerId")`);

        // 8. partner_audit_logs table
        await queryRunner.query(`
            CREATE TABLE IF NOT EXISTS "partner_audit_logs" (
                "id" character varying NOT NULL,
                "partnerId" character varying NOT NULL,
                "actorUserId" character varying NOT NULL,
                "actorEmail" character varying NOT NULL,
                "actorRole" character varying NOT NULL,
                "action" character varying NOT NULL,
                "resourceType" character varying NOT NULL,
                "resourceId" character varying NOT NULL,
                "metadata" jsonb,
                "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
                CONSTRAINT "PK_partner_audit_logs_id" PRIMARY KEY ("id")
            )
        `);
        await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_partner_audit_logs_partnerId" ON "partner_audit_logs" ("partnerId")`);

        // 9. Add partner columns to catalog & booking tables
        await queryRunner.query(`ALTER TABLE "restaurants" ADD COLUMN IF NOT EXISTS "partnerId" character varying`);
        await queryRunner.query(`ALTER TABLE "restaurants" ADD COLUMN IF NOT EXISTS "businessId" character varying`);
        await queryRunner.query(`ALTER TABLE "restaurants" ADD COLUMN IF NOT EXISTS "approvalStatus" character varying NOT NULL DEFAULT 'APPROVED'`);

        await queryRunner.query(`ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "partnerId" character varying`);
        await queryRunner.query(`ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "businessId" character varying`);
        await queryRunner.query(`ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "approvalStatus" character varying NOT NULL DEFAULT 'APPROVED'`);

        await queryRunner.query(`ALTER TABLE "activities" ADD COLUMN IF NOT EXISTS "partnerId" character varying`);
        await queryRunner.query(`ALTER TABLE "activities" ADD COLUMN IF NOT EXISTS "businessId" character varying`);
        await queryRunner.query(`ALTER TABLE "activities" ADD COLUMN IF NOT EXISTS "approvalStatus" character varying NOT NULL DEFAULT 'APPROVED'`);

        await queryRunner.query(`ALTER TABLE "hotels" ADD COLUMN IF NOT EXISTS "partnerId" character varying`);
        await queryRunner.query(`ALTER TABLE "hotels" ADD COLUMN IF NOT EXISTS "businessId" character varying`);
        await queryRunner.query(`ALTER TABLE "hotels" ADD COLUMN IF NOT EXISTS "approvalStatus" character varying NOT NULL DEFAULT 'APPROVED'`);

        await queryRunner.query(`ALTER TABLE "sports_venues" ADD COLUMN IF NOT EXISTS "partnerId" character varying`);
        await queryRunner.query(`ALTER TABLE "sports_venues" ADD COLUMN IF NOT EXISTS "businessId" character varying`);
        await queryRunner.query(`ALTER TABLE "sports_venues" ADD COLUMN IF NOT EXISTS "approvalStatus" character varying NOT NULL DEFAULT 'APPROVED'`);

        await queryRunner.query(`ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "partnerId" character varying`);
        await queryRunner.query(`ALTER TABLE "bookings" ADD COLUMN IF NOT EXISTS "businessId" character varying`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "bookings" DROP COLUMN IF EXISTS "businessId"`);
        await queryRunner.query(`ALTER TABLE "bookings" DROP COLUMN IF EXISTS "partnerId"`);
        await queryRunner.query(`ALTER TABLE "sports_venues" DROP COLUMN IF EXISTS "approvalStatus"`);
        await queryRunner.query(`ALTER TABLE "sports_venues" DROP COLUMN IF EXISTS "businessId"`);
        await queryRunner.query(`ALTER TABLE "sports_venues" DROP COLUMN IF EXISTS "partnerId"`);
        await queryRunner.query(`ALTER TABLE "hotels" DROP COLUMN IF EXISTS "approvalStatus"`);
        await queryRunner.query(`ALTER TABLE "hotels" DROP COLUMN IF EXISTS "businessId"`);
        await queryRunner.query(`ALTER TABLE "hotels" DROP COLUMN IF EXISTS "partnerId"`);
        await queryRunner.query(`ALTER TABLE "activities" DROP COLUMN IF EXISTS "approvalStatus"`);
        await queryRunner.query(`ALTER TABLE "activities" DROP COLUMN IF EXISTS "businessId"`);
        await queryRunner.query(`ALTER TABLE "activities" DROP COLUMN IF EXISTS "partnerId"`);
        await queryRunner.query(`ALTER TABLE "events" DROP COLUMN IF EXISTS "approvalStatus"`);
        await queryRunner.query(`ALTER TABLE "events" DROP COLUMN IF EXISTS "businessId"`);
        await queryRunner.query(`ALTER TABLE "events" DROP COLUMN IF EXISTS "partnerId"`);
        await queryRunner.query(`ALTER TABLE "restaurants" DROP COLUMN IF EXISTS "approvalStatus"`);
        await queryRunner.query(`ALTER TABLE "restaurants" DROP COLUMN IF EXISTS "businessId"`);
        await queryRunner.query(`ALTER TABLE "restaurants" DROP COLUMN IF EXISTS "partnerId"`);

        await queryRunner.query(`DROP TABLE IF EXISTS "partner_audit_logs"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "partner_payout_profiles"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "partner_invitations"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "partner_approvals"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "partner_documents"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "partner_businesses"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "partner_users"`);
        await queryRunner.query(`DROP TABLE IF EXISTS "partners"`);
    }
}
