import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/plan.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/plaza_image.dart';
import 'build_my_day_wizard_screen.dart';
import 'generated_plan_screen.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  void _openPlan(BuildContext context, PlazaPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeneratedPlanScreen(initialPlan: plan),
      ),
    );
  }

  void _startWizard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BuildMyDayWizardScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final state = PlazaGlobalState.instance;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI CONCIERGE & ITINERARIES',
                              style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Build My Day', style: AppTypography.displayMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Multi-stop plans combining cinema, dining, karting & nightlife tailored to your budget.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Hero "Build My Day" Wizard Launch Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderColor: AppColors.primary.withValues(alpha: 0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.sunsetPrimary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Design a Custom Day', style: AppTypography.headingMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      '5 easy steps: People • Budget • Time • Zone • Mood',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GlassPill(label: '🏎️ Adventure', iconColor: AppColors.primary),
                              GlassPill(label: '🍜 Foodie', iconColor: AppColors.accentAmber),
                              GlassPill(label: '🍷 Date Night', iconColor: AppColors.secondaryViolet),
                              GlassPill(label: '🎉 Friends', iconColor: AppColors.accentGold),
                            ],
                          ),
                          const SizedBox(height: 18),
                          GlassButton(
                            text: 'Start Planning Wizard',
                            icon: Icons.play_arrow_rounded,
                            variant: GlassButtonVariant.primary,
                            onPressed: () => _startWizard(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Saved Plans Section
                  if (state.savedPlans.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Your Saved Plans',
                        subtitle: '${state.savedPlans.length} ready to experience',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: state.savedPlans.length,
                      itemBuilder: (context, index) {
                        final plan = state.savedPlans[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () => _openPlan(context, plan),
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          plan.mood.emoji,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(plan.title, style: AppTypography.headingSmall),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${plan.peopleCount} Guests • ${plan.items.length} Stops • ${plan.locationArea}',
                                              style: AppTypography.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.bookmark_remove_rounded, color: AppColors.textMuted, size: 20),
                                        onPressed: () {
                                          state.removeSavedPlan(plan.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Removed "${plan.title}" from saved plans.'),
                                              backgroundColor: AppColors.surfaceCard,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        '₹${plan.grandTotal.toInt()} Est. Total',
                                        style: AppTypography.labelLarge.copyWith(
                                          color: AppColors.accentGold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Open Itinerary',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Curated PLAZA Day Experiences
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: 'Curated Hyderabad Itineraries',
                      subtitle: 'Handcrafted by local tastemakers',
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildCuratedPlanCard(
                    context,
                    title: 'Cyberabad Nightlife & Fast Laps',
                    area: 'Financial District & Gachibowli',
                    emoji: '🏎️',
                    stops: 'Karting + Craft Cocktails + Late Night Diner',
                    price: '₹2,650 / person',
                    imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=800&auto=format&fit=crop',
                    onTap: () => _startWizard(context),
                  ),

                  _buildCuratedPlanCard(
                    context,
                    title: 'Royal Falaknuma Heritage & High Tea',
                    area: 'Old City & Falaknuma',
                    emoji: '👑',
                    stops: 'Perfume Walk + Palace Buggy + Nizami Feast',
                    price: '₹3,900 / person',
                    imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
                    onTap: () => _startWizard(context),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCuratedPlanCard(
    BuildContext context, {
    required String title,
    required String area,
    required String emoji,
    required String stops,
    required String price,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: PlazaImage(imageUrl: imageUrl, fit: BoxFit.cover),
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
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GlassPill(
                      label: area.toUpperCase(),
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.primary,
                      textColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.headingMedium.copyWith(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stops,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      price,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w700,
                      ),
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
