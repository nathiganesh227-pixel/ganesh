import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/plaza_global_state.dart';
import '../../../core/models/shopping.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_pill.dart';
import '../../../core/widgets/plaza_image.dart';
import '../product_details_screen.dart';

enum ProductCardVariant {
  standard,
  horizontal,
  compact,
}

class ProductCard extends StatelessWidget {
  final Product product;
  final ProductCardVariant variant;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.variant = ProductCardVariant.standard,
    this.onTap,
  });

  void _navigateToDetails(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ProductCardVariant.compact:
        return _buildCompactCard(context);
      case ProductCardVariant.horizontal:
        return _buildHorizontalCard(context);
      case ProductCardVariant.standard:
        return _buildStandardCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(product.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 18.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Container
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: AspectRatio(
                        aspectRatio: 1.15,
                        child: PlazaImage(
                          imageUrl: product.coverImageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Top Gradient Scrim
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Category / Deal Badge Top Left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: GlassPill(
                        label: product.discountBadge ?? product.brand,
                        backgroundColor: (product.discountBadge != null
                                ? AppColors.accentAmber
                                : AppColors.primary)
                            .withValues(alpha: 0.35),
                        textColor: product.discountBadge != null
                            ? AppColors.accentAmber
                            : Colors.white,
                      ),
                    ),

                    // Favorite Button Top Right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => PlazaGlobalState.instance.toggleFavorite(product.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFav
                                  ? AppColors.alertRed.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.alertRed : Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ),

                    // Stock or Rating Pill Bottom Left
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.accentGold),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // In Stock / Out of Stock Indicator Bottom Right
                    Positioned(
                      bottom: 8,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (product.inStock ? AppColors.liveGreen : AppColors.alertRed)
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (product.inStock ? AppColors.liveGreen : AppColors.alertRed)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          product.inStock ? 'IN STOCK' : 'OUT OF STOCK',
                          style: TextStyle(
                            color: product.inStock ? AppColors.liveGreen : AppColors.alertRed,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Info Section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      Text(
                        product.brand.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                          letterSpacing: 1.2,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Title
                      Text(
                        product.name,
                        style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${product.price.toInt()}',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.originalPrice != null) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '₹${product.originalPrice!.toInt()}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Store & Distance
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${product.storeName} • ${product.distance}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
      },
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(product.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: Container(
            width: 220,
            margin: const EdgeInsets.only(right: 14),
            child: GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: PlazaImage(
                            imageUrl: product.coverImageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (product.discountBadge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GlassPill(
                            label: product.discountBadge!,
                            backgroundColor: AppColors.accentAmber.withValues(alpha: 0.35),
                            textColor: AppColors.accentAmber,
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => PlazaGlobalState.instance.toggleFavorite(product.id),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFav
                                    ? AppColors.alertRed.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppColors.alertRed : Colors.white,
                              size: 13,
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
                          product.brand.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₹${product.price.toInt()}',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '₹${product.originalPrice!.toInt()}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(product.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(10),
              borderRadius: 16.0,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: PlazaImage(
                        imageUrl: product.coverImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.brand.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryLight,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => PlazaGlobalState.instance.toggleFavorite(product.id),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? AppColors.alertRed : Colors.white60,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.accentGold),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: AppTypography.labelSmall.copyWith(fontSize: 10),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                product.storeName,
                                style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₹${product.price.toInt()}',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product.originalPrice != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '₹${product.originalPrice!.toInt()}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (product.inStock ? AppColors.liveGreen : AppColors.alertRed)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.inStock ? 'IN STOCK' : 'SOLD OUT',
                                style: TextStyle(
                                  color: product.inStock ? AppColors.liveGreen : AppColors.alertRed,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
