# PLAZA Phase 8: Production Reliability, Security Audit & E2E Verification

**Date**: 2026-09-24  
**Auditor**: Antigravity Automated Verification Agent  
**Scope**: Flutter Mobile App, NestJS Modular Monolith API, PostgreSQL 17 Database, TypeORM Persistence Layer.

---

## Executive Summary

Phase 7 successfully established swappable repository abstractions, synchronized 7-vertical seed data, added basic JWT auth, and proved sports court concurrency locking. However, an exhaustive code-level audit reveals several critical production blockers and architectural vulnerabilities that must be resolved in Phase 8:

1. **Database Schema Synchronization**: The backend TypeORM connection is currently configured with `synchronize: true` in `app.module.ts`. There are no automated TypeORM migration files or CLI migration runners configured in `package.json`. In production, this can lead to accidental data loss or breaking schema alterations.
2. **Authorization / Data Isolation Leak**: `BookingsController.findOne(id)` and `cancel(id)` do not verify that the authenticated user actually owns the booking record. Any logged-in user with a valid JWT could view or cancel another user's booking pass if they know the booking ID.
3. **Silent Local Fallback on Mutation**: In Flutter's `Api*Repository` implementations (such as `ApiDiningRepository`, `ApiShoppingRepository`, `ApiStayRepository`, `ApiActivityRepository`, `ApiEventRepository`), when an API booking call fails, the code silently catches the error and executes `_fallback.create*(...)` which returns `true` or mocks success locally. While silent fallback is acceptable for browsing read-only catalog data, mutations (purchases, reservations, cancellations) **must never** silently succeed against fake local data.
4. **Concurrency Locking Limited to Sports**: Concurrency control and inventory decrementation are currently only enforced with pessimistic locking on Sports courts. Movies seat collisions, Events ticket tiers, Shopping inventory, Stays room inventory, Activities slot caps, and Dining table slots require transactional concurrency controls and boundary checks.
5. **Client-Side Pricing Vulnerability**: While server recalculation was drafted for stays and shopping, several endpoints still rely partially on payload metadata without centralized server-authoritative price calculation routines, and no payment state machine exists.
6. **Missing Security Middlewares**: Helmet security headers, CORS origin whitelisting, and API rate limiting (`@nestjs/throttler`) are absent from `main.ts`.
7. **Test Coverage Deficit**: The backend currently has only 5 Jest tests covering basic bcrypt and utility functions. Broad integration, authorization, concurrency, and lifecycle tests must be implemented.

---

## Detailed Audit by Subsystem

### 1. Flutter Mobile Architecture
- **State Management**: `PlazaGlobalState` acts as the single source of truth for local notifications, user rewards points, and offline bookings wallet.
- **Repository Provider**: `RepositoryProvider` provides centralized access to the 7 verticals.
- **Resiliency & Fallbacks**:
  - *Read operations*: Safe and seamless. Catalogs fall back to local mock data if the API daemon is down.
  - *Write operations*: **Vulnerable**. Methods like `createOrder`, `createBooking`, and `createReservation` fall back to local in-memory storage, misleading the user into believing a remote reservation succeeded.

### 2. NestJS Backend Architecture & Security
- **Controllers & DTOs**:
  - `AuthDto` handles registration and login with `class-validator` annotations (`@IsEmail()`, `@MinLength(6)`).
  - Validation pipe in `main.ts` uses `whitelist: true, transform: true`.
  - Missing: Rate limiter against brute-force attacks on `/auth/login` and `/auth/register`.
  - Missing: Helmet HTTP security headers.
  - Missing: CORS whitelist (currently permits all origins via `app.enableCors()`).
- **Authentication**:
  - Passwords hashed with `bcrypt` (10 rounds).
  - Stateless JWT issued with configurable secret and expiry.
  - `JwtAuthGuard` applied to `/bookings` endpoints, `/plans`, `/rewards`, `/notifications`.
- **Authorization**:
  - `BookingsController.findAll` scopes to `req.user.sub`.
  - `BookingsController.findOne(id)` and `BookingsController.cancel(id)` **do not** check `booking.userId === req.user.sub`.

### 3. Database & Persistence Layer
- **PostgreSQL 17**: Running locally on port 5432 with `plaza_dev`.
- **TypeORM Entities**:
  - Entities defined: `User`, `MovieEntity`, `TheatreEntity`, `RestaurantEntity`, `EventEntity`, `ActivityEntity`, `ProductEntity`, `HotelEntity`, `SportsVenueEntity`, `BookingEntity`, `PlanEntity`, `RewardEntity`, `NotificationEntity`.
- **TypeORM Synchronization**:
  - `app.module.ts` sets `synchronize: true`. Must be set to `false` for production/staging, with automated migrations.
- **Indexes**:
  - Primary keys are indexed. Foreign keys and search fields (such as `userId`, `status`, `createdAt`, `category`) lack explicit composite indexes.

### 4. Booking State Machine & Lifecycle
- `BookingStatus` enum: `upcoming`, `active`, `completed`, `cancelled`.
- Missing explicit transitional validation (e.g. preventing `CANCELLED -> COMPLETED`).
- Missing simulated `PaymentService` abstraction linking booking creation with payment confirmation.

---

## Phase 8 Action Plan

1. **Database Migration Safety**:
   - Implement standalone TypeORM DataSource (`backend/src/database/data-source.ts`).
   - Add migration scripts: `npm run migration:generate`, `npm run migration:run`, `npm run migration:revert`.
   - Generate initial migration for current schema and test running on a clean database.
   - Configure `synchronize: false` for production.
2. **Security Hardening**:
   - Install and configure `@nestjs/throttler` for rate limiting (auth, bookings, search).
   - Install and configure `helmet` for HTTP security headers.
   - Restrict CORS origins.
3. **Authorization & Data Isolation**:
   - Add strict ownership checks: ensure users can only view, modify, or cancel their own bookings, plans, and notifications.
   - Implement unit and integration tests proving User A is denied access to User B's resources.
4. **Local Fallback Safety**:
   - Update Flutter repositories so read operations gracefully fall back, but write/mutation operations throw network errors when the backend is unreachable.
5. **Concurrency & Inventory Guarding**:
   - Implement and test concurrency controls across all 7 verticals.
6. **Booking State Machine & Server-Side Price Authority**:
   - Implement `PaymentService` abstraction.
   - Formalize booking state machine transitions.
   - Server strictly recalculates totals, ignoring client inputs.
7. **Comprehensive Testing**:
   - Expand backend tests covering auth, ownership, concurrency, pricing, and error handling.
   - Verify all Flutter tests continue passing (0 analyzer issues).
