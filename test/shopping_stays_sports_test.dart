import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/shopping_cart_manager.dart';
import 'package:plaza/core/data/shopping_mock_data.dart';
import 'package:plaza/core/data/stay_mock_data.dart';
import 'package:plaza/core/data/sports_mock_data.dart';
import 'package:plaza/core/models/shopping.dart';
import 'package:plaza/core/models/stay.dart';
import 'package:plaza/core/models/sports.dart';
import 'package:plaza/features/shopping/shopping_screen.dart';
import 'package:plaza/features/shopping/product_details_screen.dart';
import 'package:plaza/features/shopping/cart_screen.dart';
import 'package:plaza/features/shopping/shopping_confirmation_screen.dart';
import 'package:plaza/features/stays/stays_screen.dart';
import 'package:plaza/features/stays/hotel_details_screen.dart';
import 'package:plaza/features/stays/hotel_confirmation_screen.dart';
import 'package:plaza/features/sports/sports_screen.dart';
import 'package:plaza/features/sports/sports_slot_booking_screen.dart';
import 'package:plaza/features/sports/sports_confirmation_screen.dart';
import 'package:plaza/features/explore/explore_screen.dart';

void main() {
  group('Shopping Flow Tests', () {
    testWidgets('ShoppingScreen renders categories, flash deals, and malls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: ShoppingScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Shopping & Luxury'), findsOneWidget);
      expect(find.text('All Items'), findsOneWidget);
      expect(find.text("Today's Flash Deals 🔥"), findsOneWidget);
      expect(find.text('Premier Malls & Boutiques 🏬'), findsOneWidget);
    });

    testWidgets('ProductDetailsScreen displays product and adds to cart', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final product = ShoppingMockData.products.first; // MacBook Pro
      final initialCount = ShoppingCartManager.instance.totalItemCount;

      await tester.pumpWidget(MaterialApp(home: ProductDetailsScreen(product: product)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(product.name), findsOneWidget);
      expect(find.text('About Product'), findsOneWidget);
      expect(find.text('Add to Bag 🛍️'), findsOneWidget);

      await tester.tap(find.text('Add to Bag 🛍️'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(ShoppingCartManager.instance.totalItemCount, greaterThan(initialCount));
    });

    testWidgets('CartScreen applies coupon and calculates totals', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: CartScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Shopping Bag'), findsOneWidget);
      expect(find.text('Delivery / Pickup Preference'), findsOneWidget);
      expect(find.text('Grand Total'), findsOneWidget);

      // Enter coupon
      await tester.enterText(find.byType(TextField).first, 'PLAZASHOP');
      await tester.tap(find.text('Apply'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Applied ✓'), findsOneWidget);
    });

    testWidgets('ShoppingConfirmationScreen renders order pass and QR code', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = ShoppingOrder(
        orderId: 'PLZ-SHP-889911',
        items: [
          CartItem(
            product: ShoppingMockData.products[1],
            quantity: 1,
          ),
        ],
        itemsTotal: 16995.0,
        discountAmount: 1699.0,
        platformFee: 49.0,
        gstAmount: 2753.0,
        grandTotal: 18098.0,
        fulfillmentType: ShoppingFulfillmentType.inStorePickup,
        storeName: 'Superkicks Banjara Hills',
        storeLocation: 'Road No. 12, Banjara Hills',
        orderTime: DateTime.now(),
        qrCodeData: 'PLAZA-ORDER:PLZ-SHP-889911:4521',
        paymentMethod: 'UPI / Google Pay',
        pickupCode: '4521',
      );

      await tester.pumpWidget(MaterialApp(home: ShoppingConfirmationScreen(order: order)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Order Confirmed!'), findsOneWidget);
      expect(find.text('Superkicks Banjara Hills'), findsOneWidget);
      expect(find.text('PLZ-SHP-889911'), findsOneWidget);
      expect(find.text('PICKUP CODE: 4521'), findsOneWidget);
    });
  });

  group('Stays Flow Tests', () {
    testWidgets('StaysScreen renders featured hotels and categories', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: StaysScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Stays & Luxury Escapes'), findsOneWidget);
      expect(find.text('All Stays'), findsOneWidget);
      expect(find.text('Signature Palaces & 5★ Stays 👑'), findsOneWidget);
      expect(find.text('Taj Falaknuma Palace'), findsWidgets);
    });

    testWidgets('HotelDetailsScreen & RoomBookingScreen calculate stay prices', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final hotel = StayMockData.hotels.first;
      await tester.pumpWidget(MaterialApp(home: HotelDetailsScreen(hotel: hotel)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(hotel.name), findsOneWidget);
      expect(find.text('World-Class Amenities'), findsOneWidget);
      expect(find.text('Select Room 🏨'), findsOneWidget);

      await tester.tap(find.text('Select Room 🏨'));
      await tester.pumpAndSettle();

      expect(find.text('Reserve Room'), findsOneWidget);
      expect(find.text('Stay Duration & Dates'), findsOneWidget);
      expect(find.text('Enhance Your Stay (Add-ons)'), findsOneWidget);
      expect(find.text('Book Stay 🏨'), findsOneWidget);
    });

    testWidgets('HotelConfirmationScreen renders luxury stay pass and QR', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final booking = HotelBooking(
        bookingId: 'PLZ-STY-992211',
        hotel: StayMockData.hotels.first,
        roomType: StayMockData.hotels.first.roomTypes.first,
        checkInDate: DateTime.now().add(const Duration(days: 1)),
        checkOutDate: DateTime.now().add(const Duration(days: 2)),
        nights: 1,
        guestsCount: 2,
        roomsCount: 1,
        selectedAddOns: [StayMockData.defaultAddOns.first],
        roomTotal: 48500.0,
        addOnsTotal: 3000.0,
        taxesAndFees: 9270.0,
        grandTotal: 60770.0,
        guestName: 'Nathi Gopi Ganesh',
        guestEmail: 'gopi.ganesh@example.com',
        guestPhone: '+91 98765 43210',
        specialRequests: 'High floor, palace garden view',
        qrCodeData: 'PLAZA-STAY:PLZ-STY-992211:stay_taj_falaknuma',
        paymentMethod: 'UPI / Google Pay',
        bookingTime: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(home: HotelConfirmationScreen(booking: booking)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Stay Reserved!'), findsOneWidget);
      expect(find.text('Taj Falaknuma Palace'), findsOneWidget);
      expect(find.text('PLZ-STY-992211'), findsOneWidget);
    });
  });

  group('Sports Flow Tests', () {
    testWidgets('SportsScreen renders sports categories and arenas', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: SportsScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Sports & Turfs'), findsOneWidget);
      expect(find.text('All Sports'), findsOneWidget);
      expect(find.text('Available Right Now ⚡'), findsOneWidget);
      expect(find.text('HotFut Arena Gachibowli'), findsWidgets);
    });

    testWidgets('SportsSlotBookingScreen handles durations, add-ons, and squad mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final venue = SportsMockData.venues.first;
      await tester.pumpWidget(MaterialApp(
        home: SportsSlotBookingScreen(venue: venue, initialSport: SportType.boxCricket),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Book Turf / Slot'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Available Time Slots'), findsOneWidget);

      // Toggle Squad Booking
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Squad / Team Name'), findsOneWidget);
      expect(find.textContaining('Share Per Player:'), findsOneWidget);
    });

    testWidgets('SportsConfirmationScreen renders sports pass and split bill', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final booking = SportsBooking(
        bookingId: 'PLZ-SPT-114422',
        venue: SportsMockData.venues.first,
        sport: SportType.boxCricket,
        date: DateTime.now(),
        slot: SportsMockData.venues.first.availableSlots.first,
        durationMinutes: 60,
        playersCount: 10,
        addOns: [SportsMockData.venues.first.equipmentAddOns.first],
        isSquadBooking: true,
        squadName: 'Hyderabadi Strikers',
        courtPrice: 1400.0,
        addOnsTotal: 350.0,
        convenienceFee: 50.0,
        grandTotal: 1800.0,
        perPersonCost: 180.0,
        bookerName: 'Nathi Gopi Ganesh',
        bookerPhone: '+91 98765 43210',
        qrCodeData: 'PLAZA-SPORTS:PLZ-SPT-114422',
        paymentMethod: 'UPI / Google Pay',
        bookingTime: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(home: SportsConfirmationScreen(booking: booking)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Turf Slot Confirmed!'), findsOneWidget);
      expect(find.text('HotFut Arena Gachibowli'), findsOneWidget);
      expect(find.text('PLZ-SPT-114422'), findsOneWidget);
      expect(find.text('₹180 / player'), findsOneWidget);
    });
  });

  group('Unified Search Tests', () {
    testWidgets('ExploreScreen performs cross-vertical search', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Hyderabad'), findsOneWidget);

      // Search for "Taj" -> should find Stays
      await tester.enterText(find.byType(TextField).first, 'Taj');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('STAYS'), findsWidgets);
      expect(find.text('Taj Falaknuma Palace'), findsOneWidget);

      // Search for "Jordan" -> should find Shopping
      await tester.enterText(find.byType(TextField).first, 'Jordan');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('SHOPPING'), findsWidgets);
      expect(find.textContaining('Air Jordan 1'), findsOneWidget);

      // Search for "HotFut" -> should find Sports
      await tester.enterText(find.byType(TextField).first, 'HotFut');
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('SPORTS'), findsWidgets);
      expect(find.text('HotFut Arena Gachibowli'), findsOneWidget);
    });
  });
}
