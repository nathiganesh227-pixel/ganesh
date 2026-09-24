import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/shopping_cart_manager.dart';
import '../../core/data/shopping_mock_data.dart';
import '../../core/models/shopping.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/shopping_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import 'store_details_screen.dart';

class ShoppingScreen extends StatefulWidget {
  final ShoppingRepository? repository;
  const ShoppingScreen({super.key, this.repository});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ShoppingCartManager _cart = ShoppingCartManager.instance;
  late final ShoppingRepository _shoppingRepo;
  List<Product> _loadedProducts = ShoppingMockData.products;
  List<ShoppingStore> _loadedStores = ShoppingMockData.stores;
  ShoppingCategoryType? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _shoppingRepo = widget.repository ?? RepositoryProvider.instance.shoppingRepo;
    _cart.addListener(_onCartChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _fetchShoppingData();
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
    _cart.removeListener(_onCartChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  List<Product> get _filteredProducts {
    return _loadedProducts.where((p) {
      if (_selectedCategory != null && p.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesName = p.name.toLowerCase().contains(_searchQuery);
        final matchesBrand = p.brand.toLowerCase().contains(_searchQuery);
        final matchesCategory = p.category.label.toLowerCase().contains(_searchQuery);
        final matchesStore = p.storeName.toLowerCase().contains(_searchQuery);
        return matchesName || matchesBrand || matchesCategory || matchesStore;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deals = _loadedProducts.where((p) => p.isDealOfTheDay).toList();
    final trending = _loadedProducts.where((p) => p.isTrending).toList();
    final stores = _loadedStores;

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
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text('HYDERABAD', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                                  ],
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
                      onFilterTap: () {},
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

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

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                  // Today's Deals Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: "Today's Flash Deals 🔥",
                        actionText: 'See All',
                        onActionTap: () {},
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
                        itemBuilder: (context, index) => _buildDealProductCard(deals[index]),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Malls & Flagships Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Premier Malls & Boutiques 🏬',
                        actionText: 'View All',
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

                  // Trending Near You Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Trending Near You ✨',
                        actionText: '${trending.length} items',
                        onActionTap: () {},
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                // Filtered Products Catalog
                if (_filteredProducts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No products found matching your search.'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductGridCard(_filteredProducts[index]),
                        childCount: _filteredProducts.length,
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

  Widget _buildDealProductCard(Product p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: p)),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PlazaImage(
                    imageUrl: p.coverImageUrl,
                    height: 130,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                  if (p.discountBadge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppGradients.sunsetPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.discountBadge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.name,
                      style: AppTypography.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₹${p.price.toInt()}',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.originalPrice != null)
                          Text(
                            '₹${p.originalPrice!.toInt()}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.storeName,
                      style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
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

  Widget _buildStoreCard(ShoppingStore s) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StoreDetailsScreen(store: s)),
        );
      },
      child: Container(
        width: 220,
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

  Widget _buildProductGridCard(Product p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: p)),
        );
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  PlazaImage(
                    imageUrl: p.coverImageUrl,
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GlassPill(
                      label: '${p.rating.toStringAsFixed(1)} ★',
                      textColor: AppColors.accentGold,
                      backgroundColor: const Color(0x95000000),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                  ),
                  if (p.discountBadge != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppGradients.sunsetPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.discountBadge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.brand.toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.name,
                    style: AppTypography.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '₹${p.price.toInt()}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.accentAmber,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.distance,
                        style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
