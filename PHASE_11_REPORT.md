# PLAZA — Phase 11 Engineering & Verification Report

## Live Render Backend Integration, Environment Configuration & Resilient Fallback

**Date**: 2026-09-25  
**Target Environment**: Cloud Staging (Render)  
**Live API Base URL**: `https://plaza-api-o4sh.onrender.com/api/v1`  
**Swagger UI**: `https://plaza-api-o4sh.onrender.com/api/docs`  
**Branch**: `main`

---

## 1. Executive Summary

In Phase 11, the Flutter PLAZA application was successfully integrated with the live NestJS backend deployed on Render (`https://plaza-api-o4sh.onrender.com/api/v1`).

The integration was achieved while:
- Preserving the Apple-inspired Liquid Glass UI and all existing vertical experiences.
- Preserving local catalog fallback for read operations during network or cloud database unavailability.
- Preserving strict write-mutation safety (ensuring failing API bookings/cancellations do **not** mutate local data).
- Eliminating hardcoded URLs in UI screens by introducing a decoupled, `--dart-define`-driven `EnvironmentConfig`.
- Synchronizing authentication tokens application-wide across repository `ApiClient` instances.

> [!IMPORTANT]
> **Production Readiness Statement**: PLAZA is **NOT** yet declared fully production-ready. While the live Render NestJS server is running, healthy, rate-limited, and protected by JWT auth guards, the cloud database on Render has not yet completed live table migrations or seeding (catalog queries return HTTP 500 `Internal server error`). PLAZA's resilient repository architecture gracefully absorbs this via local catalog fallback, but cloud staging database provisioning remains the critical next blocker before real user traffic can be served from the cloud DB.

---

## 2. Live Render Connectivity & Endpoint Audit Matrix

Direct HTTP and repository-level probing was performed directly against `https://plaza-api-o4sh.onrender.com/api/v1` using `tool/test_live_render_connectivity.dart`.

| Endpoint | Method | Live HTTP Status | Latency | Correlation ID Header | Live Behavior Verified |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/health` | `GET` | **200 OK** | 601 ms | `plz_1790317412356_zg2ab` | System healthy: `{"status":"UP","service":"plaza-backend","version":"1.0.0"}` |
| `/api/docs` | `GET` | **200 OK** | 412 ms | *N/A (Static Asset)* | Swagger UI OpenAPI documentation is live and renderable |
| `/auth/login` (validation) | `POST` | **400 Bad Request** | 335 ms | `plz_1790317416948_r6t7h` | ValidationPipe rejected malformed body: `["email must be an email","password should not be empty"]` |
| `/auth/me` (no token) | `GET` | **401 Unauthorized** | 322 ms | `plz_1790317416333_5ezt1` | Guard rejected unauthenticated call: `"Authentication token is required"` |
| `/auth/me` (invalid token) | `GET` | **401 Unauthorized** | 278 ms | `plz_1790317416611_baqax` | JWT guard rejected invalid token: `"Your session has expired or is invalid. Please log in again."` |
| `/auth/demo-login` | `POST` | **500 Server Error** | 444 ms | `plz_1790317417380_vthrw` | Database connection pending on Render instance; caught cleanly |
| `/movies` | `GET` | **500 Server Error** | 329 ms | `plz_1790317412728_qg1di` | Cloud DB unseeded; Flutter `ApiMovieRepository` triggers local catalog fallback |
| `/dining` | `GET` | **500 Server Error** | 785 ms | `plz_1790317413209_jrm3c` | Cloud DB unseeded; Flutter `ApiDiningRepository` triggers local restaurant fallback |
| `/events` | `GET` | **500 Server Error** | 572 ms | `plz_1790317414025_17vdk` | Cloud DB unseeded; Flutter `ApiEventRepository` triggers local events fallback |
| `/activities` | `GET` | **500 Server Error** | 315 ms | `plz_1790317414405_09zrw` | Cloud DB unseeded; Flutter `ApiActivityRepository` triggers local activities fallback |
| `/shopping` | `GET` | **500 Server Error** | 468 ms | `plz_1790317414880_am0p9` | Cloud DB unseeded; Flutter `ApiShoppingRepository` triggers local products fallback |
| `/stays` | `GET` | **500 Server Error** | 349 ms | `plz_1790317415180_bf455` | Cloud DB unseeded; Flutter `ApiStayRepository` triggers local hotels fallback |
| `/sports` | `GET` | **500 Server Error** | 312 ms | `plz_1790317415535_9lj95` | Cloud DB unseeded; Flutter `ApiSportsRepository` triggers local sports venues fallback |
| `/search?q=kalki` | `GET` | **500 Server Error** | 460 ms | `plz_1790317416000_gj0h8` | Cloud DB unseeded; Flutter `ApiSearchRepository` triggers local search fallback |

---

## 3. Flutter Environment & Architecture Verification

### 3.1 Environment Configuration (`EnvironmentConfig`)
- **Configurable via Dart Define**:
  ```bash
  flutter run --dart-define=PLAZA_API_URL=https://plaza-api-o4sh.onrender.com/api/v1
  ```
- **Environment Structure**:
  - `AppEnvironment.dev`: defaults to `http://127.0.0.1:3000/api/v1`
  - `AppEnvironment.staging`: defaults to `https://plaza-api-o4sh.onrender.com/api/v1`
  - `AppEnvironment.prod`: defaults to `https://plaza-api-o4sh.onrender.com/api/v1`
- **Zero UI Coupling**: No UI screen references `https://...`; all screens consume repositories injected via `RepositoryProvider`.

### 3.2 ApiClient Resilience & Auth Propagation
- **Global Auth Token Synchronization**: When `AuthService.login()` or `AuthService.demoLogin()` is executed, `ApiClient.setGlobalAuthToken(token)` synchronizes the token across all independent repository clients (`ApiMovieRepository`, `ApiBookingRepository`, etc.).
- **Header Injection**: Requests automatically attach `Authorization: Bearer <token>` when a token exists.
- **Envelope Unwrapping**: NestJS responses structured as `{ success, data, message, statusCode }` are cleanly unpacked into `ApiResponse.success(data)`.
- **Structured Error Extraction**: Errors returned as JSON strings or validation arrays are parsed into human-readable messages (e.g., `HTTP 400: email must be an email, password should not be empty`).
- **Resilience**: `SocketException`, `TimeoutException`, and HTTP 4xx/5xx are caught without unhandled exceptions.

### 3.3 Mutation Safety
In accordance with PLAZA architectural principles:
- Read/catalog operations gracefully fall back to local seed data when the API is unreachable or reports an error.
- Write/mutation operations (e.g., `createReservation`, `createBooking`, `bookSlot`, `cancelBooking`) strictly fail (`return false;`) and do **not** mutate local state when the API call fails.

---

## 4. Test & Verification Results

### 4.1 Flutter Unit & Integration Test Suites
- **Command**: `flutter test`
- **Total Test Suites**: 8 suites
- **Total Tests Passed**: **77 / 77 passed** (0 failures)
  - `test/phase11_live_render_integration_test.dart`: **19 / 19 passed**
  - `test/phase7_full_integration_test.dart`: passed
  - `test/phase6_backend_repository_test.dart`: passed
  - `test/phase5_unified_experience_test.dart`: passed
  - `test/movies_booking_test.dart`: passed
  - `test/dining_events_activities_test.dart`: passed
  - `test/shopping_stays_sports_test.dart`: passed
  - `test/widget_test.dart`: passed

### 4.2 Flutter Code Analysis
- **Command**: `flutter analyze`
- **Result**: **No issues found!** (Clean analysis, 0 warnings, 0 errors, 0 lints)

### 4.3 Backend Test Suite
- **Command**: `npm test` inside `backend/`
- **Total Test Suites**: 4 suites
- **Total Tests Passed**: **36 / 36 passed** (0 failures)

---

## 5. Security & Secret Safeguards

- No Razorpay live/test secret keys are bundled in Flutter code.
- No Twilio live/test authentication tokens are bundled in Flutter code.
- No database credentials or passwords are committed to version control.
- Rate limiting (120 req/min) and Correlation IDs (`x-correlation-id`) are verified in live Render response headers.

---

## 6. Exact Next Blockers for Cloud Staging

1. **Render PostgreSQL Provisioning & Migration**:
   - The NestJS web service is active on Render, but requests to entity repositories return HTTP 500 because the Render PostgreSQL instance has not been attached via `DATABASE_URL` in the Render dashboard, or table migrations (`DB_MIGRATIONS_RUN=true`) have not yet executed in the cloud database.
   - Once `DATABASE_URL` is configured in Render environment variables, the updated `app.module.ts` will automatically connect with SSL enabled and auto-run migrations.
2. **Third-Party Sandbox Credentials (Razorpay & Twilio)**:
   - Real Razorpay sandbox API keys and Twilio credentials remain pending user provision in cloud staging environment variables. Simulated adapters handle payments and SMS notifications safely in the interim.
