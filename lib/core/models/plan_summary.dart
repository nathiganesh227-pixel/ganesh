class ItineraryStep {
  final String timeSlot;
  final String title;
  final String category;
  final String venue;
  final String costEst;
  final String iconName;

  const ItineraryStep({
    required this.timeSlot,
    required this.title,
    required this.category,
    required this.venue,
    required this.costEst,
    required this.iconName,
  });
}

class DayPlan {
  final int peopleCount;
  final double budget;
  final int durationHours;
  final String vibe;
  final List<ItineraryStep> steps;

  const DayPlan({
    required this.peopleCount,
    required this.budget,
    required this.durationHours,
    required this.vibe,
    required this.steps,
  });
}
