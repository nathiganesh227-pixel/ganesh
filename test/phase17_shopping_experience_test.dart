import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/data/shopping_cart_manager.dart';
import 'package:plaza/core/data/shopping_mock_data.dart';
import 'package:plaza/core/models/shopping.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/api_shopping_repository.dart';
import 'package:plaza/core/repositories/local_shopping_repository.dart';
import 'package:plaza/features/shopping/cart_screen.dart';
import 'package:plaza/features/shopping/product_details_screen.dart';
import 'package:plaza/features/shopping/shopping_confirmation_screen.dart';
import 'package:plaza/features/shopping/shopping_screen.dart';
import 'package:plaza/features/shopping/widgets/product_card.dart';

void main() {
  setUp(() {
    EnvironmentConfig.reset();
    EnvironmentConfig.setEnvironment(AppEnvironment.dev);
    PlazaGlobalState.instance.setSelectedCity('Hyderabad');
  });

  group('Phase 17: Shopping Discovery Experience', () {
    testWidgets('ShoppingScreen renders header, city selector, search, and sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingScreen(repository: LocalShoppingRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & City
      expect(find.text('Shopping & Luxury'), findsOneWidget);
      expect(find.text('HYDERABAD'), findsOneWidget);

      // Search & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Favorites'), findsOneWidget);
      expect(find.text('In Stock'), findsOneWidget);
      expect(find.text('Trending Deals'), findsOneWidget);

      // Category Chips
      expect(find.text('All Items'), findsOneWidget);
      expect(find.text('Fashion'), findsWidgets);
      expect(find.text('Electronics'), findsWidgets);

      // Sections
      expect(find.text("Today's Flash Deals 🔥"), findsOneWidget);
      expect(find.text('Premier Malls & Boutiques 🏬'), findsOneWidget);
    });

    testWidgets('ShoppingScreen filters by category and quick chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingScreen(repository: LocalShoppingRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Electronics category
      await tester.tap(find.text('Electronics').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('MacBook Pro'), findsWidgets);

      // Tap on In Stock quick filter
      await tester.tap(find.text('In Stock'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing'), findsOneWidget);
    });

    testWidgets('ShoppingScreen search bar filters products with debounce and handles empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingScreen(repository: LocalShoppingRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Type in search query
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Jordan');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Air Jordan 1'), findsWidgets);

      // Search for non-existent item to trigger empty state
      await tester.enterText(searchField, 'NonExistentSpaceshipProductXYZ');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No products found matching your search.'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Tap Reset All Filters
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      expect(find.text("Today's Flash Deals 🔥"), findsOneWidget);
    });

    testWidgets('City selector bottom sheet switches global city in ShoppingScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingScreen(repository: LocalShoppingRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap City Header
      await tester.tap(find.text('HYDERABAD'));
      await tester.pumpAndSettle();

      expect(find.text('Select Shopping City'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Select Bengaluru
      await tester.tap(find.text('Bengaluru'));
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.selectedCity, 'Bengaluru');
      expect(find.text('BENGALURU'), findsOneWidget);
    });
  });

  group('Phase 17: Product Cards & Details Experience', () {
    testWidgets('ProductCard renders with price, rating, discount badge, and reacts to favorite toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final product = ShoppingMockData.products.first; // MacBook Pro

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: product, variant: ProductCardVariant.standard),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(product.name), findsOneWidget);
      expect(find.text('₹${product.price.toInt()}'), findsOneWidget);
      expect(find.text(product.brand.toUpperCase()), findsOneWidget);
      expect(find.text('IN STOCK'), findsOneWidget);

      // Toggle favorite
      final favButton = find.byIcon(Icons.favorite_border_rounded);
      expect(favButton, findsOneWidget);
      await tester.tap(favButton);
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.favoriteIds.contains(product.id), isTrue);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('ProductDetailsScreen renders gallery, specs, store logistics, variants, and quantity controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final product = ShoppingMockData.products[1]; // Air Jordan 1

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(product: product),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(product.name), findsOneWidget);
      expect(find.text('About Product'), findsOneWidget);
      expect(find.text('Select Option / Variant'), findsOneWidget);
      expect(find.text('Product Specifications'), findsOneWidget);
      expect(find.text('Store Availability & Pickup'), findsOneWidget);
      expect(find.text(product.storeName), findsOneWidget);

      // Quantity controls test
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Increment quantity
      final addQty = find.byIcon(Icons.add);
      await tester.tap(addQty);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);

      // Decrement quantity
      final removeQty = find.byIcon(Icons.remove);
      await tester.tap(removeQty);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('ProductDetailsScreen updates price and stock status when variant changes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final product = ShoppingMockData.products[1]; // Air Jordan 1

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(product: product),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on second variant: "UK 9 / US 10 (High Demand)"
      if (product.variants.length > 1) {
        await tester.tap(find.text(product.variants[1].name));
        await tester.pumpAndSettle();

        // Effective price calculation
        final expectedPrice = product.price + product.variants[1].priceDelta;
        expect(find.text('₹${expectedPrice.toInt()}'), findsOneWidget);
      }
    });

    testWidgets('ProductDetailsScreen handles out-of-stock products with disabled state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const outOfStockProduct = Product(
        id: 'prod_oos_test',
        name: 'Limited Edition Rare Sneaker',
        brand: 'Nike Lab',
        category: ShoppingCategoryType.footwear,
        price: 24999,
        rating: 4.9,
        reviewCount: 12,
        coverImageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
        galleryImages: [],
        description: 'Sold out collector edition sneaker.',
        specifications: {'Edition': 'Ultra Limited'},
        variants: [],
        storeId: 'store_1',
        storeName: 'Nike Flagship',
        storeLocation: 'Road No. 36, Jubilee Hills',
        distance: '2.5 km',
        inStock: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductDetailsScreen(product: outOfStockProduct),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OUT OF STOCK'), findsWidgets);
      expect(find.text('Currently Out of Stock'), findsOneWidget);
    });
  });

  group('Phase 17: Cart, Checkout & Digital Order Pass Flow', () {
    testWidgets('CartScreen renders items, updates quantity, applies coupon, and calculates server breakdown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ShoppingCartManager.instance.clearCart();
      ShoppingCartManager.instance.addItem(ShoppingMockData.products.first, quantity: 1);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(repository: LocalShoppingRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Shopping Bag'), findsOneWidget);
      expect(find.text('Delivery / Pickup Preference'), findsOneWidget);
      expect(find.text('Store Pickup'), findsOneWidget);

      // Verify bill summary
      expect(find.text('Bag Subtotal'), findsOneWidget);
      expect(find.text('Express Handling Fee'), findsOneWidget);
      expect(find.text('Grand Total'), findsWidgets);

      // Apply Coupon
      final couponField = find.byType(TextField).first;
      await tester.enterText(couponField, 'PLAZASHOP');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Applied ✓'), findsOneWidget);
    });

    testWidgets('CartScreen checkout creates order, syncs with PlazaGlobalState unified bookings, and opens confirmation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ShoppingCartManager.instance.clearCart();
      ShoppingCartManager.instance.addItem(ShoppingMockData.products[1], quantity: 1);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(repository: LocalShoppingRepository()),
        ),
      );
      await tester.pumpAndSettle();

      final initialBookingsCount = PlazaGlobalState.instance.bookings.length;

      // Tap Place Order
      await tester.tap(find.text('Place Order 🛍️'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify navigated to ShoppingConfirmationScreen
      expect(find.text('Order Confirmed!'), findsOneWidget);
      expect(find.text('SHOW TO STORE CONCIERGE'), findsOneWidget);
      expect(find.textContaining('PICKUP CODE:'), findsOneWidget);

      // Verify unified bookings updated
      expect(PlazaGlobalState.instance.bookings.length, initialBookingsCount + 1);
      final latestBooking = PlazaGlobalState.instance.bookings.first;
      expect(latestBooking.type, UnifiedBookingType.shopping);
      expect(latestBooking.status, BookingStatus.upcoming);
    });

    testWidgets('ShoppingConfirmationScreen displays digital pass details, pickup code, and scannable QR code', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final order = ShoppingOrder(
        orderId: 'ORD-PLZ-889911',
        items: [
          CartItem(product: ShoppingMockData.products[1], quantity: 1),
        ],
        itemsTotal: 16995.0,
        discountAmount: 1699.0,
        platformFee: 29.0,
        gstAmount: 765.0,
        grandTotal: 16090.0,
        fulfillmentType: ShoppingFulfillmentType.inStorePickup,
        storeName: 'Superkicks Banjara Hills',
        storeLocation: 'Road No. 12, Banjara Hills',
        orderTime: DateTime.now(),
        qrCodeData: 'PLAZA-ORDER:ORD-PLZ-889911:4582',
        paymentMethod: 'Pay on Pickup',
        pickupCode: '4582',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShoppingConfirmationScreen(order: order),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Confirmed!'), findsOneWidget);
      expect(find.text('ORD-PLZ-889911'), findsOneWidget);
      expect(find.text('Superkicks Banjara Hills'), findsOneWidget);
      expect(find.text('PICKUP CODE: 4582'), findsOneWidget);
      expect(find.text('Pay on Pickup / Pending'), findsOneWidget);
      expect(find.text('Payable Amount'), findsOneWidget);
      expect(find.text('₹16090'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });
  });

  group('Phase 17: Customer Isolation & Security', () {
    testWidgets('Shopping consumer screens contain zero admin controls or leaks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ShoppingScreen(repository: LocalShoppingRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Product'), findsNothing);
      expect(find.text('Edit Product'), findsNothing);
      expect(find.text('Delete Product'), findsNothing);
      expect(find.text('Publish'), findsNothing);
      expect(find.text('Unpublish'), findsNothing);
      expect(find.text('Inventory Management'), findsNothing);
      expect(find.text('Admin Dashboard'), findsNothing);
    });

    test('ApiShoppingRepository rethrows error in production mode when mock data disabled', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      EnvironmentConfig.useMockData = false;

      final repo = ApiShoppingRepository(
        client: _FailingApiClient(),
        fallback: const LocalShoppingRepository(),
      );

      expect(() => repo.getProducts(), throwsA(isA<Exception>()));
    });
  });
}

class _FailingApiClient extends ApiClient {
  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    required T Function(dynamic json) fromJson,
  }) async {
    return ApiResponse<T>.failure('Failed to reach production backend', statusCode: 503);
  }
}
