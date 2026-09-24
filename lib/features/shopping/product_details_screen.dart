import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/shopping_cart_manager.dart';
import '../../core/data/shopping_mock_data.dart';
import '../../core/models/shopping.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'cart_screen.dart';
import 'store_details_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedImageIndex = 0;
  ProductVariant? _selectedVariant;
  final ShoppingCartManager _cart = ShoppingCartManager.instance;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _addToCart({bool navigateToCart = false}) {
    _cart.addItem(widget.product, variant: _selectedVariant, quantity: 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${widget.product.name} to your bag 🛍️'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Bag',
          textColor: AppColors.primary,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
          },
        ),
      ),
    );

    if (navigateToCart) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrice = widget.product.price + (_selectedVariant?.priceDelta ?? 0);
    final allImages = widget.product.galleryImages.isNotEmpty
        ? widget.product.galleryImages
        : [widget.product.coverImageUrl];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Image App Bar
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x95000000),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Stack(
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
                              color: const Color(0x95000000),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.glassBorderSubtle),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                          ),
                        ),
                        if (_cart.totalItemCount > 0)
                          Positioned(
                            top: 6,
                            right: 4,
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
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlazaImage(
                        imageUrl: allImages[_selectedImageIndex % allImages.length],
                        fit: BoxFit.cover,
                      ),
                      // Top gradient for app bar icons
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xBB070A11),
                              Colors.transparent,
                              Color(0xDD070A11),
                              AppColors.background,
                            ],
                            stops: [0.0, 0.4, 0.85, 1.0],
                          ),
                        ),
                      ),
                      // Image Thumbnail Selector Indicator
                      if (allImages.length > 1)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: allImages.asMap().entries.map((entry) {
                              final idx = entry.key;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedImageIndex = idx),
                                child: Container(
                                  width: _selectedImageIndex == idx ? 22 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _selectedImageIndex == idx ? AppColors.primary : Colors.white38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand & Discount Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.product.brand.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryLight,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.product.discountBadge != null)
                            GlassPill(
                              label: widget.product.discountBadge!,
                              backgroundColor: AppColors.accentAmber.withValues(alpha: 0.2),
                              textColor: AppColors.accentAmber,
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text(widget.product.name, style: AppTypography.headingLarge),

                      const SizedBox(height: 8),

                      // Rating & Reviews Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                                const SizedBox(width: 4),
                                Text(
                                  widget.product.rating.toStringAsFixed(1),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${widget.product.reviewCount} verified reviews)',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Price Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${effectivePrice.toInt()}',
                            style: AppTypography.headingLarge.copyWith(
                              color: AppColors.accentAmber,
                              fontSize: 26,
                            ),
                          ),
                          if (widget.product.originalPrice != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              '₹${widget.product.originalPrice!.toInt()}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '(${widget.product.discountPercent.toInt()}% OFF)',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.liveGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Variants Selector
                      if (widget.product.variants.isNotEmpty) ...[
                        Text('Select Option / Variant', style: AppTypography.labelLarge),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.product.variants.map((v) {
                            final isSelected = _selectedVariant?.id == v.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedVariant = v),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.25)
                                      : AppColors.glassFillMedium,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  v.name,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      Text('About Product', style: AppTypography.labelLarge),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      // Specifications Table
                      Text('Product Specifications', style: AppTypography.labelLarge),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: widget.product.specifications.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.key,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.value,
                                      style: AppTypography.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Store Availability & Express Pickup Card
                      Text('Store Availability & Pickup', style: AppTypography.labelLarge),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          final matchingStore = ShoppingMockData.stores.firstWhere(
                            (s) => s.id == widget.product.storeId,
                            orElse: () => ShoppingMockData.stores.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoreDetailsScreen(store: matchingStore),
                            ),
                          );
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: AppColors.primaryLight, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.product.storeName, style: AppTypography.labelMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${widget.product.storeLocation} • ${widget.product.distance}',
                                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'In Stock for Same-Day Express Pickup',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.liveGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Floating CTA Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: 'Add to Bag 🛍️',
                      variant: GlassButtonVariant.secondary,
                      onPressed: () => _addToCart(navigateToCart: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      text: 'Buy Now',
                      variant: GlassButtonVariant.primary,
                      onPressed: () => _addToCart(navigateToCart: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
