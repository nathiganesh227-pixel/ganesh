import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plaza/core/models/dining.dart';
import 'package:plaza/core/models/stay.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';

import 'package:plaza/core/repositories/api_movie_repository.dart';
import 'package:plaza/core/repositories/api_dining_repository.dart';
import 'package:plaza/core/repositories/api_event_repository.dart';
import 'package:plaza/core/repositories/api_activity_repository.dart';
import 'package:plaza/core/repositories/api_shopping_repository.dart';
import 'package:plaza/core/repositories/api_stay_repository.dart';
import 'package:plaza/core/repositories/api_sports_repository.dart';
import 'package:plaza/core/repositories/api_booking_repository.dart';
import 'package:plaza/core/repositories/search_repository.dart';
import 'package:plaza/core/repositories/local_movie_repository.dart';
import 'package:plaza/core/repositories/local_dining_repository.dart';
import 'package:plaza/core/repositories/local_event_repository.dart';
import 'package:plaza/core/repositories/local_activity_repository.dart';
import 'package:plaza/core/repositories/local_shopping_repository.dart';
import 'package:plaza/core/repositories/local_stay_repository.dart';
import 'package:plaza/core/repositories/local_sports_repository.dart';
import 'package:plaza/core/repositories/local_booking_repository.dart';

void main() {
  group('Phase 11 — Live Render Backend & Environment Configuration', () {
    tearDown(() {
      EnvironmentConfig.reset();
      ApiClient.setGlobalAuthToken(null);
    });

    test('EnvironmentConfig points to Live Render URL by default for staging/prod', () {
      EnvironmentConfig.setEnvironment(AppEnvironment.staging);
      expect(EnvironmentConfig.baseUrl, 'https://plaza-api-o4sh.onrender.com/api/v1');
      expect(EnvironmentConfig.isLiveRender, isTrue);

      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      expect(EnvironmentConfig.baseUrl, 'https://plaza-api-o4sh.onrender.com/api/v1');
      expect(EnvironmentConfig.isLiveRender, isTrue);

      EnvironmentConfig.setEnvironment(AppEnvironment.dev);
      expect(EnvironmentConfig.baseUrl, 'http://127.0.0.1:3000/api/v1');
      expect(EnvironmentConfig.isLiveRender, isFalse);
    });

    test('EnvironmentConfig supports runtime baseUrl override without hardcoded UI references', () {
      EnvironmentConfig.setBaseUrlOverride('https://custom-staging.onrender.com/api/v1');
      expect(EnvironmentConfig.baseUrl, 'https://custom-staging.onrender.com/api/v1');
      expect(EnvironmentConfig.isLiveRender, isTrue);

      EnvironmentConfig.reset();
      expect(EnvironmentConfig.baseUrl, isNotEmpty);
    });
  });

  group('Phase 11 — ApiClient Resilience, Envelopes & Auth Attachment', () {
    tearDown(() {
      ApiClient.setGlobalAuthToken(null);
      EnvironmentConfig.reset();
    });

    test('ApiClient successfully unwraps standard NestJS API envelope', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/movies'));
        return http.Response(
          json.encode({
            'success': true,
            'data': [
              {
                'id': 'render_mov_1',
                'title': 'Kalki 2898 AD (Render)',
                'tagline': 'The future begins',
                'synopsis': 'Epic sci-fi action saga',
                'posterUrl': 'https://example.com/poster.jpg',
                'backdropUrl': 'https://example.com/backdrop.jpg',
                'rating': 9.2,
                'votesCount': 50000,
                'genres': ['Sci-Fi', 'Action'],
                'duration': '3h 01m',
                'primaryLanguage': 'Telugu',
                'availableLanguages': ['Telugu', 'Hindi'],
                'formats': ['IMAX 3D', '2D'],
                'certificate': 'UA',
                'releaseDate': '2026-06-27T00:00:00.000Z',
                'startingPrice': 350,
                'cast': [],
                'director': 'Nag Ashwin',
              }
            ],
            'message': 'Movies retrieved successfully',
            'statusCode': 200,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(client: mockClient);
      final response = await client.get<List<dynamic>>(
        '/movies',
        fromJson: (json) => json as List<dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.statusCode, 200);
      expect(response.message, 'Movies retrieved successfully');
      expect(response.data?.length, 1);
      expect(response.data?.first['id'], 'render_mov_1');
    });

    test('ApiClient automatically attaches Bearer token across instances via global token', () async {
      ApiClient.setGlobalAuthToken('jwt_staging_render_token_xyz999');

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer jwt_staging_render_token_xyz999');
        return http.Response(
          json.encode({
            'success': true,
            'data': {'status': 'authenticated', 'userId': 'usr_staging_001'},
            'message': 'Profile verified',
            'statusCode': 200,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(client: mockClient);
      final response = await client.get<Map<String, dynamic>>(
        '/auth/me',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.data?['userId'], 'usr_staging_001');
    });

    test('ApiClient extracts structured error messages on HTTP 4xx/5xx', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'success': false,
            'data': null,
            'message': 'Invalid credentials provided',
            'statusCode': 401,
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = ApiClient(client: mockClient);
      final response = await client.post<Map<String, dynamic>>(
        '/auth/login',
        body: {'email': 'test@plaza.app', 'password': 'wrong'},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      expect(response.success, isFalse);
      expect(response.statusCode, 401);
      expect(response.message, contains('Invalid credentials provided'));
    });

    test('ApiClient gracefully returns failure on timeout', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      });

      final client = ApiClient(client: mockClient);
      final response = await client.get<Map<String, dynamic>>(
        '/movies',
        fromJson: (json) => json as Map<String, dynamic>,
      );
      expect(response, isA<ApiResponse<Map<String, dynamic>>>());
    });
  });

  group('Phase 11 — 7-Vertical Catalog Local Fallback on Render 500 / Network Error', () {
    late ApiClient failingClient;

    setUp(() {
      failingClient = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            json.encode({
              'success': false,
              'data': null,
              'message': 'Internal server error',
              'statusCode': 500,
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
    });

    test('1. Movies: falls back to local catalog on API 500', () async {
      final repo = ApiMovieRepository(
        client: failingClient,
        fallback: const LocalMovieRepository(),
      );
      final movies = await repo.getMovies();
      expect(movies.isNotEmpty, isTrue);
      expect(movies.first.title, isNotEmpty);

      final movie = await repo.getMovieById(movies.first.id);
      expect(movie, isNotNull);
    });

    test('2. Dining: falls back to local restaurants on API 500', () async {
      final repo = ApiDiningRepository(
        client: failingClient,
        fallback: const LocalDiningRepository(),
      );
      final restaurants = await repo.getRestaurants();
      expect(restaurants.isNotEmpty, isTrue);
      expect(restaurants.first.name, isNotEmpty);

      final restaurant = await repo.getRestaurantById(restaurants.first.id);
      expect(restaurant, isNotNull);
    });

    test('3. Events: falls back to local events on API 500', () async {
      final repo = ApiEventRepository(
        client: failingClient,
        fallback: const LocalEventRepository(),
      );
      final events = await repo.getEvents();
      expect(events.isNotEmpty, isTrue);
      expect(events.first.title, isNotEmpty);
    });

    test('4. Activities: falls back to local activities on API 500', () async {
      final repo = ApiActivityRepository(
        client: failingClient,
        fallback: const LocalActivityRepository(),
      );
      final activities = await repo.getActivities();
      expect(activities.isNotEmpty, isTrue);
      expect(activities.first.title, isNotEmpty);
    });

    test('5. Shopping: falls back to local products and stores on API 500', () async {
      final repo = ApiShoppingRepository(
        client: failingClient,
        fallback: const LocalShoppingRepository(),
      );
      final products = await repo.getProducts();
      final stores = await repo.getStores();
      expect(products.isNotEmpty, isTrue);
      expect(stores.isNotEmpty, isTrue);
    });

    test('6. Stays: falls back to local hotels and rooms on API 500', () async {
      final repo = ApiStayRepository(
        client: failingClient,
        fallback: const LocalStayRepository(),
      );
      final hotels = await repo.getHotels();
      expect(hotels.isNotEmpty, isTrue);
      expect(hotels.first.name, isNotEmpty);
    });

    test('7. Sports: falls back to local venues on API 500', () async {
      final repo = ApiSportsRepository(
        client: failingClient,
        fallback: const LocalSportsRepository(),
      );
      final venues = await repo.getVenues();
      expect(venues.isNotEmpty, isTrue);
      expect(venues.first.name, isNotEmpty);
    });

    test('Search: falls back to local cross-vertical search on API 500', () async {
      final repo = ApiSearchRepository(
        client: failingClient,
        fallback: const LocalSearchRepository(),
      );
      final results = await repo.search('Dune');
      expect(results.totalCount, greaterThan(0));
    });
  });

  group('Phase 11 — Strict Mutation Safety (No Silent Local Mutations on API Error)', () {
    late ApiClient failingClient;

    setUp(() {
      failingClient = ApiClient(
        client: MockClient((request) async {
          return http.Response(
            json.encode({
              'success': false,
              'data': null,
              'message': 'Database connection error',
              'statusCode': 500,
            }),
            500,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
    });

    test('Dining reservation creation fails safely and rejects silent local mutation', () async {
      final localRepo = const LocalDiningRepository();
      final repo = ApiDiningRepository(
        client: failingClient,
        fallback: localRepo,
      );

      final restaurants = await localRepo.getRestaurants();
      final testRes = DiningReservation(
        reservationId: 'res_test_safe_99',
        restaurant: restaurants.first,
        date: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '19:30',
        partySize: 2,
        seatingPreference: SeatingPreference.indoor,
        guestName: 'Ganesh',
        guestPhone: '+91 9876543210',
        createdAt: DateTime.now(),
      );

      final success = await repo.createReservation(testRes);
      expect(success, isFalse, reason: 'Must NOT succeed or silently mutate local data on API failure');
    });

    test('Stay booking creation fails safely on API error', () async {
      final localRepo = const LocalStayRepository();
      final repo = ApiStayRepository(
        client: failingClient,
        fallback: localRepo,
      );

      final hotels = await localRepo.getHotels();
      final testBooking = HotelBooking(
        bookingId: 'stay_bkg_test_99',
        hotel: hotels.first,
        roomType: hotels.first.roomTypes.first,
        checkInDate: DateTime.now().add(const Duration(days: 3)),
        checkOutDate: DateTime.now().add(const Duration(days: 5)),
        nights: 2,
        roomsCount: 1,
        guestsCount: 2,
        selectedAddOns: const [],
        roomTotal: 30000,
        addOnsTotal: 0,
        taxesAndFees: 5400,
        grandTotal: 35400,
        guestName: 'Ganesh',
        guestEmail: 'g@test.com',
        guestPhone: '+919876543210',
        specialRequests: '',
        qrCodeData: 'PLZ-STAY-99',
        paymentMethod: 'UPI',
        bookingTime: DateTime.now(),
      );

      final success = await repo.createBooking(testBooking);
      expect(success, isFalse, reason: 'Stay booking must fail safely without local mutation');
    });

    test('Sports court booking creation fails safely on API error', () async {
      final localRepo = const LocalSportsRepository();
      final repo = ApiSportsRepository(
        client: failingClient,
        fallback: localRepo,
      );

      final venues = await localRepo.getVenues();
      final testSlot = venues.first.availableSlots.first;

      final success = await repo.bookSlot(
        venueId: venues.first.id,
        sportName: 'Badminton',
        slotId: testSlot.id,
        date: '2026-10-01',
        playersCount: 2,
      );

      expect(success, isFalse, reason: 'Sports booking must fail safely without local mutation');
    });

    test('Unified booking cancellation fails safely on API error', () async {
      final localRepo = const LocalBookingRepository();
      final repo = ApiBookingRepository(
        client: failingClient,
        fallback: localRepo,
      );

      final success = await repo.cancelBooking('bkg_unreal_999');
      expect(success, isFalse, reason: 'Cancellation must fail cleanly on API failure');
    });
  });

  group('Phase 11 — End-to-End Movies Flow against Render API Mock', () {
    test('ApiMovieRepository retrieves remote movies when Render returns 200', () async {
      final liveMockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'success': true,
            'data': [
              {
                'id': 'render_mov_kalki',
                'title': 'Kalki 2898 AD',
                'tagline': 'The future of cinema',
                'synopsis': 'Set in the post-apocalyptic world of Kasi in 2898 AD.',
                'posterUrl': 'https://example.com/kalki.jpg',
                'backdropUrl': 'https://example.com/kalki_bd.jpg',
                'rating': 9.1,
                'votesCount': 142000,
                'genres': ['Sci-Fi', 'Mythology', 'Action'],
                'duration': '3h 01m',
                'primaryLanguage': 'Telugu',
                'availableLanguages': ['Telugu', 'Hindi', 'Tamil'],
                'formats': ['IMAX 3D', '4DX', '2D'],
                'certificate': 'UA',
                'releaseDate': '2026-06-27T00:00:00.000Z',
                'startingPrice': 350,
                'cast': [],
                'director': 'Nag Ashwin',
              }
            ],
            'message': 'Movies fetched',
            'statusCode': 200,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = ApiMovieRepository(
        client: ApiClient(client: liveMockClient),
        fallback: const LocalMovieRepository(),
      );

      final movies = await repo.getMovies();
      expect(movies.isNotEmpty, isTrue);
      expect(movies.first.id, 'render_mov_kalki');
      expect(movies.first.title, 'Kalki 2898 AD');
      expect(movies.first.genres, contains('Mythology'));
    });
  });
}
