# PLAZA — Production Readiness & Deployment Checklist

This document defines the strict pre-flight, security, reliability, and deployment procedures required for promoting the **PLAZA** consumer application (Flutter Client) and API platform (NestJS + PostgreSQL 17) to staging and production environments.

---

## 1. Database & Migrations

- [x] **Strict Disablement of `synchronize`**:
  - `synchronize: false` is enforced in `app.module.ts` and `data-source.ts`. Schema synchronization is strictly forbidden in staging and production to prevent catastrophic data loss.
- [x] **Version-Controlled Migrations**:
  - All schema evolutions must be generated via `npm run migration:generate --name=<DescriptiveName>` and reviewed by engineering before deployment.
- [x] **Rollback Verification (`migration:revert`)**:
  - Every migration must have a fully tested, idempotent `down()` method verified against an active PostgreSQL instance.
- [x] **Deterministic Seeding (`npm run seed`)**:
  - Seeds are decoupled from production runtime boot. Seeds must only populate static lookup data (theatres, categories) or realistic catalog fixtures in non-production environments.
- [ ] **Connection Pooling & SSL**:
  - Production `TypeOrmModule` must configure `ssl: { rejectUnauthorized: true }` and pool bounds (`max: 25`, `idleTimeoutMillis: 30000`).

---

## 2. Authentication, Authorization & Cryptography

- [x] **Bcrypt Password Hashing**:
  - Minimum salt rounds = 10 (`bcrypt.genSalt(10)`). Passwords are never stored or logged in plain text.
- [x] **JWT Cryptographic Hardening**:
  - Access tokens signed with minimum 256-bit entropy (`JWT_SECRET`).
  - Production tokens enforce 7-day expiration (`expiresIn: '7d'`) with claims (`sub`, `email`, `role`).
- [x] **Multi-Tenant Data Isolation & Ownership Validation**:
  - `JwtAuthGuard` enforced across all sensitive endpoints (`/bookings/:id`, `/plans/:id`, `/notifications/:id`).
  - Strict ownership check: Service layer enforces `item.userId === req.user.sub`; unauthorized access or cancellation throws `403 ForbiddenException`.
  - Demo/fallback user injection is strictly disabled when `NODE_ENV === 'production'`.

---

## 3. Server-Side Price Authority & Financial Integrity

- [x] **Absolute Server Recalculation**:
  - Client-submitted `totalPrice` or discount amounts are completely ignored across all 7 verticals (Movies, Dining, Events, Activities, Shopping, Stays, Sports).
  - Totals are computed exclusively from database entity pricing, verified tax rates, and fixed platform convenience fees:
    - **Movies**: `seatPrice * count + convenienceFee (₹70) + 5% GST`
    - **Stays**: `roomPrice * nights * rooms + addOns + 12% luxury tax`
    - **Shopping**: `∑(itemPrice + variantDelta) * qty + ₹29 platform fee + 5% GST`
    - **Events**: `tierPrice * qty + 5% fee`
    - **Sports**: `courtPrice + addOns + ₹50 fee`
    - **Activities**: `packagePrice * people + addOns + 18% GST`
    - **Dining**: Complimentary table reservations (₹0.00)
- [x] **Payment Gateway Abstraction (`PaymentService`)**:
  - Transaction authorization, settlement tokens, and automated refunds tied to booking lifecycle.
  - Payment metadata (`paymentId`, `transactionRef`, `status`) persisted inside `booking.metadata`.

---

## 4. Concurrency & High-Contention Locking

- [x] **Transactional Boundary Enforcement**:
  - All booking operations wrapped inside database transactions (`dataSource.transaction`).
- [x] **Pessimistic Locking on High-Contention Venues**:
  - Sports courts utilize `pessimistic_write` locks during conflict verification to eliminate race conditions.
- [x] **Seat Collision & Double-Booking Guards**:
  - Overlapping movie seat selections in identical showtimes are blocked with `409 ConflictException`.
  - Same-day court bookings for overlapping slots are rejected with `409 ConflictException`.
  - Event ticket stock decrements atomically; orders exceeding `remainingCount` fail immediately.

---

## 5. API Hardening & Network Security

- [x] **Security Headers (`helmet`)**:
  - HTTP headers hardened with standard CSP, HSTS, X-Frame-Options, X-Content-Type-Options, and Referrer-Policy.
- [x] **Rate Limiting (`@nestjs/throttler`)**:
  - Global rate limiter configured at 120 requests/minute per client IP (production recommended: 60 req/min for write routes).
- [x] **Strict CORS Whitelisting**:
  - Wildcard `*` disabled in production. Explicitly whitelist verified app bundle domains and mobile URL schemes.
- [x] **Request Body Size Limits**:
  - Express JSON payload bounded to `2mb` (production: `1mb`) to prevent JSON-bomb DoS attacks.
- [x] **Correlation ID Tracing (`LoggingMiddleware`)**:
  - Every inbound HTTP request tagged with an `X-Correlation-ID` header; logs record method, path, status, and duration in milliseconds.

---

## 6. Client Architecture & Resilience (Flutter)

- [x] **Write Mutation Non-Fallback Policy**:
  - Catalog and discovery read operations gracefully fall back to local cached data for seamless offline browsing.
  - Write mutations (`createOrder`, `bookSlot`, `createReservation`, `createBooking`, `bookTickets`, `cancelBooking`) strictly fail (`return false` / show error) when the server rejects or is unreachable. No silent mock writes in production!
- [x] **Zero Lint Issues**:
  - `flutter analyze` passes with 0 warnings or errors.
- [x] **Full Test Suite Coverage**:
  - 58/58 Flutter tests passing across all features and navigation flows.

---

## 7. Deployment Runbook

### Pre-Deployment Checks:
1. Verify database target:
   ```bash
   export DB_HOST="prod-primary-db.plaza.internal"
   export DB_SYNC="false"
   ```
2. Run database migrations:
   ```bash
   cd backend
   npm run build
   npm run migration:run
   ```
3. Execute unit & integration suites:
   ```bash
   npm test
   cd ..
   flutter test
   ```

### Staging Verification:
- [ ] Confirm Swagger UI is restricted or disabled in production (`/api/docs`).
- [ ] Execute health probe:
  ```bash
  curl -I http://localhost:3000/api/v1/health
  ```
- [ ] Verify correlation IDs are echoed in response headers (`x-correlation-id`).
- [ ] Verify 401 Unauthorized returned when requesting `/api/v1/bookings` without Bearer token.
- [ ] Verify 403 Forbidden returned when User A attempts to view User B's booking.

### Post-Deployment Monitoring:
- Monitor PostgreSQL connection pool saturation and query latency.
- Monitor Throttler 429 Too Many Requests alerts.
- Monitor payment gateway webhook reconciliation queues.
