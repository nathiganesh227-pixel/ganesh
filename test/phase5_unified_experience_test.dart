import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/features/bookings/bookings_screen.dart';
import 'package:plaza/features/plans/plans_screen.dart';
import 'package:plaza/features/plans/build_my_day_wizard_screen.dart';
import 'package:plaza/features/profile/profile_screen.dart';
import 'package:plaza/features/profile/rewards_screen.dart';
import 'package:plaza/features/notifications/notifications_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5 - Global State Store Tests', () {
    test('PlazaGlobalState seeds data across all 7 verticals', () {
      final state = PlazaGlobalState.instance;

      expect(state.bookings.isNotEmpty, true);
      expect(state.upcomingBookings.isNotEmpty, true);
      expect(state.activeBookings.isNotEmpty, true);
      expect(state.completedBookings.isNotEmpty, true);
      expect(state.cancelledBookings.isNotEmpty, true);

      // Verify representations of verticals
      final types = state.bookings.map((b) => b.type).toSet();
      expect(types.contains(UnifiedBookingType.movie), true);
      expect(types.contains(UnifiedBookingType.dining), true);
      expect(types.contains(UnifiedBookingType.event), true);
      expect(types.contains(UnifiedBookingType.activity), true);
      expect(types.contains(UnifiedBookingType.shopping), true);
      expect(types.contains(UnifiedBookingType.stay), true);
      expect(types.contains(UnifiedBookingType.sports), true);
    });

    test('PlazaGlobalState handles booking addition and cancellation', () {
      final state = PlazaGlobalState.instance;
      final initialCount = state.bookings.length;

      final testBooking = UnifiedBooking(
        id: 'TEST-BK-001',
        type: UnifiedBookingType.movie,
        title: 'Gladiator II IMAX',
        subtitle: 'Prasads Large Screen',
        location: 'Necklace Road',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '6:00 PM',
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401',
        status: BookingStatus.upcoming,
        totalAmount: 500,
      );

      state.addBooking(testBooking);
      expect(state.bookings.length, initialCount + 1);
      expect(state.bookings.first.id, 'TEST-BK-001');

      state.cancelBooking('TEST-BK-001');
      final cancelled = state.bookings.firstWhere((b) => b.id == 'TEST-BK-001');
      expect(cancelled.status, BookingStatus.cancelled);
    });

    test('PlazaGlobalState manages favorites and recently viewed', () {
      final state = PlazaGlobalState.instance;

      expect(state.isFavorite('test_fav_item'), false);
      state.toggleFavorite('test_fav_item');
      expect(state.isFavorite('test_fav_item'), true);
      state.toggleFavorite('test_fav_item');
      expect(state.isFavorite('test_fav_item'), false);

      expect(state.recentlyViewed.isNotEmpty, true);
    });

    test('PlazaGlobalState bookEntirePlan creates wallet bookings and awards points', () {
      final state = PlazaGlobalState.instance;
      final initialPoints = state.rewardsBalance;
      final initialBookingsCount = state.bookings.length;

      final plan = state.savedPlans.first;
      final planBookingId = state.bookEntirePlan(plan);

      expect(planBookingId.startsWith('PLN-HYD-'), true);
      expect(state.bookings.length, initialBookingsCount + plan.items.length);
      expect(state.rewardsBalance, initialPoints + 450);
    });

    test('PlazaGlobalState handles rewards voucher redemption', () {
      final state = PlazaGlobalState.instance;
      final voucher = state.vouchers.firstWhere((v) => !v.isRedeemed);

      final balanceBefore = state.rewardsBalance;
      if (balanceBefore >= voucher.pointsCost) {
        final success = state.redeemVoucher(voucher.id);
        expect(success, true);
        expect(state.rewardsBalance, balanceBefore - voucher.pointsCost);
        final redeemed = state.vouchers.firstWhere((v) => v.id == voucher.id);
        expect(redeemed.isRedeemed, true);
      }
    });
  });

  group('Phase 5 - Unified Bookings Wallet Screen Tests', () {
    testWidgets('BookingsScreen renders tabs and booking cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: BookingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.textContaining('Upcoming'), findsOneWidget);
      expect(find.textContaining('Active Now'), findsOneWidget);
      expect(find.textContaining('Completed'), findsOneWidget);
      expect(find.textContaining('Cancelled'), findsOneWidget);

      // Verify presence of view switcher icons
      expect(find.byIcon(Icons.view_agenda_rounded), findsOneWidget);
      expect(find.byIcon(Icons.timeline_rounded), findsOneWidget);

      // Tap timeline view icon
      await tester.tap(find.byIcon(Icons.timeline_rounded));
      await tester.pumpAndSettle();

      // Switch back to card view
      await tester.tap(find.byIcon(Icons.view_agenda_rounded));
      await tester.pumpAndSettle();
    });
  });

  group('Phase 5 - Plans & Build My Day Screen Tests', () {
    testWidgets('PlansScreen renders hub, launch card and saved plans', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PlansScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Build My Day'), findsOneWidget);
      expect(find.text('Start Planning Wizard'), findsOneWidget);
      expect(find.text('Your Saved Plans'), findsOneWidget);
    });

    testWidgets('BuildMyDayWizardScreen navigates through 5 steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: BuildMyDayWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: People
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Who is joining today?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Budget
      expect(find.text('Step 2 of 5'), findsOneWidget);
      expect(find.text('What’s the budget target?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Time
      expect(find.text('Step 3 of 5'), findsOneWidget);
      expect(find.text('When are you heading out?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Location
      expect(find.text('Step 4 of 5'), findsOneWidget);
      expect(find.text('Preferred Zone in Hyderabad'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 5: Mood
      expect(find.text('Step 5 of 5'), findsOneWidget);
      expect(find.text('Pick your vibe for the day'), findsOneWidget);
      expect(find.text('Generate Day Itinerary ✨'), findsOneWidget);
    });
  });

  group('Phase 5 - Profile & Rewards Screen Tests', () {
    testWidgets('ProfileScreen renders user details, coins and menu items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile & Rewards'), findsOneWidget);
      expect(find.text('Gopi Ganesh'), findsOneWidget);
      expect(find.text('PLAZA COINS'), findsOneWidget);
      expect(find.text('Saved Favorites'), findsOneWidget);
      expect(find.text('Recently Viewed'), findsOneWidget);
    });

    testWidgets('RewardsScreen renders points balance and vouchers', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: RewardsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rewards & Wallet'), findsOneWidget);
      expect(find.text('POINTS BALANCE'), findsOneWidget);
      expect(find.text('Give ₹250, Get 500 Pts'), findsOneWidget);
      expect(find.text('How to Earn Points'), findsOneWidget);
      expect(find.text('Redemption Catalog'), findsOneWidget);
      expect(find.text('Points History'), findsOneWidget);
    });

    testWidgets('NotificationsModal renders categorized notifications', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inbox & Alerts'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
    });
  });
}
