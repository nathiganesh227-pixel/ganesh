# PLAZA — Phase 10 Audit & Pre-Flight Verification

**Audit Date**: 2026-09-24  
**Scope**: Verification of Phase 9 architecture, payment provider adapters, webhook security, database migrations, containerization, environment configuration, and gaps prior to Cloud Staging deployment.

---

## 1. Executive Summary & Verification Classification

Following the strict honesty guidelines for Phase 10, all claims from Phase 9 were audited directly against the codebase, active PostgreSQL database, and host environment.

| Component / Capability | Audit Status | Code / Architecture Reality |
|---|---|---|
| **Apple Liquid Glass UI** | **VERIFIED** | Clean, 0 lint warnings, 58/58 Flutter tests passing |
| **TypeORM Migrations** | **VERIFIED** | `InitialSchema` & `AddWebhookEventsTable` applied; `synchronize: false` verified |
| **Database-Backed Webhook Idempotency** | **VERIFIED** | `WebhookEventEntity` stores events; duplicate delivery returns `already_processed` |
| **HMAC-SHA256 Webhook Verification** | **VERIFIED** | Timing-safe verification; rejects forged signatures with HTTP 401 |
| **Client Request Idempotency (`Idempotency-Key`)** | **ARCHITECTURAL GAP** | Webhook events have idempotency, but client `POST /bookings/*` lacks `Idempotency-Key` tracking |
| **Razorpay Adapter Integration** | **ADAPTER READY** | Code implements paise conversion & HMAC logic, but uses test fallback keys (`rzp_test_plaza2026`) |
| **Real Razorpay Sandbox Live Run** | **BLOCKED — CREDENTIALS REQUIRED** | No valid merchant sandbox keys configured in host environment |
| **Twilio SMS Adapter** | **ADAPTER READY** | Formats messages and generates SIDs, but uses test credentials (`AC_test_account_sid_2026`) |
| **Real Twilio SMS Live Delivery** | **BLOCKED — CREDENTIALS REQUIRED** | No active Twilio SID / Auth Token configured in host environment |
| **Docker Staging Stack** | **CONFIGURED & READY** | `Dockerfile` and `docker-compose.staging.yml` exist, tested locally without cloud runtime |
| **Live Cloud Staging Host** | **NOT DEPLOYED** | No cloud provider CLI or remote container cluster currently provisioned |
| **Secrets Management in `.gitignore`** | **CRITICAL GAP IDENTIFIED** | Neither root `.gitignore` nor backend ignored `.env` or `dist/`; credentials exposed to git |

---

## 2. Detailed Findings

### A. What Phase 9 Actually Verified
1. **Cryptographic Webhook Signatures**:
   - `RazorpayAdapter.verifyWebhookSignature` computes `crypto.createHmac('sha256', secret).update(rawBody).digest('hex')` and compares with `crypto.timingSafeEqual`.
   - Live HTTP request with genuine HMAC returns 200 OK.
   - Forged signature returns 401 Unauthorized.
2. **Webhook Replay Attack Protection**:
   - `WebhookEventEntity` records each event ID in PostgreSQL.
   - Replaying the identical payload returns `{ "status": "ignored", "reason": "already_processed" }`.
3. **Database Migration Pipeline**:
   - Applied `1790253677580-InitialSchema.ts` (12 entity tables).
   - Applied `1790255429904-AddWebhookEventsTable.ts` (`webhook_events` table).
   - Verified that `synchronize: false` is honored when `DB_SYNC` is not set.
4. **State Machine Transitions**:
   - Tested transitions for `order.paid` (➔ `UPCOMING`), `payment.failed` (➔ `FAILED`), and `refund.processed` (➔ `CANCELLED`).
5. **Test Baseline**:
   - Flutter: 58/58 unit and widget tests passing.
   - NestJS: 27/27 unit and integration tests passing.

---

### B. What is Still Local-Only
1. **API Host**: The backend is running locally on `http://127.0.0.1:3000/api/v1` via macOS process. No remote public URL or cloud load balancer is actively proxying traffic.
2. **Database**: PostgreSQL 17 is running on local port `5432` (`plaza_dev`).
3. **Redis**: Not running locally as a daemon; only specified in `docker-compose.staging.yml`.

---

### C. What is Only Adapter-Ready vs Sandbox-Ready
1. **Razorpay Adapter**:
   - The adapter (`RazorpayAdapter`) is fully written and tested against the official Razorpay payload schema (`order.paid`, `payment.captured`, `payment.failed`, `refund.processed`).
   - However, without live merchant sandbox keys (`rzp_test_...` and API secret from dashboard.razorpay.com), the adapter operates in simulated mode.
   - Real checkout modal on mobile or web requires genuine merchant keys.
2. **Twilio SMS Adapter**:
   - The adapter (`TwilioSmsAdapter`) correctly formats E.164 phone numbers and message content.
   - Without a funded Twilio Account SID and Auth Token, actual network SMS delivery cannot be confirmed on physical cell phones.

---

### D. Architectural & Security Gaps to Address in Phase 10

1. **Client-Side Booking Idempotency (`Idempotency-Key` Header)**:
   - **Gap**: If a user on a mobile device taps "Pay & Book" and the connection drops during response delivery, the app might retry. Without an `Idempotency-Key` header on `POST /api/v1/bookings/*`, the server could create duplicate orders or trigger a seat conflict error.
   - **Remedy**: Implement an `IdempotencyService` and middleware/interceptor that stores client idempotency keys with user ID in PostgreSQL/memory, returning the cached result upon replay.

2. **Secrets & Git Hygiene**:
   - **Gap**: `.env` and `dist/` were not present in root `.gitignore`.
   - **Remedy**: Update `.gitignore` and create `backend/.gitignore` ensuring `.env`, `.env.*`, `dist/`, and `node_modules/` are strictly excluded from version control.

3. **Fallback Default Secrets in Code**:
   - **Gap**: `RazorpayAdapter` and `TwilioSmsAdapter` fall back to string constants (`'secret_test_plaza2026'`) if environment variables are missing.
   - **Remedy**: When `NODE_ENV === 'staging'` or `'production'`, missing keys must be reported with explicit warnings or throw startup configuration errors, ensuring unconfigured deployments fail fast.

4. **Dynamic Staging URL in Flutter**:
   - **Gap**: `EnvironmentConfig.baseUrl` had a hardcoded staging string (`'https://staging-api.plaza.app/api/v1'`).
   - **Remedy**: Support `--dart-define=PLAZA_API_URL=...` so any provisioned cloud staging endpoint can be targeted without modifying Dart source code.

---

## 3. Action Plan for Phase 10 Execution

1. **Implement Client `Idempotency-Key` Handling** on `POST /bookings/*` to guarantee zero duplicate bookings from network retries.
2. **Hardening Secrets**: Update `.gitignore` to prevent any accidental credential leakage.
3. **Real Cloud Staging Configuration**:
   - Prepare dynamic environment configuration and deployment templates for Render/Railway/Fly.io.
   - Document the exact cloud staging deployment procedure and blockers where cloud credentials are required.
4. **End-to-End Test Suite Expansion**:
   - Write comprehensive tests for `Idempotency-Key` client replays.
   - Write tests for inventory safety bounds (Movie seats, Sports turf double-booking, Event capacity non-negative).
   - Write tests for price tampering rejection across all 7 verticals.
5. **Create `PHASE_10_E2E_MATRIX.md` and `PHASE_10_REPORT.md`**.
