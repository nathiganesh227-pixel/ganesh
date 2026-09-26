import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/shopping_cart_manager.dart';
import '../../core/data/shopping_mock_data.dart';
import '../../core/models/shopping.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/shopping_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'cart_screen.dart';
import 'store_details_screen.dart';
import 'widgets/product_card.dart';

class ShoppingScreen extends StatefulWidget {
  final ShoppingRepository? repository;
  const ShoppingScreen({super.key, this.repository});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final ShoppingCartManager _cart = ShoppingCartManager.instance;
  late final ShoppingRepository _shoppingRepo;
  List<Product> _loadedProducts = ShoppingMockData.products;
  List<ShoppingStore> _loadedStores = ShoppingMockData.stores;
  ShoppingCategoryType? _selectedCategory;
  String _searchQuery = '';
  bool _favoritesOnly = false;
  bool _inStockOnly = false;
  bool _trendingOnly = false;

  @override
  void initState() {
    super.initState();
    _shoppingRepo = widget.repository ?? RepositoryProvider.instance.shoppingRepo;
    _cart.addListener(_onCartChanged);
    _searchController.addListener(_onSearchChanged);
    _fetchShoppingData();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  Future<void> _fetchShoppingData() async {
    try {
      final products = await _shoppingRepo.getProducts();
      final stores = await _shoppingRepo.getStores();
      if (mounted) {
        setState(() {
          if (products.isNotEmpty) _loadedProducts = products;
          if (stores.isNotEmpty) _loadedStores = stores;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cart.removeListener(_onCartChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _favoritesOnly = false;
      _inStockOnly = false;
      _trendingOnly = false;
    });
  }

  void _openCitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        const supportedCities = [
          'Hyderabad',
          'Bengaluru',
          'Mumbai',
          'Delhi NCR',
          'Chennai',
          'Pune',
        ];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: const BoxDecoration(
                color: Color(0xF0090D18),
                border: Border(
                  top: BorderSide(color: AppColors.glassBorder, width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Shopping City', style: AppTypography.headingMedium),
                      const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse flagship stores and local boutique inventories',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  ListenableBuilder(
                    listenable: PlazaGlobalState.instance,
                    builder: (context, _) {
                      final currentCity = PlazaGlobalState.instance.selectedCity;
                      return Column(
                        children: supportedCities.map((city) {
                          final isSelected = currentCity.toLowerCase() == city.toLowerCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: Icon(
                                  Icons.near_me_rounded,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                  size: 18,
                                ),
                                title: Text(
                                  city,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                    : null,
                                onTap: () {
                                  PlazaGlobalState.instance.setSelectedCity(city);
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Product> get _filteredProducts {
    final favIds = PlazaGlobalState.instance.favoriteIds;

    return _loadedProducts.where((p) {
      if (_favoritesOnly && !favIds.contains(p.id)) {
        return false;
      }
      if (_inStockOnly && !p.inStock) {
        return false;
      }
      if (_trendingOnly && !p.isTrending) {
        return false;
      }
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesName = p.name.toLowerCase().contains(_searchQuery);
        final matchesBrand = p.brand.toLowerCase().contains(_searchQuery);
        final matchesCategory = p.category.label.toLowerCase().contains(_searchQuery);
        final matchesStore = p.storeName.toLowerCase().contains(_searchQuery);
        final matchesDesc = p.description.toLowerCase().contains(_searchQuery);
        return matchesName || matchesBrand || matchesCategory || matchesStore || matchesDesc;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deals = _loadedProducts.where((p) => p.isDealOfTheDay).toList();
    final trending = _loadedProducts.where((p) => p.isTrending).toList();
    final stores = _loadedStores;
    final filtered = _filteredProducts;
    final isFiltering = _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _favoritesOnly ||
        _inStockOnly ||
        _trendingOnly;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Atmospheric Glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header Row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.glassFillMedium,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.glassBorderSubtle),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListenableBuilder(
                                  listenable: PlazaGlobalState.instance,
                                  builder: (context, _) {
                                    final city = PlazaGlobalState.instance.selectedCity.toUpperCase();
                                    return GestureDetector(
                                      onTap: () => _openCitySelector(context),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                                          const SizedBox(width: 3),
                                          Text(city, style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textMuted),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                Text('Shopping & Luxury', style: AppTypography.headingMedium),
                              ],
                            ),
                          ],
                        ),

                        // Cart Button with Live Badge
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const CartScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.glassFillMedium,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.glassBorderSubtle),
                                ),
                                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                            if (_cart.totalItemCount > 0)
                              Positioned(
                                top: 4,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${_cart.totalItemCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Glass Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassSearchBar(
                      hintText: 'Search brands, sneakers, tech, malls...',
                      controller: _searchController,
                      onFilterTap: () => _openCitySelector(context),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Quick Filter Chips (Favorites, In Stock, Trending)
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListenableBuilder(
                      listenable: PlazaGlobalState.instance,
                      builder: (context, _) {
                        final favCount = PlazaGlobalState.instance.favoriteIds.length;
                        return Row(
                          children: [
                            // Favorites quick chip
                            GestureDetector(
                              onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _favoritesOnly
                                      ? AppColors.alertRed.withValues(alpha: 0.25)
                                      : AppColors.glassFillMedium,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _favoritesOnly
                                        ? AppColors.alertRed.withValues(alpha: 0.6)
                                        : AppColors.glassBorderSubtle,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: _favoritesOnly ? AppColors.alertRed : AppColors.textMuted,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Favorites ($favCount)',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: _favoritesOnly ? Colors.white : AppColors.textSecondary,
                                        fontWeight: _favoritesOnly ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // In Stock quick chip
                            GestureDetector(
                              onTap: () => setState(() => _inStockOnly = !_inStockOnly),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _inStockOnly
                                      ? AppColors.liveGreen.withValues(alpha: 0.25)
                                      : AppColors.glassFillMedium,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _inStockOnly
                                        ? AppColors.liveGreen.withValues(alpha: 0.6)
                                        : AppColors.glassBorderSubtle,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: _inStockOnly ? AppColors.liveGreen : AppColors.textMuted,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'In Stock',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: _inStockOnly ? Colors.white : AppColors.textSecondary,
                                        fontWeight: _inStockOnly ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Trending quick chip
                            GestureDetector(
                              onTap: () => setState(() => _trendingOnly = !_trendingOnly),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _trendingOnly
                                      ? AppColors.accentAmber.withValues(alpha: 0.25)
                                      : AppColors.glassFillMedium,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _trendingOnly
                                        ? AppColors.accentAmber.withValues(alpha: 0.6)
                                        : AppColors.glassBorderSubtle,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      color: _trendingOnly ? AppColors.accentAmber : AppColors.textMuted,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Trending Deals',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: _trendingOnly ? Colors.white : AppColors.textSecondary,
                                        fontWeight: _trendingOnly ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // Categories Horizontal Filter Bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: ShoppingCategoryType.values.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isAllSelected = _selectedCategory == null;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = null),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isAllSelected ? AppColors.primary : AppColors.glassFillMedium,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isAllSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                                ),
                              ),
                              child: Text(
                                'All Items',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isAllSelected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        final cat = ShoppingCategoryType.values[index - 1];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat.emoji, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  cat.label.split('&').first.trim(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Unfiltered Carousels: Deals & Malls
                if (!isFiltering) ...[
                  // Today's Deals Section
                  if (deals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SectionHeader(
                          title: "Today's Flash Deals 🔥",
                          actionText: '${deals.length} deals',
                          onActionTap: () => setState(() => _trendingOnly = true),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 245,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: deals.length,
                          itemBuilder: (context, index) => ProductCard(
                            product: deals[index],
                            variant: ProductCardVariant.compact,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // Malls & Flagships Section
                  if (stores.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SectionHeader(
                          title: 'Premier Malls & Boutiques 🏬',
                          actionText: '${stores.length} venues',
                          onActionTap: () {},
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 190,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: stores.length,
                          itemBuilder: (context, index) => _buildStoreCard(stores[index]),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // Trending Header
                  if (trending.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SectionHeader(
                          title: 'Trending Near You ✨',
                          actionText: '${trending.length} items',
                          onActionTap: () => setState(() => _trendingOnly = true),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                ],

                // Filter Active Bar
                if (isFiltering)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${filtered.length} products',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: _resetFilters,
                            child: Text(
                              'Clear All',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Products Catalog Grid / Empty State
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.glassFillMedium,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.glassBorderSubtle),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found matching your search.',
                              style: AppTypography.headingSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search query, city, or filter selection.',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _resetFilters,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text('Reset All Filters', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: filtered[index],
                          variant: ProductCardVariant.standard,
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(ShoppingStore s) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StoreDetailsScreen(store: s)),
        );
      },
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 14),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlazaImage(
                imageUrl: s.coverImageUrl,
                height: 100,
                width: double.infinity,
                borderRadius: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: AppTypography.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.mallName} • ${s.distance}',
                      style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.offerTag,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.liveGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
