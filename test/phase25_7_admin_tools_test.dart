import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/admin_models.dart';
import 'package:plaza/features/admin/views/admin_incidents_view.dart';
import 'package:plaza/features/admin/views/admin_payments_view.dart';
import 'views/admin_operations_test_repo.dart';

void main() {
  group('Phase 25.7 Admin Reconciliation & Incident Models', () {
    test('ReconciliationDashboardData deserialization from JSON', () {
      final json = {
        'reconciliation': {
          'total': 15,
          'required': 3,
          'inProgress': 1,
          'resolved': 10,
          'failed': 1,
          'notRequired': 0,
        },
        'recovery': {
          'total': 8,
          'required': 2,
          'inProgress': 1,
          'resolved': 5,
          'failed': 0,
        },
        'webhooks': {
          'total': 25,
          'received': 2,
          'processing': 0,
          'processed': 20,
          'failed': 2,
          'ignored': 1,
        },
        'mismatches': {
          'AMOUNT_MISMATCH': 2,
          'STATUS_MISMATCH': 1,
        },
        'manualInterventionRequired': 5,
        'paymentConfig': {
          'paymentMode': 'SIMULATED',
          'razorpayLiveEnabled': false,
          'livePaymentBlocked': true,
          'status': 'SIMULATED_SAFE',
        },
      };

      final data = ReconciliationDashboardData.fromJson(json);
      expect(data.reconciliation['total'], 15);
      expect(data.reconciliation['required'], 3);
      expect(data.reconciliation['resolved'], 10);
      expect(data.recovery['total'], 8);
      expect(data.recovery['required'], 2);
      expect(data.webhooks['total'], 25);
      expect(data.webhooks['failed'], 2);
      expect(data.manualInterventionRequired, 5);
      expect(data.paymentConfig['paymentMode'], 'SIMULATED');
      expect(data.paymentConfig['razorpayLiveEnabled'], false);
      expect(data.paymentConfig['livePaymentBlocked'], true);
      expect(data.mismatches['AMOUNT_MISMATCH'], 2);
    });

    test('UnifiedIncidentItem deserialization from JSON', () {
      final json = {
        'id': 'inc_rec_001',
        'type': 'RECOVERY',
        'title': 'Payment Recovery: TIMEOUT',
        'description': 'Gateway timeout during capture',
        'status': 'REQUIRED',
        'severity': 'HIGH',
        'referenceId': 'pay_sim_123',
        'paymentId': 'pay_sim_123',
        'bookingId': 'bk_001',
        'failureCategory': 'UNKNOWN_PROVIDER_OUTCOME',
        'requiresManualIntervention': true,
        'createdAt': '2026-09-30T10:00:00.000Z',
        'updatedAt': '2026-09-30T10:05:00.000Z',
        'resolvedAt': null,
      };

      final item = UnifiedIncidentItem.fromJson(json);
      expect(item.id, 'inc_rec_001');
      expect(item.type, 'RECOVERY');
      expect(item.title, 'Payment Recovery: TIMEOUT');
      expect(item.severity, 'HIGH');
      expect(item.requiresManualIntervention, true);
      expect(item.paymentId, 'pay_sim_123');
    });

    test('ReconciliationRecordItem and ReconciliationDetailData deserialization', () {
      final json = {
        'id': 'recon_001',
        'paymentId': 'pay_001',
        'bookingId': 'bk_001',
        'provider': 'simulated',
        'canonicalPaymentStatus': 'CAPTURED',
        'observedProviderStatus': 'PENDING',
        'canonicalAmount': 543,
        'canonicalAmountInMinorUnits': 54300,
        'observedAmountInMinorUnits': 54300,
        'canonicalCurrency': 'INR',
        'observedCurrency': 'INR',
        'mismatchCategory': 'STATUS_MISMATCH',
        'status': 'REQUIRED',
        'attemptCount': 1,
        'requiresManualIntervention': true,
        'createdAt': '2026-09-30T10:00:00.000Z',
        'updatedAt': '2026-09-30T10:00:00.000Z',
        'canonicalVsObserved': {
          'status': {'canonical': 'CAPTURED', 'observed': 'PENDING', 'matches': false},
          'amount': {'canonical': 543, 'canonicalMinor': 54300, 'observedMinor': 54300, 'matches': true},
          'currency': {'canonical': 'INR', 'observed': 'INR', 'matches': true},
        },
        'timeline': [
          {
            'timestamp': '2026-09-30T10:00:00.000Z',
            'event': 'PAYMENT_CREATED',
            'actor': 'system',
            'status': 'PENDING',
            'description': 'Payment intent created',
          }
        ],
      };

      final detail = ReconciliationDetailData.fromJson(json);
      expect(detail.record.id, 'recon_001');
      expect(detail.record.mismatchCategory, 'STATUS_MISMATCH');
      expect(detail.canonicalVsObserved.isNotEmpty, true);
      expect(detail.canonicalVsObserved['status']?['matches'], false);
      expect(detail.timeline.length, 1);
      expect(detail.timeline.first.event, 'PAYMENT_CREATED');
    });
  });

  group('Phase 25.7 Flutter Admin Views Widget Tests', () {
    testWidgets('AdminIncidentsView renders KPI cards, tabs, and incident items', (tester) async {
      final mockRepo = Phase21MockAdminRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminIncidentsView(repository: mockRepo),
          ),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Header and search
      expect(find.text('Admin Incident Center'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // KPI cards
      expect(find.text('Manual Action Needed'), findsOneWidget);
      expect(find.text('Recovery Active'), findsOneWidget);
      expect(find.text('Recon Discrepancies'), findsOneWidget);
      expect(find.text('Webhook Anomalies'), findsOneWidget);

      // Filter tabs
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('RECOVERY'), findsOneWidget);
      expect(find.text('RECONCILIATION'), findsOneWidget);
      expect(find.text('WEBHOOK'), findsOneWidget);

      // Incident cards rendered
      expect(find.text('Payment Recovery: UNKNOWN_PROVIDER_OUTCOME'), findsOneWidget);
      expect(find.text('Reconciliation: AMOUNT_MISMATCH'), findsOneWidget);
    });

    testWidgets('AdminPaymentsView renders Transaction Ledger and switches to Reconciliation Queue', (tester) async {
      final mockRepo = Phase21MockAdminRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPaymentsView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top TabBar with Transactions and Reconciliation
      expect(find.text('Transaction Ledger'), findsOneWidget);
      expect(find.text('Reconciliation Queue'), findsOneWidget);

      // Switch to Reconciliation Queue tab
      await tester.tap(find.text('Reconciliation Queue'));
      await tester.pumpAndSettle();

      // Reconciliation Queue view elements
      expect(find.text('Run Batch Reconcile'), findsOneWidget);
      expect(find.text('SIMULATED (LIVE BLOCKED)'), findsOneWidget);

      // Mismatch items
      expect(find.text('AMOUNT_MISMATCH'), findsWidgets);
      expect(find.textContaining('pay_recon_101'), findsWidgets);
    });
  });
}
