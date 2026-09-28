import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/auth/auth_service.dart';
import 'package:plaza/core/models/partner_models.dart';
import 'package:plaza/core/repositories/api_partner_repository.dart';
import 'package:plaza/features/admin/admin_dashboard_shell.dart';
import 'package:plaza/features/admin/views/admin_partners_view.dart';
import 'package:plaza/features/partner/onboarding/partner_onboarding_sheet.dart';
import 'package:plaza/features/partner/partner_dashboard_shell.dart';
import 'package:plaza/features/partner/partner_route_guard.dart';

void main() {
  setUp(() {
    AuthService.instance.signOut();
  });

  group('PLAZA Phase 22 - Role & Authorization Model Tests', () {
    test('UserRole.fromString correctly parses all Phase 22 roles', () {
      expect(UserRole.fromString('super_admin'), equals(UserRole.superAdmin));
      expect(UserRole.fromString('superadmin'), equals(UserRole.superAdmin));
      expect(UserRole.fromString('partner_owner'), equals(UserRole.partnerOwner));
      expect(UserRole.fromString('partnerowner'), equals(UserRole.partnerOwner));
      expect(UserRole.fromString('partner_manager'), equals(UserRole.partnerManager));
      expect(UserRole.fromString('partner_staff'), equals(UserRole.partnerStaff));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('operator'), equals(UserRole.operator));
      expect(UserRole.fromString('user'), equals(UserRole.user));
      expect(UserRole.fromString('unknown_role'), equals(UserRole.user));
    });

    test('PlazaUser correctly evaluates multi-tenant partner access permissions', () {
      const owner = PlazaUser(
        id: 'u-owner-1',
        name: 'Suresh Babu',
        email: 'owner@spicegarden.com',
        role: UserRole.partnerOwner,
        partnerId: 'prt-100',
      );
      expect(owner.isPartner, isTrue);
      expect(owner.isPartnerOwner, isTrue);
      expect(owner.canAccessPartnerPortal, isTrue);
      expect(owner.isAdmin, isFalse);

      const manager = PlazaUser(
        id: 'u-mgr-1',
        name: 'Rajesh Manager',
        email: 'mgr@spicegarden.com',
        role: UserRole.partnerManager,
        partnerId: 'prt-100',
      );
      expect(manager.isPartner, isTrue);
      expect(manager.isPartnerOwner, isFalse);
      expect(manager.canAccessPartnerPortal, isTrue);

      const staff = PlazaUser(
        id: 'u-staff-1',
        name: 'Kiran Staff',
        email: 'kiran@spicegarden.com',
        role: UserRole.partnerStaff,
        partnerId: 'prt-100',
      );
      expect(staff.isPartner, isTrue);
      expect(staff.canAccessPartnerPortal, isTrue);

      const customer = PlazaUser(
        id: 'u-cust-1',
        name: 'Regular Customer',
        email: 'cust@gmail.com',
        role: UserRole.user,
      );
      expect(customer.isPartner, isFalse);
      expect(customer.canAccessPartnerPortal, isFalse);

      const admin = PlazaUser(
        id: 'u-admin-1',
        name: 'Plaza Admin',
        email: 'admin@plaza.app',
        role: UserRole.admin,
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.canAccessPartnerPortal, isTrue);

      const superAdmin = PlazaUser(
        id: 'u-super-1',
        name: 'Platform Super Admin',
        email: 'super@plaza.app',
        role: UserRole.superAdmin,
      );
      expect(superAdmin.isSuperAdmin, isTrue);
      expect(superAdmin.isAdmin, isTrue);
      expect(superAdmin.canAccessPartnerPortal, isTrue);
    });
  });

  group('PLAZA Phase 22 - Domain Models & Serialization Tests', () {
    test('PartnerType.fromString parses all 5 commercial verticals', () {
      expect(PartnerType.fromString('restaurant'), equals(PartnerType.restaurant));
      expect(PartnerType.fromString('event_organizer'), equals(PartnerType.eventOrganizer));
      expect(PartnerType.fromString('activity_operator'), equals(PartnerType.activityOperator));
      expect(PartnerType.fromString('hotel'), equals(PartnerType.hotel));
      expect(PartnerType.fromString('stay'), equals(PartnerType.hotel));
      expect(PartnerType.fromString('sports_venue'), equals(PartnerType.sportsVenue));
    });

    test('PartnerStatus.fromString and display name evaluation', () {
      expect(PartnerStatus.fromString('draft'), equals(PartnerStatus.draft));
      expect(PartnerStatus.fromString('submitted'), equals(PartnerStatus.submitted));
      expect(PartnerStatus.fromString('under_review'), equals(PartnerStatus.underReview));
      expect(PartnerStatus.fromString('approved'), equals(PartnerStatus.approved));
      expect(PartnerStatus.fromString('rejected'), equals(PartnerStatus.rejected));
      expect(PartnerStatus.fromString('suspended'), equals(PartnerStatus.suspended));

      expect(PartnerStatus.approved.displayName, equals('Verified Partner'));
      expect(PartnerStatus.submitted.displayName, equals('Under Review (Gate 1)'));
    });

    test('PartnerProfile serialization and deserialization', () {
      final json = {
        'id': 'prt_101',
        'legalName': 'Royal Dining LLP',
        'displayName': 'Royal Feast',
        'partnerType': 'restaurant',
        'status': 'submitted',
        'email': 'feast@royal.com',
        'phone': '+91 99999 11111',
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'address': 'Marine Drive 10',
        'pinCode': '400020',
        'gstNumber': '27AABCR1234F1Z5',
        'panNumber': 'AABCR1234F',
      };

      final profile = PartnerProfile.fromJson(json);
      expect(profile.id, equals('prt_101'));
      expect(profile.displayName, equals('Royal Feast'));
      expect(profile.partnerType, equals(PartnerType.restaurant));
      expect(profile.status, equals(PartnerStatus.submitted));
      expect(profile.isApproved, isFalse);

      final outJson = profile.toJson();
      expect(outJson['displayName'], equals('Royal Feast'));
      expect(outJson['gstNumber'], equals('27AABCR1234F1Z5'));
    });

    test('PartnerBusinessListing Gate 2 status helper methods', () {
      const listingDraft = PartnerBusinessListing(
        id: 'bl-1',
        partnerId: 'prt_1',
        vertical: 'dining',
        name: 'The Orchid Grill',
        description: 'Luxury steaks',
        address: 'MG Road',
        city: 'Bengaluru',
        contactPhone: '+91 98888 77777',
        contactEmail: 'orchid@grill.com',
        status: 'draft',
      );
      expect(listingDraft.isDraft, isTrue);
      expect(listingDraft.isApproved, isFalse);
      expect(listingDraft.isSubmitted, isFalse);

      const listingApproved = PartnerBusinessListing(
        id: 'bl-2',
        partnerId: 'prt_1',
        vertical: 'dining',
        name: 'The Orchid Grill',
        description: 'Luxury steaks',
        address: 'MG Road',
        city: 'Bengaluru',
        contactPhone: '+91 98888 77777',
        contactEmail: 'orchid@grill.com',
        status: 'approved',
      );
      expect(listingApproved.isApproved, isTrue);
    });

    test('PartnerDocument Gate 1 status evaluation', () {
      const doc = PartnerDocument(
        id: 'doc-1',
        partnerId: 'prt_1',
        documentType: 'fssai_license',
        fileUrl: 'https://cdn.plaza.app/doc.pdf',
        fileName: 'fssai.pdf',
        status: 'approved',
      );
      expect(doc.isApproved, isTrue);
      expect(doc.isRejected, isFalse);
    });

    test('PartnerPayoutProfile masked account evaluation', () {
      const payout = PartnerPayoutProfile(
        id: 'pay-1',
        partnerId: 'prt_1',
        accountHolderName: 'Royal Feast',
        bankName: 'ICICI Bank',
        accountNumberMasked: '••••••••8819',
        ifscCode: 'ICIC0001000',
        payoutStatus: 'verified',
      );
      expect(payout.isVerified, isTrue);
      expect(payout.accountNumberMasked.endsWith('8819'), isTrue);
    });
  });

  group('PLAZA Phase 22 - PartnerRouteGuard Widget Tests', () {
    testWidgets('Blocks unauthorized customer and displays Partner Access Required', (tester) async {
      AuthService.instance.setMockUser(
        const PlazaUser(
          id: 'usr_reg_1',
          name: 'Regular Customer',
          email: 'cust@plaza.app',
          role: UserRole.user,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerRouteGuard(
            child: Scaffold(body: Text('Secret Partner Portal')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partner Access Required'), findsOneWidget);
      expect(find.text('Secret Partner Portal'), findsNothing);
      expect(find.text('Onboard as Partner'), findsOneWidget);
      expect(find.text('Back to App'), findsOneWidget);
    });

    testWidgets('Permits authorized partner owner to view portal', (tester) async {
      AuthService.instance.setMockUser(
        const PlazaUser(
          id: 'usr_owner_1',
          name: 'Suresh Babu',
          email: 'suresh@spicegarden.com',
          role: UserRole.partnerOwner,
          partnerId: 'prt_demo_1',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerRouteGuard(
            child: Scaffold(body: Text('Secret Partner Portal')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Secret Partner Portal'), findsOneWidget);
      expect(find.text('Partner Access Required'), findsNothing);
    });
  });

  group('PLAZA Phase 22 - PartnerOnboardingSheet Tests', () {
    testWidgets('Renders onboarding sheet with 5 commercial categories and advances steps', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = ApiPartnerRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PartnerOnboardingSheet.show(ctx, repository: repo),
                child: const Text('Open Onboarding'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Onboarding'));
      await tester.pumpAndSettle();

      // Step 1: Category Selection
      expect(find.text('Partner with PLAZA'), findsOneWidget);
      expect(find.text('Restaurant & Dining'), findsOneWidget);
      expect(find.text('Event Organizer'), findsOneWidget);
      expect(find.text('Activity Operator'), findsOneWidget);
      expect(find.text('Hotel / Resort / Stay'), findsOneWidget);
      expect(find.text('Sports Venue'), findsOneWidget);

      // Select Hotel / Stay category
      await tester.tap(find.text('Hotel / Resort / Stay'));
      await tester.pumpAndSettle();

      // Tap Next to step 2 (Business Details)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Legal Entity Name *'), findsOneWidget);
      expect(find.text('Brand / Customer Display Name *'), findsOneWidget);

      // Enter business details
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));
      await tester.enterText(textFields.at(0), 'Heritage Hospitality Pvt Ltd');
      await tester.enterText(textFields.at(1), 'Heritage Palace Stay');
      await tester.enterText(textFields.at(2), 'contact@heritage.com');
      await tester.enterText(textFields.at(3), '+91 98765 00000');
      await tester.pumpAndSettle();

      // Tap Next to step 3 (Business Location)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Location & Operating City'), findsOneWidget);
    });
  });

  group('PLAZA Phase 22 - PartnerDashboardShell Widget Tests', () {
    testWidgets('Renders Partner Dashboard with 6 modules, Gate 1 status, and actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = ApiPartnerRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: PartnerDashboardShell(
            partnerId: 'prt_demo_1',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header and Organization details
      expect(find.text('Spice Garden Fine Dining'), findsWidgets);
      expect(find.text('Restaurant / Dining'), findsOneWidget);

      // Overview Tab is loaded
      expect(find.text('Upcoming Bookings'), findsOneWidget);
      expect(find.text('Gross Revenue'), findsOneWidget);
      expect(find.text('Active Listings'), findsOneWidget);
      expect(find.text('Staff Team'), findsOneWidget);

      // Switch to Listings Tab (Gate 2)
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Listings')));
      await tester.pumpAndSettle();

      expect(find.text('Business Listings'), findsOneWidget);
      expect(find.text('Add Listing'), findsOneWidget);

      // Switch to Bookings Tab
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Bookings')));
      await tester.pumpAndSettle();

      expect(find.text('Customer Bookings'), findsOneWidget);
      expect(find.text('Dinner Table for 4'), findsOneWidget);
      expect(find.text('Check In Customer'), findsWidgets);

      // Perform Customer QR / Check-in
      await tester.tap(find.text('Check In Customer').first);
      await tester.pumpAndSettle();

      // Switch to Documents Tab (Gate 1)
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('KYC Docs')));
      await tester.pumpAndSettle();

      expect(find.text('KYC Verification Documents'), findsOneWidget);
      expect(find.text('fssai_cert.pdf'), findsOneWidget);

      // Switch to Staff Tab
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Staff')));
      await tester.pumpAndSettle();

      expect(find.text('Authorized Staff'), findsOneWidget);
      expect(find.text('Suresh Babu'), findsOneWidget);
      expect(find.text('Rajesh Manager'), findsOneWidget);

      // Switch to Payout Tab
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Payout')));
      await tester.pumpAndSettle();

      expect(find.text('Bank & Payout Profile'), findsOneWidget);
      expect(find.text('••••••••4892'), findsOneWidget);
      expect(find.text('HDFC Bank'), findsOneWidget);
    });
  });

  group('PLAZA Phase 22 - AdminPartnersView & Governance Tests', () {
    testWidgets('Admin can view partners, filter by status, and open inspection sheet', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = ApiPartnerRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(partnerRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & filters
      expect(find.text('Partner & Vendor Governance'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'ALL'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'SUBMITTED'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'APPROVED'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'SUSPENDED'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'REJECTED'), findsOneWidget);

      // Default demo partner card
      expect(find.text('Spice Garden Fine Dining'), findsOneWidget);
      expect(find.text('Inspect'), findsOneWidget);

      // Open Inspection Sheet
      await tester.tap(find.text('Inspect'));
      await tester.pumpAndSettle();

      // Inspection sheet tabs
      expect(find.text('GATE 1 STATUS: APPROVED'), findsOneWidget);
      expect(find.text('Suspend Partner'), findsOneWidget);
      expect(find.text('Overview & Payout'), findsOneWidget);
      expect(find.text('Gate 1: Documents'), findsOneWidget);
      expect(find.text('Gate 2: Listings'), findsOneWidget);

      // Inspect Gate 1 Documents
      await tester.tap(find.text('Gate 1: Documents'));
      await tester.pumpAndSettle();

      expect(find.text('FSSAI_LICENSE'), findsOneWidget);
      expect(find.text('Reject Doc'), findsOneWidget);

      // Inspect Gate 2 Listings
      await tester.tap(find.text('Gate 2: Listings'));
      await tester.pumpAndSettle();

      expect(find.text('Spice Garden Fine Dining'), findsWidgets);
    });

    testWidgets('AdminDashboardShell integrates Partners destination at index 18', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final partnerRepo = ApiPartnerRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardShell(
            partnerRepository: partnerRepo,
            initialSectionIndex: 18, // Partners
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partner & Vendor Governance'), findsOneWidget);
      expect(find.text('Spice Garden Fine Dining'), findsOneWidget);
    });
  });
}
