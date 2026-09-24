import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/plan.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import 'generated_plan_screen.dart';
import '../../core/models/unified_booking.dart';

class BuildMyDayWizardScreen extends StatefulWidget {
  const BuildMyDayWizardScreen({super.key});

  @override
  State<BuildMyDayWizardScreen> createState() => _BuildMyDayWizardScreenState();
}

class _BuildMyDayWizardScreenState extends State<BuildMyDayWizardScreen> {
  int _currentStep = 0;

  // Selected parameters
  int _peopleCount = 2;
  String _budgetLabel = 'Moderate';
  String _timeRange = 'Evening (5 PM - 11 PM)';
  String _locationArea = 'Jubilee Hills & Banjara Hills';
  PlanMood _selectedMood = PlanMood.friends;

  final List<String> _areas = [
    'Jubilee Hills & Banjara Hills',
    'Hitec City & Gachibowli',
    'Financial District & Kokapet',
    'Old City & Charminar',
    'Secunderabad & Begumpet',
  ];

  final List<Map<String, dynamic>> _budgetTiers = [
    {'label': 'Budget', 'range': '₹500 - ₹1,500', 'min': 500.0, 'max': 1500.0, 'icon': Icons.savings_outlined},
    {'label': 'Moderate', 'range': '₹1,500 - ₹3,000', 'min': 1500.0, 'max': 3000.0, 'icon': Icons.currency_rupee_rounded},
    {'label': 'Premium', 'range': '₹3,000 - ₹6,000', 'min': 3000.0, 'max': 6000.0, 'icon': Icons.diamond_outlined},
    {'label': 'Luxury', 'range': '₹6,000+', 'min': 6000.0, 'max': 15000.0, 'icon': Icons.auto_awesome_rounded},
  ];

  final List<Map<String, String>> _timeWindows = [
    {'title': 'Morning to Afternoon', 'desc': '9:00 AM - 2:00 PM • Breakfast & Activity'},
    {'title': 'Afternoon to Evening', 'desc': '1:00 PM - 7:00 PM • Lunch & Entertainment'},
    {'title': 'Evening to Night', 'desc': '5:00 PM - 11:30 PM • Dinner, Cinema & Lounge'},
    {'title': 'Full Day Grand Tour', 'desc': '10:00 AM - 11:00 PM • All-Day 4-Part Sequence'},
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _generateAndNavigate();
    }
  }

  void _generateAndNavigate() {
    // Construct cohesive tailored plan
    final planId = 'pln_${DateTime.now().millisecondsSinceEpoch}';
    final generatedPlan = _buildTailoredPlan(planId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeneratedPlanScreen(initialPlan: generatedPlan),
      ),
    );
  }

  PlazaPlan _buildTailoredPlan(String planId) {
    final now = DateTime.now();

    List<PlanItem> items = [];
    String title = '${_selectedMood.label} Day in $_locationArea';
    String subtitle = '$_peopleCount Guests • $_budgetLabel Budget • $_timeRange';

    if (_selectedMood == PlanMood.adventure || _selectedMood == PlanMood.friends) {
      items = [
        const PlanItem(
          id: 'item_gen_1',
          vertical: UnifiedBookingType.activity,
          title: 'High-Speed Go-Karting Championship',
          venue: 'Runway 9 Circuit',
          area: 'Outer Ring Road, Kompally',
          time: '4:00 PM',
          duration: '75 mins',
          costPerPerson: 750,
          imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=800&auto=format&fit=crop',
          note: 'Pro track session with split timing transponders',
          slot: PlanTimeSlot.afternoon,
        ),
        const PlanItem(
          id: 'item_gen_2',
          vertical: UnifiedBookingType.dining,
          title: 'Modern Indian Dinner & Molecular Drinks',
          venue: 'Farzi Café Jubilee Hills',
          area: 'Road No. 36, Jubilee Hills',
          time: '7:00 PM',
          duration: '105 mins',
          costPerPerson: 1100,
          imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
          note: 'Outdoor deck seating reserved • 25% off club deal',
          slot: PlanTimeSlot.evening,
        ),
        const PlanItem(
          id: 'item_gen_3',
          vertical: UnifiedBookingType.movie,
          title: 'Dune: Part Two (IMAX 3D Laser)',
          venue: 'AMB Cinemas, Screen 1',
          area: 'Sarath City Capital Mall, Kondapur',
          time: '9:45 PM',
          duration: '166 mins',
          costPerPerson: 450,
          imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop',
          note: 'Central Platinum Recliners with Dolby Atmos',
          slot: PlanTimeSlot.night,
        ),
      ];
    } else if (_selectedMood == PlanMood.dateNight || _selectedMood == PlanMood.luxury) {
      title = 'Romantic Candlelight & Skyline Night';
      items = [
        const PlanItem(
          id: 'item_gen_1',
          vertical: UnifiedBookingType.dining,
          title: 'Mediterranean Sundowner & Tapas',
          venue: 'Olive Bistro & Bar',
          area: 'Road No. 46, Jubilee Hills',
          time: '6:00 PM',
          duration: '90 mins',
          costPerPerson: 1600,
          imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800&auto=format&fit=crop',
          note: 'Lake-view terrace table with craft sangrias',
          slot: PlanTimeSlot.evening,
        ),
        const PlanItem(
          id: 'item_gen_2',
          vertical: UnifiedBookingType.movie,
          title: 'Kalki 2898 AD (IMAX Experience)',
          venue: 'Prasads Large Screen IMAX',
          area: 'Necklace Road, Hyderabad',
          time: '8:45 PM',
          duration: '180 mins',
          costPerPerson: 500,
          imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop',
          note: 'VIP Couches with in-seat artisan confectionery',
          slot: PlanTimeSlot.night,
        ),
      ];
    } else {
      // Foodie / Chill / Explore
      items = [
        const PlanItem(
          id: 'item_gen_1',
          vertical: UnifiedBookingType.activity,
          title: 'Historic Charminar & Fragrance Trail',
          venue: 'Old City Cultural Hub',
          area: 'Old City, Hyderabad',
          time: '11:00 AM',
          duration: '120 mins',
          costPerPerson: 400,
          imageUrl: 'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?q=80&w=800&auto=format&fit=crop',
          note: 'Artisanal attar tasting & heritage bazaar walk',
          slot: PlanTimeSlot.morning,
        ),
        const PlanItem(
          id: 'item_gen_2',
          vertical: UnifiedBookingType.dining,
          title: 'Royal Nizami High Tea & Biryani',
          venue: 'Adaa at Taj Falaknuma',
          area: 'Falaknuma, Hyderabad',
          time: '3:30 PM',
          duration: '150 mins',
          costPerPerson: 2200,
          imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
          note: 'Palace buggy arrival with heritage tour',
          slot: PlanTimeSlot.afternoon,
        ),
      ];
    }

    return PlazaPlan(
      id: planId,
      title: title,
      subtitle: subtitle,
      mood: _selectedMood,
      peopleCount: _peopleCount,
      locationArea: _locationArea,
      date: now.add(const Duration(days: 1)),
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BUILD MY DAY', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                        Text('Step ${_currentStep + 1} of 5', style: AppTypography.headingMedium),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppGradients.sunsetPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AI PLANNER',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(5, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Continue Action
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
                      tooltip: 'Reset',
                      onPressed: () => setState(() => _currentStep = 0),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: GlassButton(
                      text: _currentStep == 4 ? 'Generate Day Itinerary ✨' : 'Continue',
                      variant: GlassButtonVariant.primary,
                      onPressed: _nextStep,
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

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPeopleStep();
      case 1:
        return _buildBudgetStep();
      case 2:
        return _buildTimeStep();
      case 3:
        return _buildLocationStep();
      case 4:
        return _buildMoodStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: PEOPLE
  Widget _buildPeopleStep() {
    final partySizes = [
      {'count': 1, 'label': 'Solo Explorer', 'desc': 'Me, myself & peaceful unwinding', 'icon': Icons.person_rounded},
      {'count': 2, 'label': 'Couple / Duo', 'desc': 'Date night, besties, or dinner for 2', 'icon': Icons.people_alt_rounded},
      {'count': 4, 'label': 'Squad (3-5)', 'desc': 'Close friend circle & group fun', 'icon': Icons.groups_rounded},
      {'count': 8, 'label': 'Party Gang (6+)', 'desc': 'Large celebration or team outing', 'icon': Icons.celebration_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is joining today?', style: AppTypography.headingLarge),
        const SizedBox(height: 6),
        Text(
          'We will tailor venue seating, group slots and squad ticket bundles.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 20),
        ...partySizes.map((p) {
          final isSelected = _peopleCount == p['count'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _peopleCount = p['count'] as int),
              child: GlassCard(
                borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        p['icon'] as IconData,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['label'] as String, style: AppTypography.headingSmall),
                          const SizedBox(height: 2),
                          Text(p['desc'] as String, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 2: BUDGET
  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What’s the budget target?', style: AppTypography.headingLarge),
        const SizedBox(height: 6),
        Text('Per person spend across all venues and passes.', style: AppTypography.bodySmall),
        const SizedBox(height: 20),
        ..._budgetTiers.map((b) {
          final isSelected = _budgetLabel == b['label'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                _budgetLabel = b['label'] as String;
              }),
              child: GlassCard(
                borderColor: isSelected ? AppColors.accentGold : AppColors.glassBorder,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentGold.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        b['icon'] as IconData,
                        color: isSelected ? AppColors.accentGold : AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['label'] as String, style: AppTypography.headingSmall),
                          const SizedBox(height: 2),
                          Text(b['range'] as String, style: AppTypography.bodySmall.copyWith(color: AppColors.accentGold)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.accentGold, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 3: TIME
  Widget _buildTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When are you heading out?', style: AppTypography.headingLarge),
        const SizedBox(height: 6),
        Text('Choose the time window for your itinerary.', style: AppTypography.bodySmall),
        const SizedBox(height: 20),
        ..._timeWindows.map((tw) {
          final isSelected = _timeRange == tw['title'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _timeRange = tw['title']!),
              child: GlassCard(
                borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.primaryLight, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tw['title']!, style: AppTypography.headingSmall),
                          const SizedBox(height: 2),
                          Text(tw['desc']!, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 4: LOCATION
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferred Zone in Hyderabad', style: AppTypography.headingLarge),
        const SizedBox(height: 6),
        Text('Venues will be kept within comfortable 15-minute transit distance.', style: AppTypography.bodySmall),
        const SizedBox(height: 20),
        ..._areas.map((area) {
          final isSelected = _locationArea == area;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _locationArea = area),
              child: GlassCard(
                borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primaryLight, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(area, style: AppTypography.headingSmall),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 5: MOOD
  Widget _buildMoodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick your vibe for the day', style: AppTypography.headingLarge),
        const SizedBox(height: 6),
        Text('Our engine picks venues that match this aesthetic.', style: AppTypography.bodySmall),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: PlanMood.values.length,
          itemBuilder: (context, index) {
            final mood = PlanMood.values[index];
            final isSelected = _selectedMood == mood;

            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: GlassCard(
                borderColor: isSelected ? AppColors.primary : AppColors.glassBorder,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      mood.label,
                      style: AppTypography.headingSmall.copyWith(
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mood.description,
                      style: AppTypography.bodySmall.copyWith(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
