import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/admin_models.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/admin_repository.dart';
import 'package:plaza/features/admin/views/admin_system_health_view.dart';

class _FakeAdminRepository implements AdminRepository {
  final AdminSystemHealth health;
  _FakeAdminRepository(this.health);

  @override
  Future<ApiResponse<AdminSystemHealth>> getSystemHealth() async {
    return ApiResponse.success(health);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 25.1 — Flutter Payment Configuration & Safety Gate', () {
    test('AdminSystemHealth.fromJson parses canonical paymentMode and safety gate flags', () {
      final json = {
        'status': 'HEALTHY',
        'timestamp': '2026-09-28T18:00:00.000Z',
        'uptimeSeconds': 3600,
        'environment': 'production',
        'paymentMode': 'SIMULATED',
        'razorpayLiveEnabled': false,
        'razorpayConfigured': false,
        'paymentConfigStatus': 'SIMULATED_READY',
        'services': {
          'api': {'status': 'UP', 'version': '1.0.0'},
          'database': {'status': 'UP', 'latencyMs': 2},
          'payments': {
            'provider': 'simulated',
            'mode': 'TEST/SANDBOX',
            'paymentMode': 'SIMULATED',
            'razorpayLiveEnabled': false,
            'razorpayConfigured': false,
            'paymentConfigStatus': 'SIMULATED_READY',
            'webhookConfigured': false,
          },
          'notifications': {'smsProvider': 'twilio', 'mode': 'TEST/SANDBOX'},
        },
      };

      final health = AdminSystemHealth.fromJson(json);
      expect(health.canonicalPaymentMode, 'SIMULATED');
      expect(health.razorpayLiveEnabled, isFalse);
      expect(health.razorpayConfigured, isFalse);
      expect(health.paymentConfigStatus, 'SIMULATED_READY');
      expect(health.paymentWebhookConfigured, isFalse);
    });

    test('EnvironmentConfig defaults razorpayLiveEnabled to false and never embeds secrets', () {
      expect(EnvironmentConfig.razorpayLiveEnabled, isFalse);

      final envFile = File('lib/core/network/environment_config.dart');
      final content = envFile.readAsStringSync();
      expect(content.contains('RAZORPAY_KEY_SECRET'), isFalse);
      expect(content.contains('RAZORPAY_WEBHOOK_SECRET'), isFalse);
    });

    testWidgets(
      'AdminSystemHealthView displays read-only payment config status and has no live activation button',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const mockHealth = AdminSystemHealth(
          status: 'HEALTHY',
          timestamp: '2026-09-28T18:00:00.000Z',
          uptimeSeconds: 1200,
          environment: 'production',
          apiStatus: 'UP',
          dbStatus: 'UP',
          dbLatencyMs: 3,
          paymentProvider: 'simulated',
          paymentMode: 'TEST/SANDBOX',
          canonicalPaymentMode: 'SIMULATED',
          razorpayLiveEnabled: false,
          razorpayConfigured: false,
          paymentConfigStatus: 'SIMULATED_READY',
          paymentWebhookConfigured: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdminSystemHealthView(
                repository: _FakeAdminRepository(mockHealth),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Payment Configuration & Safety Gate'), findsOneWidget);
        expect(find.text('SIMULATED_READY'), findsOneWidget);
        expect(find.text('SIMULATED'), findsOneWidget);
        expect(find.text('Configured: NO'), findsOneWidget);
        expect(find.text('DISABLED'), findsOneWidget);

        // Ensure there is NO one-click live payment activation toggle or button
        expect(find.textContaining('Enable Live Payments'), findsNothing);
        expect(find.byType(Switch), findsNothing);
      },
    );
  });
}
