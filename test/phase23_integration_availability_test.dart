import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/integration_models.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/features/admin/views/admin_integrations_view.dart';
import 'package:plaza/shared/widgets/availability_badge.dart';
import 'views/admin_operations_test_repo.dart';

class Phase23MockAdminRepository extends Phase21MockAdminRepository {
  bool syncCalled = false;
  String? lastSyncedProvider;

  @override
  Future<ApiResponse<IntegrationHealthSummary>> getIntegrationHealth() async {
    return ApiResponse.success(IntegrationHealthSummary(
      status: 'HEALTHY',
      totalProviders: 9,
      activeProviders: 2,
      configuredProviders: 2,
      unconfiguredProviders: 7,
      recentSyncRuns: [
        IntegrationSyncRun(
          id: 'isync_101',
          provider: 'EXTERNAL_DINING_AGGREGATOR',
          vertical: 'dining',
          status: 'SUCCESS',
          recordsRead: 15,
          recordsCreated: 2,
          recordsUpdated: 13,
          recordsFailed: 0,
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          completedAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
      ],
    ));
  }

  @override
  Future<ApiResponse<List<IntegrationProviderInfo>>> getIntegrationProviders() async {
    return ApiResponse.success([
      const IntegrationProviderInfo(
        providerId: 'INTERNAL_PARTNER',
        providerName: 'PLAZA Partner Network',
        providerType: 'INTERNAL_PARTNER',
        vertical: 'multi',
        isConfigured: true,
        isEnabled: true,
        status: 'ACTIVE',
      ),
      const IntegrationProviderInfo(
        providerId: 'EXTERNAL_MOVIE_AGGREGATOR',
        providerName: 'Cinema Exhibition Gateway',
        providerType: 'EXTERNAL_PROVIDER',
        vertical: 'movie',
        isConfigured: false,
        isEnabled: false,
        status: 'DISABLED',
      ),
    ]);
  }

  @override
  Future<ApiResponse<List<IntegrationSyncRun>>> getIntegrationSyncRuns({
    String? provider,
    int limit = 20,
    int offset = 0,
  }) async {
    return ApiResponse.success([
      IntegrationSyncRun(
        id: 'isync_101',
        provider: 'EXTERNAL_DINING_AGGREGATOR',
        vertical: 'dining',
        status: 'SUCCESS',
        recordsRead: 15,
        recordsCreated: 2,
        recordsUpdated: 13,
        recordsFailed: 0,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        completedAt: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ]);
  }

  @override
  Future<ApiResponse<dynamic>> triggerIntegrationSync(String providerId, {String? vertical}) async {
    syncCalled = true;
    lastSyncedProvider = providerId;
    return ApiResponse.success({'success': true, 'providerId': providerId});
  }
}

void main() {
  group('Phase 23 — Integration Models & Availability Tests', () {
    test('AvailabilityStatus and Freshness enums parse correctly', () {
      expect(AvailabilityStatus.fromString('AVAILABLE'), equals(AvailabilityStatus.available));
      expect(AvailabilityStatus.fromString('LIMITED'), equals(AvailabilityStatus.limited));
      expect(AvailabilityStatus.fromString('SOLD_OUT'), equals(AvailabilityStatus.soldOut));
      expect(AvailabilityStatus.fromString('UNAVAILABLE'), equals(AvailabilityStatus.unavailable));
      expect(AvailabilityStatus.fromString('UNKNOWN'), equals(AvailabilityStatus.unknown));
      expect(AvailabilityStatus.fromString(null), equals(AvailabilityStatus.unknown));

      expect(AvailabilityFreshness.fromString('FRESH'), equals(AvailabilityFreshness.fresh));
      expect(AvailabilityFreshness.fromString('STALE'), equals(AvailabilityFreshness.stale));
      expect(AvailabilityFreshness.fromString('EXPIRED'), equals(AvailabilityFreshness.expired));
      expect(AvailabilityFreshness.fromString(null), equals(AvailabilityFreshness.unknown));
    });

    test('AvailabilityInfo parses JSON truthfully', () {
      final json = {
        'status': 'LIMITED',
        'freshness': 'FRESH',
        'remainingQuantity': 4,
        'totalCapacity': 50,
        'source': 'PARTNER',
        'lastUpdatedAt': '2026-09-28T12:00:00.000Z',
      };
      final info = AvailabilityInfo.fromJson(json);
      expect(info.status, equals(AvailabilityStatus.limited));
      expect(info.freshness, equals(AvailabilityFreshness.fresh));
      expect(info.remainingQuantity, equals(4));
      expect(info.totalCapacity, equals(50));
      expect(info.source, equals('PARTNER'));
      expect(info.lastUpdatedAt, isNotNull);
    });

    test('IntegrationProviderInfo parses JSON safely without secrets', () {
      final json = {
        'providerId': 'EXTERNAL_HOTEL_CHANNEL',
        'providerName': 'Global Hospitality Channel',
        'providerType': 'EXTERNAL_PROVIDER',
        'vertical': 'stay',
        'isConfigured': false,
        'isEnabled': false,
        'status': 'DISABLED',
      };
      final p = IntegrationProviderInfo.fromJson(json);
      expect(p.providerId, equals('EXTERNAL_HOTEL_CHANNEL'));
      expect(p.isConfigured, isFalse);
      expect(p.isEnabled, isFalse);
      expect(p.status, equals('DISABLED'));
    });
  });

  group('Phase 23 — AvailabilityBadge Widget Tests', () {
    testWidgets('renders Available state with green checkmark', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvailabilityBadge(
              status: AvailabilityStatus.available,
              remainingQuantity: 15,
            ),
          ),
        ),
      );

      expect(find.text('Available'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders Limited state with quantity count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvailabilityBadge(
              status: AvailabilityStatus.limited,
              remainingQuantity: 3,
            ),
          ),
        ),
      );

      expect(find.text('Limited (3 left)'), findsOneWidget);
      expect(find.byIcon(Icons.timelapse_rounded), findsOneWidget);
    });

    testWidgets('renders Sold Out state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvailabilityBadge(
              status: AvailabilityStatus.soldOut,
            ),
          ),
        ),
      );

      expect(find.text('Sold Out'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('renders Check Availability when status is unknown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvailabilityBadge(
              status: AvailabilityStatus.unknown,
            ),
          ),
        ),
      );

      expect(find.text('Check Availability'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });

    testWidgets('renders Stale freshness tag when requested', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvailabilityBadge(
              status: AvailabilityStatus.available,
              freshness: AvailabilityFreshness.stale,
              showFreshness: true,
            ),
          ),
        ),
      );

      expect(find.text('Stale'), findsOneWidget);
    });
  });

  group('Phase 23 — AdminIntegrationsView Widget Tests', () {
    testWidgets('renders integration operations header, metrics, and provider cards', (tester) async {
      final mockRepo = Phase23MockAdminRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminIntegrationsView(repository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header & health status
      expect(find.text('Integration Operations'), findsOneWidget);
      expect(find.text('HEALTHY'), findsOneWidget);

      // Metrics cards
      expect(find.text('Total Adapters'), findsOneWidget);
      expect(find.text('Live / Active'), findsOneWidget);
      expect(find.text('Configured'), findsOneWidget);
      expect(find.text('Disabled (No Keys)'), findsOneWidget);

      // Provider cards
      expect(find.text('PLAZA Partner Network'), findsOneWidget);
      expect(find.text('Cinema Exhibition Gateway'), findsOneWidget);
      expect(find.text('Configured: NO'), findsOneWidget);
      expect(find.text('Enabled: NO'), findsOneWidget);

      // Recent sync run
      expect(find.textContaining('EXTERNAL_DINING_AGGREGATOR'), findsOneWidget);
    });

    testWidgets('triggers manual sync upon clicking Sync Now button', (tester) async {
      final mockRepo = Phase23MockAdminRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminIntegrationsView(repository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final syncButtons = find.widgetWithText(ElevatedButton, 'Sync Now');
      expect(syncButtons, findsWidgets);

      await tester.tap(syncButtons.first);
      await tester.pump();

      expect(mockRepo.syncCalled, isTrue);
      expect(mockRepo.lastSyncedProvider, equals('INTERNAL_PARTNER'));
    });
  });
}
