import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/auth/auth_service.dart';
import 'package:plaza/core/models/admin_models.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/repositories/admin_repository.dart';
import 'package:plaza/features/admin/admin_dashboard_shell.dart';
import 'package:plaza/features/admin/admin_route_guard.dart';
import 'package:plaza/features/admin/views/admin_audit_logs_view.dart';
import 'package:plaza/features/admin/views/admin_movies_view.dart';
import 'package:plaza/features/admin/views/admin_overview_view.dart';
import 'package:plaza/features/admin/views/admin_screens_view.dart';
import 'package:plaza/features/admin/views/admin_shows_view.dart';
import 'package:plaza/features/admin/views/admin_theatres_view.dart';
import 'package:plaza/features/admin/views/admin_users_view.dart';
import 'package:plaza/features/admin/views/admin_vertical_catalog_view.dart';
import 'package:plaza/features/navigation/plaza_navigation_shell.dart';

/// Mock Admin Repository for UI widget tests conforming to AdminRepository
class MockAdminRepository implements AdminRepository {
  final List<AdminMovie> movies = [
    AdminMovie(
      id: 'm-1',
      title: 'Kalki 2898 AD',
      synopsis: 'Sci-fi epic set in the dystopian future.',
      posterUrl: '',
      backdropUrl: '',
      rating: 9.0,
      votesCount: 45000,
      genres: ['Sci-Fi', 'Action'],
      duration: '180m',
      primaryLanguage: 'Telugu',
      availableLanguages: ['Telugu', 'Hindi'],
      formats: ['2D', '3D', 'IMAX'],
      certificate: 'U/A',
      releaseDate: '2024-06-27',
      startingPrice: 250,
      director: 'Nag Ashwin',
      isNowShowing: true,
    ),
  ];

  final List<AdminTheatre> theatres = [
    AdminTheatre(
      id: 'th-1',
      name: 'PVR Inorbit Mall',
      location: 'Madhapur, Hyderabad',
      city: 'Hyderabad',
      address: 'Inorbit Mall 4th Floor',
      isActive: true,
    ),
  ];

  final List<AdminScreen> screens = [
    AdminScreen(
      id: 'sc-1',
      theatreId: 'th-1',
      name: 'Audi 1 (IMAX)',
      screenType: 'IMAX Laser',
      capacity: 350,
      isActive: true,
    ),
  ];

  final List<AdminShow> shows = [
    AdminShow(
      id: 'sh-1',
      movieId: 'm-1',
      theatreId: 'th-1',
      screenId: 'sc-1',
      showDate: '2026-09-30',
      startTime: '18:30',
      format: 'IMAX 3D',
      language: 'Telugu',
      pricing: const AdminShowPricing(gold: 250, premium: 350, recliner: 500),
      status: 'active',
    ),
  ];

  final List<AdminCatalogItem> diningItems = [
    AdminCatalogItem(
      id: 'din-1',
      nameOrTitle: 'Jewel of Nizam - The Minar',
      category: 'Fine Dining',
      location: 'Gandipet, Hyderabad',
      price: 2500,
      rating: 4.8,
      isPublished: true,
    ),
    AdminCatalogItem(
      id: 'din-2',
      nameOrTitle: 'Hidden Bistro',
      category: 'Cafe',
      location: 'Banjara Hills',
      price: 800,
      rating: 4.2,
      isPublished: false,
    ),
  ];

  final List<AdminUser> users = [
    AdminUser(
      id: 'u-admin',
      name: 'System Admin',
      email: 'admin@plaza.com',
      role: 'admin',
      createdAt: DateTime.now(),
    ),
    AdminUser(
      id: 'u-customer',
      name: 'Regular Customer',
      email: 'customer@gmail.com',
      role: 'user',
      createdAt: DateTime.now(),
    ),
  ];

  final List<AdminAuditLog> auditLogs = [
    AdminAuditLog(
      id: 'log-1',
      actorUserId: 'u-admin',
      actorEmail: 'admin@plaza.com',
      action: 'UPDATE_ROLE',
      resourceType: 'user',
      resourceId: 'u-customer',
      createdAt: DateTime.now(),
      metadata: {'previousRole': 'user', 'newRole': 'admin'},
    ),
  ];

  @override
  Future<ApiResponse<AdminDashboardStats>> getDashboardStats() async {
    return ApiResponse.success(
      AdminDashboardStats(
        users: users.length,
        movies: movies.length,
        dining: diningItems.length,
        events: 1,
        activities: 1,
        shopping: 1,
        stays: 1,
        sports: 1,
        bookings: 0,
      ),
    );
  }

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers({int limit = 50, int offset = 0}) async {
    return ApiResponse.success(users);
  }

  @override
  Future<ApiResponse<AdminUser>> getUserById(String id) async {
    final u = users.firstWhere((element) => element.id == id, orElse: () => users.first);
    return ApiResponse.success(u);
  }

  @override
  Future<ApiResponse<dynamic>> updateUserRole(String id, String role) async {
    final idx = users.indexWhere((u) => u.id == id);
    if (idx != -1) {
      users[idx] = AdminUser(
        id: users[idx].id,
        name: users[idx].name,
        email: users[idx].email,
        role: role,
        createdAt: users[idx].createdAt,
      );
    }
    return ApiResponse.success({'success': true});
  }

  @override
  Future<ApiResponse<List<AdminAuditLog>>> getAuditLogs({int limit = 50, int offset = 0}) async {
    return ApiResponse.success(auditLogs);
  }

  @override
  Future<ApiResponse<List<AdminMovie>>> getMovies({int limit = 50, int offset = 0}) async {
    return ApiResponse.success(movies);
  }

  @override
  Future<ApiResponse<AdminMovie>> createMovie(Map<String, dynamic> dto) async {
    return ApiResponse.success(movies.first);
  }

  @override
  Future<ApiResponse<AdminMovie>> updateMovie(String id, Map<String, dynamic> dto) async {
    return ApiResponse.success(movies.first);
  }

  @override
  Future<ApiResponse<dynamic>> deleteMovie(String id) async {
    return ApiResponse.success({'deleted': true});
  }

  @override
  Future<ApiResponse<List<AdminTheatre>>> getTheatres({int limit = 50, int offset = 0}) async {
    return ApiResponse.success(theatres);
  }

  @override
  Future<ApiResponse<AdminTheatre>> createTheatre(Map<String, dynamic> dto) async {
    return ApiResponse.success(theatres.first);
  }

  @override
  Future<ApiResponse<AdminTheatre>> updateTheatre(String id, Map<String, dynamic> dto) async {
    return ApiResponse.success(theatres.first);
  }

  @override
  Future<ApiResponse<List<AdminScreen>>> getScreens({String? theatreId, int limit = 50, int offset = 0}) async {
    return ApiResponse.success(screens);
  }

  @override
  Future<ApiResponse<AdminScreen>> createScreen(String theatreId, Map<String, dynamic> dto) async {
    return ApiResponse.success(screens.first);
  }

  @override
  Future<ApiResponse<AdminScreen>> updateScreen(String id, Map<String, dynamic> dto) async {
    return ApiResponse.success(screens.first);
  }

  @override
  Future<ApiResponse<List<AdminShow>>> getShows({String? movieId, String? theatreId, String? date, int limit = 50, int offset = 0}) async {
    return ApiResponse.success(shows);
  }

  @override
  Future<ApiResponse<AdminShow>> createShow(Map<String, dynamic> dto) async {
    return ApiResponse.success(shows.first);
  }

  @override
  Future<ApiResponse<AdminShow>> updateShow(String id, Map<String, dynamic> dto) async {
    return ApiResponse.success(shows.first);
  }

  @override
  Future<ApiResponse<dynamic>> deleteShow(String id) async {
    return ApiResponse.success({'cancelled': true});
  }

  @override
  Future<ApiResponse<List<AdminCatalogItem>>> getVerticalItems(String vertical, {int limit = 50, int offset = 0}) async {
    return ApiResponse.success(diningItems);
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> createVerticalItem(String vertical, Map<String, dynamic> dto) async {
    return ApiResponse.success(diningItems.first);
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> updateVerticalItem(String vertical, String id, Map<String, dynamic> dto) async {
    return ApiResponse.success(diningItems.first);
  }

  @override
  Future<ApiResponse<dynamic>> deleteVerticalItem(String vertical, String id) async {
    return ApiResponse.success({'deleted': true});
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> publishVerticalItem(String vertical, String id) async {
    final idx = diningItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      diningItems[idx] = AdminCatalogItem(
        id: diningItems[idx].id,
        nameOrTitle: diningItems[idx].nameOrTitle,
        category: diningItems[idx].category,
        location: diningItems[idx].location,
        price: diningItems[idx].price,
        rating: diningItems[idx].rating,
        isPublished: true,
      );
      return ApiResponse.success(diningItems[idx]);
    }
    return ApiResponse.failure('Item not found');
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> unpublishVerticalItem(String vertical, String id) async {
    final idx = diningItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      diningItems[idx] = AdminCatalogItem(
        id: diningItems[idx].id,
        nameOrTitle: diningItems[idx].nameOrTitle,
        category: diningItems[idx].category,
        location: diningItems[idx].location,
        price: diningItems[idx].price,
        rating: diningItems[idx].rating,
        isPublished: false,
      );
      return ApiResponse.success(diningItems[idx]);
    }
    return ApiResponse.failure('Item not found');
  }
}

void main() {
  setUp(() {
    AuthService.instance.signOut();
  });

  group('Phase 12.5 - Admin Foundation & Role Model Tests', () {
    test('UserRole parsing correctly maps admin and user strings', () {
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('ADMIN'), equals(UserRole.admin));
      expect(UserRole.fromString('user'), equals(UserRole.user));
      expect(UserRole.fromString('customer'), equals(UserRole.user));
      expect(UserRole.fromString(null), equals(UserRole.user));
    });

    test('PlazaUser accurately evaluates isAdmin flag', () {
      const admin = PlazaUser(
        id: 'u-1',
        name: 'Super Admin',
        email: 'admin@plaza.com',
        role: UserRole.admin,
      );
      expect(admin.isAdmin, isTrue);

      const customer = PlazaUser(
        id: 'u-2',
        name: 'Regular Customer',
        email: 'customer@gmail.com',
        role: UserRole.user,
      );
      expect(customer.isAdmin, isFalse);
    });
  });

  group('Phase 12.5 - AdminRouteGuard Tests', () {
    testWidgets('Blocks non-admin user and renders access restriction notice', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminRouteGuard(
            child: Scaffold(
              body: Text('Secret Operations Console'),
            ),
          ),
        ),
      );

      // Access restriction screen must be rendered
      expect(find.text('Admin Access Required'), findsOneWidget);
      expect(find.text('Secret Operations Console'), findsNothing);
      expect(find.text('Return to PLAZA Home'), findsOneWidget);
    });

    testWidgets('Allows admin user and renders destination child view', (tester) async {
      // Authenticate as ADMIN
      AuthService.instance.setMockUser(
        const PlazaUser(
          id: 'u-adm',
          name: 'Platform Ops Admin',
          email: 'admin@plaza.com',
          role: UserRole.admin,
        ),
        'valid-admin-jwt',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminRouteGuard(
            child: Scaffold(
              body: Text('Secret Operations Console'),
            ),
          ),
        ),
      );

      // Secret Operations Console must be visible to admin
      expect(find.text('Secret Operations Console'), findsOneWidget);
      expect(find.text('Admin Access Required'), findsNothing);
    });
  });

  group('Phase 12.5 - Customer UI Protection Tests', () {
    testWidgets('Standard customer navigation shell displays exactly the 5 customer tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlazaNavigationShell(),
        ),
      );

      // Bottom bar must display exactly customer destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // No admin tabs or buttons anywhere in customer navigation
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Console'), findsNothing);
      expect(find.text('Manage Shows'), findsNothing);
    });
  });

  group('Phase 12.5 - Admin UI Views Tests', () {
    final mockRepo = MockAdminRepository();

    testWidgets('AdminOverviewView renders system status and vertical metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminOverviewView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Executive Control Cockpit'), findsOneWidget);
      expect(find.text('Live system overview across all PLAZA city experiences & services.'), findsOneWidget);
      expect(find.text('Users & Members'), findsOneWidget);
      expect(find.text('Movies & Releases'), findsOneWidget);
      expect(find.text('Theatres & Venues'), findsOneWidget);
      expect(find.text('Dining Spots'), findsOneWidget);
    });

    testWidgets('AdminMoviesView renders movie catalog and search filter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminMoviesView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Movie Catalog & Releases'), findsOneWidget);
      expect(find.text('Kalki 2898 AD'), findsOneWidget);
      expect(find.text('Now Showing'), findsOneWidget);
      expect(find.text('Add Release'), findsOneWidget);
    });

    testWidgets('AdminTheatresView renders theatre multiplexes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminTheatresView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Theatre Multiplexes & Venues'), findsOneWidget);
      expect(find.text('PVR Inorbit Mall'), findsOneWidget);
      expect(find.text('Add Theatre'), findsOneWidget);
    });

    testWidgets('AdminScreensView renders screens catalog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminScreensView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Audi & Screen Management'), findsOneWidget);
      expect(find.text('Audi 1 (IMAX)'), findsOneWidget);
      expect(find.text('Add Screen'), findsOneWidget);
    });

    testWidgets('AdminShowsView renders showtimes and pricing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminShowsView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Showtimes & Slots Scheduler'), findsOneWidget);
      expect(find.text('Kalki 2898 AD • 18:30'), findsOneWidget);
      expect(find.text('Schedule Show'), findsOneWidget);
    });

    testWidgets('AdminVerticalCatalogView displays items and handles publish toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminVerticalCatalogView(
              vertical: 'dining',
              title: 'Dining Directory',
              description: 'Fine Dining and Restaurants',
              icon: Icons.restaurant_rounded,
              accentColor: Colors.orange,
              repository: mockRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dining Directory'), findsOneWidget);
      expect(find.text('Jewel of Nizam - The Minar'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Hidden Bistro'), findsOneWidget);
      expect(find.text('Unpublished'), findsOneWidget);

      // Tap on Published badge to trigger Unpublish confirmation dialog
      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();

      expect(find.text('Unpublish Item?'), findsOneWidget);
      expect(find.text('Unpublish'), findsOneWidget);

      // Confirm unpublish
      await tester.tap(find.text('Unpublish'));
      await tester.pumpAndSettle();
    });

    testWidgets('AdminUsersView renders user directory and role modification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminUsersView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User Directory & Roles'), findsOneWidget);
      expect(find.text('System Admin'), findsOneWidget);
      expect(find.text('Regular Customer'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('USER'), findsOneWidget);

      // Tap Edit Role for Regular Customer
      await tester.tap(find.byIcon(Icons.manage_accounts_outlined).last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Change User Role'), findsOneWidget);
      expect(find.text('Customer (USER)'), findsOneWidget);
      expect(find.text('Administrator (ADMIN)'), findsOneWidget);
    });

    testWidgets('AdminAuditLogsView renders security audit log entries', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminAuditLogsView(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Security Audit Trail'), findsOneWidget);
      expect(find.text('UPDATE_ROLE'), findsOneWidget);
      expect(find.text('user: u-customer'), findsOneWidget);
    });
  });

  group('Phase 12.5 - AdminDashboardShell Navigation Tests', () {
    final mockRepo = MockAdminRepository();

    testWidgets('AdminDashboardShell renders sidebar/drawer and switches sections', (tester) async {
      // Set tester window size to desktop/tablet size (e.g. 1280x1024)
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardShell(repository: mockRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Desktop sidebar shows brand and destinations
      expect(find.text('PLAZA'), findsWidgets);
      expect(find.text('OPERATIONS CONSOLE'), findsOneWidget);
      expect(find.text('Executive Control Cockpit'), findsOneWidget);

      // Switch to Movies section
      await tester.tap(find.widgetWithText(ListTile, 'Movies').first);
      await tester.pumpAndSettle();

      expect(find.text('Movie Catalog & Releases'), findsOneWidget);
      expect(find.text('Kalki 2898 AD'), findsOneWidget);

      // Switch to Dining section
      await tester.tap(find.widgetWithText(ListTile, 'Dining').first);
      await tester.pumpAndSettle();

      expect(find.text('Dining & Restaurants'), findsOneWidget);
      expect(find.text('Jewel of Nizam - The Minar'), findsOneWidget);

      // Switch to Audit Logs
      await tester.tap(find.widgetWithText(ListTile, 'Audit Logs').first);
      await tester.pumpAndSettle();

      expect(find.text('Security Audit Trail'), findsOneWidget);
    });
  });
}
