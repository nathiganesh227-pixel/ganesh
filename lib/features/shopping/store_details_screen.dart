import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/shopping_mock_data.dart';
import '../../core/models/shopping.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'product_details_screen.dart';

class StoreDetailsScreen extends StatelessWidget {
  final ShoppingStore store;

  const StoreDetailsScreen({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final storeProducts = ShoppingMockData.products.where((p) => p.storeId == store.id).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Cover App Bar
          SliverAppBar(
            expandedHeight: 280,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PlazaImage(
                    imageUrl: store.coverImageUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xBB070A11),
                          Colors.transparent,
                          Color(0xEE070A11),
                          AppColors.background,
                        ],
                        stops: [0.0, 0.4, 0.85, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassPill(
                          label: store.mallName,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(store.name, style: AppTypography.headingLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Store Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Badges
                  Row(
                    children: [
                      GlassPill(
                        label: '${store.rating.toStringAsFixed(1)} ★',
                        textColor: AppColors.accentGold,
                      ),
                      const SizedBox(width: 8),
                      GlassPill(
                        label: store.distance,
                        textColor: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassPill(
                          label: store.floorLocation,
                          textColor: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Store Info Card
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.access_time_rounded, 'Hours', store.openingHours),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.location_on_outlined, 'Location', store.location),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.local_offer_outlined, 'Active Offer', store.offerTag, highlight: true),
                        const SizedBox(height: 10),
                        _buildInfoRow(Icons.phone_outlined, 'Concierge', store.contactNumber),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Available Products from this Store
                  Text('In-Store Collection', style: AppTypography.headingMedium),
                  const SizedBox(height: 12),
                  if (storeProducts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Visit store in person to explore 1,000+ exclusive collections.',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...storeProducts.map((prod) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsScreen(product: prod),
                                ),
                              );
                            },
                            child: GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  PlazaImage(
                                    imageUrl: prod.coverImageUrl,
                                    width: 70,
                                    height: 70,
                                    borderRadius: 14,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.name,
                                          style: AppTypography.labelMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          prod.brand,
                                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${prod.price.toInt()}',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.accentAmber,
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
                        )),

                  const SizedBox(height: 24),

                  // Action Buttons
                  GlassButton(
                    text: 'Get Store Directions 📍',
                    variant: GlassButtonVariant.primary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening maps to ${store.name}...'),
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: highlight ? AppColors.accentAmber : AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: highlight ? AppColors.accentAmber : Colors.white,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
