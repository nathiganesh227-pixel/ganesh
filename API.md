# PLAZA REST API Specification

- **Base URL (Local)**: `http://127.0.0.1:3000/api/v1`
- **Swagger Documentation**: `http://127.0.0.1:3000/api/docs`

All requests and responses use JSON. Successful responses return:
```json
{
  "success": true,
  "data": { ... },
  "message": null,
  "statusCode": 200
}
```
Error responses return:
```json
{
  "success": false,
  "data": null,
  "message": "...",
  "statusCode": 400
}
```

---

## 1. Authentication & Users

### `POST /auth/register`
Registers a new PLAZA user with bcrypt password hashing.
- **Body**:
  ```json
  {
    "name": "Jane Doe",
    "email": "jane@example.com",
    "password": "Password123!",
    "phone": "+91 98765 43210"
  }
  ```
- **Returns**: User entity + signed JWT token.

### `POST /auth/login`
Authenticates a user and returns a signed JWT.
- **Body**:
  ```json
  {
    "email": "jane@example.com",
    "password": "Password123!"
  }
  ```

### `POST /auth/demo-login`
Instant one-tap login using the pre-seeded demo user (`usr_default_1`).

### `GET /auth/me`
Requires `Bearer <token>`. Returns currently authenticated profile and loyalty rewards points.

---

## 2. Movies & Showtimes

### `GET /movies`
- **Query Params**:
  - `q` (optional): Search query matching title, director, or genre.
- **Returns**: Array of `Movie` objects.

### `GET /movies/:id`
- Returns detailed movie information including synopsis, cast, formats, and rating.

### `GET /movies/:id/showtimes`
- Returns available theatres and showtimes for the movie.

---

## 3. Dining

### `GET /dining`
- **Query Params**:
  - `cuisine` (optional): Filter by cuisine type.
- **Returns**: Array of `Restaurant` objects.

### `GET /dining/:id`
- Returns detailed restaurant profile, menu dishes, available table slots, and reviews.

---

## 4. Events

### `GET /events`
- **Query Params**:
  - `category` (optional): Filter by event category.
- **Returns**: Array of live `PlazaEvent` objects.

### `GET /events/:id`
- Returns event details, performers, venue, and ticket tiers.

---

## 5. Activities

### `GET /activities`
- **Query Params**:
  - `category` (optional): Filter by activity category.
- **Returns**: Array of `PlazaActivity` objects.

### `GET /activities/:id`
- Returns packages, safety guidelines, and slot availability.

---

## 6. Shopping

### `GET /shopping`
- **Query Params**:
  - `category` (optional): Filter by shopping category.
- **Returns**: Array of `Product` objects.

### `GET /shopping/:id`
- Returns product specifications, variants, and stock status.

---

## 7. Stays

### `GET /stays`
- **Query Params**:
  - `category` (optional): Filter by stay type.
- **Returns**: Array of luxury `Hotel` objects.

### `GET /stays/:id`
- Returns room types, amenities, and add-on services.

---

## 8. Sports

### `GET /sports`
- **Query Params**:
  - `sport` (optional): Filter by supported sport.
- **Returns**: Array of `SportsVenue` objects.

### `GET /sports/:id`
- Returns court slots, rules, and equipment rentals.

---

## 9. Transactional & Concurrency-Safe Bookings Engine

All booking endpoints require `Bearer <token>` (`JwtAuthGuard`).
Every response includes security headers (Helmet CSP/HSTS) and an `X-Correlation-ID` header.
All booking mutation routes accept an optional `Idempotency-Key: <uuid>` header. Duplicate requests with the same key replay the cached response immediately, preventing double booking or duplicate payment processing.
Protected endpoints enforce strict ownership checks; accessing or cancelling another user's resource results in `403 Forbidden`.

### `GET /bookings`
- Returns unified bookings for the authenticated user (`req.user.sub`).
- **Query Params**: `status` (`upcoming`, `active`, `completed`, `cancelled`).

### `GET /bookings/:id`
- Requires `Bearer <token>`.
- Returns detailed booking record. If `booking.userId !== req.user.sub`, returns `403 Forbidden`.

### `DELETE /bookings/:id`
- Requires `Bearer <token>`.
- Cancels an existing booking pass. If `booking.userId !== req.user.sub`, returns `403 Forbidden`.
- **State Machine**: Only bookings in `UPCOMING` or `ACTIVE` states can be cancelled. Cancelling an already cancelled booking returns `400 Bad Request`.
- **Automated Refund**: When cancelled, triggers simulated refund via `PaymentService` for any paid booking and records refund metadata.

### `POST /bookings/sports`
- **Concurrency Protection**: Implements pessimistic locking (`pessimistic_write`) on sports court slots.
- **Response on Conflict**: HTTP 409 Conflict when a court slot has already been reserved.
- **Payment & Price Authority**: Server computes court rate + add-ons + convenience fee, processes simulated payment, and attaches payment metadata.

### `POST /bookings/movie`
- **Validation**: Checks for overlapping seat reservations across concurrent users (HTTP 409 Conflict).
- **Payment & Price Authority**: Recalculates seat total + platform fee + GST. Attaches payment intent.

### `POST /bookings/dining`
- Reserves restaurant table slots and records guest requirements. Complimentary reservation payment record attached.

### `POST /bookings/stays`
- **Server Calculation**: Recalculates `(pricePerNight * nights * rooms) + addOns + taxes (12%)` server-side to guarantee zero client price tampering.

### `POST /bookings/shopping`
- **Server Calculation**: Validates item availability, variant pricing, platform fee (₹29), and GST (5%) server-side.

### `POST /bookings/event`
- **Validation**: Verifies ticket tier capacity limits atomically before decrementation (HTTP 409 Conflict on stock exhaustion).

### `POST /bookings/activity`
- **Validation**: Verifies package rate, participant count, and 18% GST server-side.

---

## 10. Cross-Vertical Search

### `GET /search?q={query}`
- Cross-vertical search indexing all 7 categories simultaneously (Movies, Dining, Events, Activities, Shopping, Stays, Sports).
- Public endpoint; rate-limited to 120 req/min.

---

## 11. Plans, Rewards & Notifications

All endpoints require `Bearer <token>` (`JwtAuthGuard`).

### `GET /plans` & `POST /plans`
- Lists or saves "Build My Day" multi-vertical itinerary plans isolated to the authenticated user.

### `GET /plans/:id`
- Retrieves plan details. Returns `403 Forbidden` if the plan belongs to another user.

### `GET /rewards` & `GET /rewards/:id`
- Lists redeemable reward vouchers and loyalty benefits.

### `GET /notifications`
- Returns notifications strictly for the authenticated user.

### `PATCH /notifications/:id/read`
- Marks a notification as read. Returns `403 Forbidden` if the notification belongs to another user.

---

## 12. Webhooks & External Payment Adapters

### `POST /webhooks/razorpay`
- Receives inbound transactional event notifications from Razorpay payment gateway.
- **Security Header**: `x-razorpay-signature` (HMAC-SHA256 signature calculated with webhook secret). Requests with missing or invalid signatures return `401 Unauthorized`.
- **Idempotency**: All processed events are tracked by `id` in `webhook_events` table. Duplicate event replays return `200 OK` with `{ "status": "ignored", "reason": "already_processed" }`.
- **Supported Events**:
  - `order.paid` / `payment.captured`: Transitions target booking to `UPCOMING`/`CONFIRMED`, attaches payment receipt tokens, and dispatches automated SMS notification via Twilio adapter.
  - `payment.failed`: Transitions target booking to `FAILED` and records failure reasons.
  - `refund.processed`: Transitions target booking to `CANCELLED` and persists refund metadata.


