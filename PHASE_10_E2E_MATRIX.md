# PLAZA — Phase 10 & 10B End-to-End Verification Matrix

Date: September 24, 2026  
Environment: Staging Engine (PostgreSQL 17, NestJS, Flutter 3.x)

---

## 1. Status Taxonomy
- **`VERIFIED`**: Full end-to-end flow tested and passing against running services and database.
- **`SANDBOX VERIFIED`**: Live interaction with third-party sandbox provider verified with genuine test credentials.
- **`ADAPTER VERIFIED`**: Production adapter architecture, signature verification, and error handling fully implemented and tested with mock/sandbox contracts; awaits live cloud API keys.
- **`MOCK ONLY`**: Mocked implementation only; no live provider or database interaction.
- **`BLOCKED`**: Third-party cloud service, API credentials, or CLI tooling unavailable in environment.
- **`NOT IMPLEMENTED`**: Feature not yet built.

---

## 2. End-to-End Verification Matrix

| Domain / Vertical | Feature Flow | Verification Method | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **System** | Service Health & Uptime (`/health`) | Live HTTP GET + Jest Unit Spec | **`VERIFIED`** | Responds in ~1.0ms with uptime, service name, version |
| **System** | Helmet Security Headers | Live HTTP curl inspection | **`VERIFIED`** | HSTS, nosniff, frameguard SAMEORIGIN, CSP intact |
| **System** | Rate Limiting (120 req/min) | Live HTTP curl inspection | **`VERIFIED`** | `X-RateLimit-Limit` & `X-RateLimit-Remaining` active |
| **System** | Correlation ID Tracing | Live HTTP curl inspection | **`VERIFIED`** | `X-Correlation-ID` generated per request |
| **Authentication**| JWT User Login & Token Issue | Live HTTP POST (`/auth/login`) | **`VERIFIED`** | bcrypt verification, returns signed JWT & user profile |
| **Authentication**| JWT Route Guard Protection | Live HTTP curl + Jest Spec | **`VERIFIED`** | Rejects unauthenticated requests with 401 Unauthorized |
| **Movies** | Discovery & Showtimes | Live HTTP GET (`/movies/:id/showtimes`) | **`VERIFIED`** | Returns theatres, showtimes, formats from DB |
| **Movies** | Seat Booking & Pricing Math | Live HTTP POST + Jest Spec | **`VERIFIED`** | Calculates `basePrice * seats + fees + tax`, rejects client overrides |
| **Movies** | Concurrency Seat Lock | Jest Spec (`phase8-reliability-security`) | **`VERIFIED`** | Prevents overlapping seat bookings in same showtime |
| **Dining** | Discovery & Filters | Flutter Widget Tests (9 tests) | **`VERIFIED`** | Cuisine filtering, restaurant details, seating views |
| **Dining** | Table Reservation & Guests | Live HTTP POST + Jest Spec | **`VERIFIED`** | Complimentary flow, validates party size & seating |
| **Events** | Discovery & Tiers | Flutter Widget Tests (10 tests) | **`VERIFIED`** | VIP/General pass tiers, date/venue information |
| **Events** | Inventory Boundary Enforcement | Jest Spec (`phase8-reliability-security`) | **`VERIFIED`** | Prevents booking when ticket count exceeds remaining capacity |
| **Activities** | Discovery & Slots | Flutter Widget Tests (8 tests) | **`VERIFIED`** | Package pricing, slot timing, instructor details |
| **Activities** | Booking & QR Pass | Jest Spec (`phase7`, `phase8`) | **`VERIFIED`** | Generates digital pass and QR code |
| **Shopping** | Discovery & Deals | Flutter Widget Tests (12 tests) | **`VERIFIED`** | Stores, categories, mall experiences, discounts |
| **Shopping** | Server-Side Cart Total | Jest Spec (`phase8-reliability-security`) | **`VERIFIED`** | Recalculates product prices, adds platform fee & GST |
| **Stays** | Hotel Discovery & Room Types | Flutter Widget Tests (10 tests) | **`VERIFIED`** | Amenities, night pricing, room selections |
| **Stays** | Nightly Pricing & Taxes | Live HTTP POST + Jest Spec | **`VERIFIED`** | Computes `pricePerNight * nights * rooms + 12% tax` |
| **Sports** | Court & Slot Discovery | Flutter Widget Tests (9 tests) | **`VERIFIED`** | Venue amenities, turf types, court schedules |
| **Sports** | Pessimistic Write Lock | Jest Spec (`phase8-reliability-security`) | **`VERIFIED`** | Prevents concurrent double-booking of same slot & date |
| **Client Idempotency** | `Idempotency-Key` Header | Live HTTP POST + DB verification | **`VERIFIED`** | Caches response; duplicate request returns identical booking without re-insert |
| **Client Idempotency** | Multi-Tenant Key Isolation | Jest Spec (`phase10-cloud-staging`) | **`VERIFIED`** | Composite key `${userId}:${idempotencyKey}` prevents cross-user pollution |
| **Bookings Wallet** | Unified 7-Vertical Aggregation | Flutter Widget Tests + Jest Spec | **`VERIFIED`** | Categorized into Upcoming, Active, Completed, Cancelled |
| **Bookings Wallet** | Owner-Only Cancellation | Jest Spec (`phase8`, `phase10`) | **`VERIFIED`** | Users can only cancel their own bookings (403 Forbidden otherwise) |
| **Payments** | Simulated Provider Fallback | Jest Spec (`phase9`, `phase10`) | **`VERIFIED`** | Completes simulated payments & refunds when keys absent |
| **Payments** | Razorpay Adapter Signature Verification | Jest Spec (`phase9-payments-webhooks`) | **`ADAPTER VERIFIED`** | HMAC-SHA256 signature verification passes; forged fails |
| **Payments** | Razorpay Live Sandbox Flow | N/A | **`BLOCKED`** | `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` required |
| **Webhooks** | Razorpay Webhook Replay Protection | Live HTTP POST (`/webhooks/razorpay`) | **`VERIFIED`** | Uses `webhook_events` table; duplicate yields `already_processed` |
| **Webhooks** | Razorpay Webhook Forgery Rejection | Live HTTP POST (`/webhooks/razorpay`) | **`VERIFIED`** | Invalid signature yields 401 Unauthorized |
| **Notifications** | Twilio SMS Adapter | Jest Spec (`phase9-payments-webhooks`) | **`ADAPTER VERIFIED`** | Formats booking SMS with QR pass directions; logs SID |
| **Notifications** | Twilio Live SMS Delivery | N/A | **`BLOCKED`** | `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN` required |
| **Cloud Deployment** | Render / Railway / Fly.io Public Cloud | N/A | **`BLOCKED`** | Cloud CLI binaries and API tokens not present on host; blueprints ready |
| **Database** | PostgreSQL 17 Migration Engine | TypeORM CLI + psql inspection | **`VERIFIED`** | 3 migrations executed cleanly (`InitialMigration`, `AddWebhookEvents`, `AddIdempotencyRecords`) |
| **Client Env Config**| Dynamic Staging Base URL | Flutter `EnvironmentConfig` | **`VERIFIED`** | Supports `--dart-define=PLAZA_API_URL=...` override |

---

## 3. Test Suite Summary
- **Flutter Test Suite**: **58 / 58 passing (100%)**
- **Flutter Analyze**: **0 issues found**
- **Backend Jest Test Suites**: **4 / 4 suites passing**
  - `phase7-integration.spec.ts`: 7 tests passing
  - `phase8-reliability-security.spec.ts`: 10 tests passing
  - `phase9-payments-webhooks.spec.ts`: 10 tests passing
  - `phase10-cloud-staging-e2e.spec.ts`: 9 tests passing
  - **Total Backend Tests: 36 / 36 passing (100%)**
