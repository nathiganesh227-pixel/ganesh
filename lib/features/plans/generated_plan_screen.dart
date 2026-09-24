import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/plan.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'plan_confirmation_modal.dart';

class GeneratedPlanScreen extends StatefulWidget {
  final PlazaPlan initialPlan;

  const GeneratedPlanScreen({
    super.key,
    required this.initialPlan,
  });

  @override
  State<GeneratedPlanScreen> createState() => _GeneratedPlanScreenState();
}

class _GeneratedPlanScreenState extends State<GeneratedPlanScreen> {
  late PlazaPlan _plan;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.initialPlan;
  }

  void _savePlan() {
    setState(() => _isSaved = !_isSaved);
    if (_isSaved) {
      PlazaGlobalState.instance.savePlan(_plan);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan "${_plan.title}" saved to your plans!'),
          backgroundColor: AppColors.surfaceCard,
        ),
      );
    } else {
      PlazaGlobalState.instance.removeSavedPlan(_plan.id);
    }
  }

  void _removeItem(int index) {
    if (_plan.items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A day plan requires at least one experience.'),
          backgroundColor: AppColors.surfaceCard,
        ),
      );
      return;
    }

    setState(() {
      final updated = List<PlanItem>.from(_plan.items)..removeAt(index);
      _plan = _plan.copyWith(items: updated);
    });
  }

  void _showSwapSheet(int index) {
    final item = _plan.items[index];

    final swapOptions = [
      PlanItem(
        id: 'swap_1',
        vertical: item.vertical,
        title: 'Boutique Bowling & Craft Brews',
        venue: 'Smaaash Arena, Inorbit Mall',
        area: 'Hitec City, Hyderabad',
        time: item.time,
        duration: '90 mins',
        costPerPerson: 650,
        imageUrl: 'https://images.unsplash.com/photo-1545235617-9465d2a55698?q=80&w=800&auto=format&fit=crop',
        note: 'UV glow bowling alleys with artisanal sliders',
        slot: item.slot,
      ),
      PlanItem(
        id: 'swap_2',
        vertical: item.vertical,
        title: 'Artisanal Italian Dinner',
        venue: 'Tre-Forni at Park Hyatt',
        area: 'Road No. 2, Banjara Hills',
        time: item.time,
        duration: '110 mins',
        costPerPerson: 1800,
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800&auto=format&fit=crop',
        note: 'Wood-fired oven pizzas & handmade pastas',
        slot: item.slot,
      ),
      PlanItem(
        id: 'swap_3',
        vertical: item.vertical,
        title: 'Prasads Large Screen Blockbuster',
        venue: 'Prasads Multiplex Screen 6',
        area: 'Necklace Road, Hyderabad',
        time: item.time,
        duration: '150 mins',
        costPerPerson: 350,
        imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop',
        note: 'Largest curved projection in Hyderabad',
        slot: item.slot,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Swap Experience', style: AppTypography.headingLarge),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Select an alternative for ${item.time}', style: AppTypography.bodySmall),
            const SizedBox(height: 16),
            ...swapOptions.map((opt) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    setState(() {
                      final updated = List<PlanItem>.from(_plan.items);
                      updated[index] = opt;
                      _plan = _plan.copyWith(items: updated);
                    });
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: PlazaImage(imageUrl: opt.imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(opt.title, style: AppTypography.headingSmall.copyWith(fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('${opt.venue} • ₹${opt.costPerPerson.toInt()}/person',
                                  style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _bookEntirePlan() {
    final planBookingId = PlazaGlobalState.instance.bookEntirePlan(_plan);

    PlanConfirmationModal.show(
      context,
      plan: _plan,
      planBookingId: planBookingId,
      onViewInWallet: () {
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI CURATED ITINERARY', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                        Text(_plan.title, style: AppTypography.headingMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _isSaved ? AppColors.accentGold : Colors.white,
                    ),
                    onPressed: _savePlan,
                    tooltip: 'Save Plan',
                  ),
                ],
              ),
            ),

            // Plan Highlights Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('MOOD', '${_plan.mood.emoji} ${_plan.mood.label}'),
                    Container(width: 1, height: 28, color: AppColors.glassBorder),
                    _buildStat('GUESTS', '${_plan.peopleCount} People'),
                    Container(width: 1, height: 28, color: AppColors.glassBorder),
                    _buildStat('STOPS', '${_plan.items.length} Venues'),
                    Container(width: 1, height: 28, color: AppColors.glassBorder),
                    _buildStat('EST. TOTAL', '₹${_plan.grandTotal.toInt()}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Itinerary Items List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _plan.items.length,
                itemBuilder: (context, index) {
                  final item = _plan.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top item image + tags
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                child: SizedBox(
                                  height: 110,
                                  width: double.infinity,
                                  child: PlazaImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.3),
                                        AppColors.background.withValues(alpha: 0.85),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 12,
                                right: 12,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GlassPill(
                                      label: '${item.slot.label.toUpperCase()} • ${item.time}',
                                      icon: Icons.access_time_rounded,
                                      iconColor: AppColors.accentGold,
                                      textColor: Colors.white,
                                    ),
                                    GlassPill(
                                      label: item.vertical.displayName.toUpperCase(),
                                      iconColor: AppColors.primary,
                                      textColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 14,
                                right: 14,
                                child: Text(
                                  item.title,
                                  style: AppTypography.headingMedium.copyWith(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          // Item Details
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${item.venue} (${item.area})',
                                        style: AppTypography.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '₹${item.costPerPerson.toInt()} / person',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.accentGold,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.note,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Actions: Swap & Remove
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.primaryLight),
                                      label: Text(
                                        'Swap',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                                      ),
                                      onPressed: () => _showSwapSheet(index),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.alertRed),
                                      label: Text(
                                        'Remove',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.alertRed),
                                      ),
                                      onPressed: () => _removeItem(index),
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
              ),
            ),

            // Bottom Floating Booking Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL FOR ${_plan.peopleCount} GUESTS',
                        style: AppTypography.labelSmall.copyWith(fontSize: 9),
                      ),
                      Text(
                        '₹${_plan.grandTotal.toInt()}',
                        style: AppTypography.priceTag.copyWith(fontSize: 22, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GlassButton(
                      text: 'Book Entire Plan',
                      icon: Icons.auto_awesome_rounded,
                      variant: GlassButtonVariant.primary,
                      onPressed: _bookEntirePlan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(fontSize: 8, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
