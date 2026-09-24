import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/shopping.dart';
import 'package:plaza/core/models/stay.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/repositories/repository_provider.dart';
import 'package:plaza/core/repositories/local_dining_repository.dart';
import 'package:plaza/core/repositories/api_dining_repository.dart';
import 'package:plaza/core/repositories/local_event_repository.dart';
import 'package:plaza/core/repositories/api_event_repository.dart';
import 'package:plaza/core/repositories/local_activity_repository.dart';
import 'package:plaza/core/repositories/api_activity_repository.dart';
import 'package:plaza/core/repositories/local_shopping_repository.dart';
import 'package:plaza/core/repositories/api_shopping_repository.dart';
import 'package:plaza/core/repositories/local_stay_repository.dart';
import 'package:plaza/core/repositories/api_stay_repository.dart';
import 'package:plaza/core/repositories/local_sports_repository.dart';
import 'package:plaza/core/repositories/api_sports_repository.dart';
import 'package:plaza/core/repositories/local_booking_repository.dart';
import 'package:plaza/core/repositories/api_booking_repository.dart';
import 'package:plaza/core/repositories/search_repository.dart';
import 'package:plaza/core/auth/auth_service.dart';

void main() {
  group('Phase 7 - 7-Vertical Repositories & Full Architecture Tests', () {
    test('RepositoryProvider supplies all 7 vertical repositories', () {
      final rp = RepositoryProvider.instance;
      expect(rp.movieRepo, isNotNull);
      expect(rp.diningRepo, isNotNull);
      expect(rp.eventRepo, isNotNull);
      expect(rp.activityRepo, isNotNull);
      expect(rp.shoppingRepo, isNotNull);
      expect(rp.stayRepo, isNotNull);
      expect(rp.sportsRepo, isNotNull);
      expect(rp.bookingRepo, isNotNull);
      expect(rp.searchRepo, isNotNull);
    });

    test('Dining Repository retrieves restaurants and specific item', () async {
      final repo = const LocalDiningRepository();
      final all = await repo.getRestaurants();
      expect(all.isNotEmpty, isTrue);

      final first = all.first;
      final retrieved = await repo.getRestaurantById(first.id);
      expect(retrieved?.id, equals(first.id));
      expect(retrieved?.name, equals(first.name));
    });

    test('Event Repository retrieves events and supports filters', () async {
      final repo = const LocalEventRepository();
      final all = await repo.getEvents();
      expect(all.length, greaterThanOrEqualTo(4));

      final first = all.first;
      final byId = await repo.getEventById(first.id);
      expect(byId?.id, equals(first.id));
    });

    test('Activity Repository retrieves activities and packages', () async {
      final repo = const LocalActivityRepository();
      final all = await repo.getActivities();
      expect(all.isNotEmpty, isTrue);

      final act = await repo.getActivityById('act_1');
      expect(act, isNotNull);
      expect(act!.packages.isNotEmpty, isTrue);
    });

    test('Shopping Repository retrieves products and stores', () async {
      final repo = const LocalShoppingRepository();
      final products = await repo.getProducts();
      final stores = await repo.getStores();
      expect(products.isNotEmpty, isTrue);
      expect(stores.isNotEmpty, isTrue);

      final macbook = await repo.getProductById('prod_macbook_pro');
      expect(macbook, isNotNull);
      expect(macbook!.brand, equals('Apple'));
    });

    test('Stay Repository retrieves hotels and room types', () async {
      final repo = const LocalStayRepository();
      final hotels = await repo.getHotels();
      expect(hotels.isNotEmpty, isTrue);

      final hotel = await repo.getHotelById(hotels.first.id);
      expect(hotel, isNotNull);
      expect(hotel!.roomTypes.isNotEmpty, isTrue);
    });

    test('Sports Repository retrieves sports venues and slots', () async {
      final repo = const LocalSportsRepository();
      final venues = await repo.getVenues();
      expect(venues.isNotEmpty, isTrue);

      final venue = await repo.getVenueById(venues.first.id);
      expect(venue, isNotNull);
      expect(venue!.availableSlots.isNotEmpty, isTrue);
    });

    test('Booking Repository retrieves unified wallet bookings', () async {
      final repo = const LocalBookingRepository();
      final bookings = await repo.getBookings();
      expect(bookings, isNotNull);
    });

    test('Search Repository performs cross-vertical search across all 7 categories', () async {
      final repo = const LocalSearchRepository();
      final results = await repo.search('hyderabad');
      expect(results.isEmpty, isFalse);
      expect(results.totalCount, greaterThan(0));
    });
  });

  group('Phase 7 - Domain Model Serialization Tests', () {
    test('Product and ProductVariant fromJson and toJson roundtrip', () {
      final json = {
        'id': 'prod_test',
        'name': 'Bose Headphones',
        'brand': 'Bose',
        'category': 'electronics',
        'price': 24999.0,
        'originalPrice': 29999.0,
        'rating': 4.7,
        'reviewCount': 102,
        'coverImageUrl': 'https://example.com/bose.jpg',
        'galleryImages': ['https://example.com/bose_angle.jpg'],
        'description': 'Noise cancelling wireless headphones',
        'specifications': {'Battery': '24 Hours'},
        'variants': [
          {'id': 'v_blk', 'name': 'Triple Black', 'priceDelta': 0.0, 'inStock': true}
        ],
        'storeId': 'store_1',
        'storeName': 'Bose Store',
        'storeLocation': 'Inorbit Mall',
        'distance': '2.0 km',
        'isTrending': true,
        'isDealOfTheDay': false,
        'inStock': true,
      };

      final product = Product.fromJson(json);
      expect(product.id, equals('prod_test'));
      expect(product.name, equals('Bose Headphones'));
      expect(product.variants.length, equals(1));
      expect(product.variants.first.name, equals('Triple Black'));

      final encoded = product.toJson();
      expect(encoded['id'], equals('prod_test'));
      expect(encoded['price'], equals(24999.0));
    });

    test('Hotel and RoomType fromJson and toJson roundtrip', () {
      final json = {
        'id': 'stay_palace',
        'name': 'Palace Grand',
        'tagline': 'Royal Oasis',
        'category': 'luxury',
        'location': 'Hyderabad',
        'address': 'Banjara Hills',
        'distance': '5.0 km',
        'rating': 4.9,
        'reviewCount': 500,
        'startingPricePerNight': 25000.0,
        'coverImageUrl': 'https://example.com/hotel.jpg',
        'galleryImages': ['https://example.com/h1.jpg'],
        'description': 'Five star sanctuary',
        'amenities': ['infinityPool', 'spaWellness'],
        'rooms': [
          {
            'id': 'r_presidential',
            'name': 'Presidential Suite',
            'description': 'Grand master suite',
            'imageUrl': 'https://example.com/suite.jpg',
            'pricePerNight': 50000.0,
            'maxGuests': 4,
            'bedType': 'King Bed',
            'roomSize': '800 sq ft',
            'highlights': ['Private Pool'],
            'isAvailable': true,
          }
        ],
        'checkInTime': '02:00 PM',
        'checkOutTime': '12:00 PM',
        'isFeatured': true,
      };

      final hotel = Hotel.fromJson(json);
      expect(hotel.id, equals('stay_palace'));
      expect(hotel.roomTypes.length, equals(1));
      expect(hotel.roomTypes.first.pricePerNight, equals(50000.0));

      final encoded = hotel.toJson();
      expect(encoded['id'], equals('stay_palace'));
      expect(encoded['startingPricePerNight'], equals(25000.0));
    });

    test('UnifiedBooking fromJson and toJson roundtrip', () {
      final json = {
        'id': 'PLZ-SPT-8812',
        'type': 'sports',
        'title': 'Hotfut Turf',
        'subtitle': 'Box Cricket (1 Hour)',
        'location': 'Gachibowli',
        'date': '2026-09-24T18:00:00.000Z',
        'time': '06:00 PM',
        'imageUrl': 'https://example.com/turf.jpg',
        'status': 'upcoming',
        'totalPrice': 1200.0,
        'qrCodeData': 'QR-8812',
      };

      final booking = UnifiedBooking.fromJson(json);
      expect(booking.id, equals('PLZ-SPT-8812'));
      expect(booking.type, equals(UnifiedBookingType.sports));
      expect(booking.totalAmount, equals(1200.0));
      expect(booking.status, equals(BookingStatus.upcoming));

      final serialized = booking.toJson();
      expect(serialized['id'], equals('PLZ-SPT-8812'));
      expect(serialized['type'], equals('sports'));
      expect(serialized['totalPrice'], equals(1200.0));
    });
  });

  group('Phase 7 - Authentication & Fallback Resiliency Tests', () {
    test('AuthService demo login manages session', () async {
      final auth = AuthService.instance;
      final ok = await auth.demoLogin();
      expect(ok, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.email, isNotEmpty);
      expect(auth.currentUser?.rewardPoints, greaterThan(0));

      auth.logout();
      expect(auth.currentUser, isNull);
    });

    test('API Repositories gracefully fall back to local when backend unreachable', () async {
      // Pointing to invalid port ensures failure triggers fallback
      final apiDining = ApiDiningRepository();
      final diningFallback = await apiDining.getRestaurants();
      expect(diningFallback.isNotEmpty, isTrue);

      final apiSports = ApiSportsRepository();
      final sportsFallback = await apiSports.getVenues();
      expect(sportsFallback.isNotEmpty, isTrue);

      final apiEvents = ApiEventRepository();
      final eventsFallback = await apiEvents.getEvents();
      expect(eventsFallback.isNotEmpty, isTrue);

      final apiActivities = ApiActivityRepository();
      final activitiesFallback = await apiActivities.getActivities();
      expect(activitiesFallback.isNotEmpty, isTrue);

      final apiShopping = ApiShoppingRepository();
      final shoppingFallback = await apiShopping.getProducts();
      expect(shoppingFallback.isNotEmpty, isTrue);

      final apiStays = ApiStayRepository();
      final staysFallback = await apiStays.getHotels();
      expect(staysFallback.isNotEmpty, isTrue);

      final apiBookings = ApiBookingRepository();
      final bookingsFallback = await apiBookings.getBookings();
      expect(bookingsFallback, isNotNull);

      final apiSearch = ApiSearchRepository();
      final searchFallback = await apiSearch.search('zara');
      expect(searchFallback.shopping.isNotEmpty, isTrue);
    });
  });
}
