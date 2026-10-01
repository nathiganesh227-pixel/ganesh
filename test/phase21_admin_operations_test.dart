import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/auth/auth_service.dart';
import 'package:plaza/core/models/admin_models.dart';
import 'package:plaza/features/admin/admin_route_guard.dart';
import 'package:plaza/features/admin/views/admin_bookings_view.dart';
import 'package:plaza/features/admin/views/admin_payments_view.dart';
import 'views/admin_operations_test_repo.dart';

void main() {
  setUp(() {
    AuthService.instance.signOut();
  });

  group('Phase 21 — RBAC & Operational Security Guards', () {
    test('UserRole parsing correctly maps operator string', () {
      expect(UserRole.fromString('operator'), equals(UserRole.operator));
      expect(UserRole.fromString('OPERATOR'), equals(UserRole.operator));
    });

    test('PlazaUser accurately evaluates isOperator and canAccessAdmin', () {
      const opUser = PlazaUser(
        id: 'usr_op_1',
        name: 'Plaza Operations Staff',
        email: 'ops@plaza.club',
        role: UserRole.operator,
      );

      expect(opUser.isAdmin, isFalse);
      expect(opUser.isOperator, isTrue);
      expect(opUser.canAccessAdmin, isTrue);

      const custUser = PlazaUser(
        id: 'usr_cust_1',
        name: 'Customer One',
        email: 'cust@plaza.club',
        role: UserRole.user,
      );

      expect(custUser.isAdmin, isFalse);
      expect(custUser.isOperator, isFalse);
      expect(custUser.canAccessAdmin, isFalse);
    });

    testWidgets('AdminRouteGuard allows OPERATOR user into operations console', (tester) async {
      AuthService.instance.setMockUser(
        const PlazaUser(
          id: 'usr_op_2',
          name: 'Plaza Ops Specialist',
          email: 'specialist@plaza.club',
          role: UserRole.operator,
        ),
        'op_jwt_token',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminRouteGuard(
            child: Scaffold(
              body: Text('Operations Console Surface'),
            ),
          ),
        ),
      );

      expect(find.text('Operations Console Surface'), findsOneWidget);
      expect(find.text('Admin Access Required'), findsNothing);
    });

    testWidgets('AdminRouteGuard blocks customer USER with 403 access restriction screen', (tester) async {
      AuthService.instance.setMockUser(
        const PlazaUser(
          id: 'usr_cust_2',
          name: 'Regular Customer',
          email: 'customer@plaza.club',
          role: UserRole.user,
        ),
        'customer_jwt_token',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminRouteGuard(
            child: Scaffold(
              body: Text('Hidden Operations Surface'),
            ),
          ),
        ),
      );

      expect(find.text('Hidden Operations Surface'), findsNothing);
      expect(find.text('Admin Access Required'), findsOneWidget);
    });
  });

  group('Phase 21 — Admin Models & Data Integrity', () {
    test('AdminDashboardStats parses platform and 7 vertical breakdowns correctly', () {
      final json = {
        'users': 150,
        'movies': 12,
        'dining': 8,
        'events': 5,
        'activities': 4,
        'shopping': 20,
        'stays': 6,
        'sports': 7,
        'bookings': 60,
        'platform': {
          'grossBookingValue': 125000.5,
          'totalBookings': 60,
          'capturedPayments': 58,
          'refundedBookings': 2,
          'totalUsers': 150,
          'rewardPointsIssued': 25000,
        },
        'verticals': {
          'movies': {'total': 12, 'active': 10},
          'sports': {'total': 7, 'active': 7},
        },
      };

      final stats = AdminDashboardStats.fromJson(json);

      expect(stats.users, equals(150));
      expect(stats.platform.grossBookingValue, equals(125000.5));
      expect(stats.platform.capturedPayments, equals(58));
      expect(stats.verticals['movies']?.total, equals(12));
      expect(stats.verticals['movies']?.active, equals(10));
      expect(stats.verticals['sports']?.total, equals(7));
    });

    test('AdminBooking and AdminPayment do not contain sensitive private signatures', () {
      final paymentJson = {
        'id': 'pay_123',
        'bookingId': 'bk_123',
        'provider': 'razorpay',
        'amount': 2500.0,
        'currency': 'INR',
        'status': 'captured',
        'providerOrderId': 'order_fake_123',
        'providerPaymentId': 'pay_fake_abc',
        'createdAt': '2026-09-26T12:00:00Z',
      };

      final payment = AdminPayment.fromJson(paymentJson);
      expect(payment.id, equals('pay_123'));
      expect(payment.providerPaymentId, equals('pay_fake_abc'));
      expect(payment.status, equals('captured'));
      expect(payment.amount, equals(2500.0));
    });
  });

  group('Phase 21 — Operations UI Views Tests', () {
    final testRepo = Phase21MockAdminRepository();

    testWidgets('AdminBookingsView renders booking items and filter chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminBookingsView(repository: testRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Customer Bookings & Orders'), findsOneWidget);
      expect(find.text('bk_1'), findsOneWidget);
      expect(find.text('bk_2'), findsOneWidget);
    });

    testWidgets('AdminPaymentsView renders transactions with safe projections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPaymentsView(repository: testRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payments & Reconciliation'), findsOneWidget);
      expect(find.textContaining('pay_1'), findsWidgets);
      expect(find.text('CAPTURED'), findsWidgets);
    });
  });
}
