enum RewardType {
  hasanat,
  badge,
  trophy,
}

class RewardEvent {
  const RewardEvent({
    required this.type,
    required this.title,
    required this.message,
    this.score,
  });

  final RewardType type;
  final String title;
  final String message;
  final int? score;
}

class RewardScreenArgs {
  const RewardScreenArgs({
    required this.event,
    required this.primaryLabel,
    required this.primaryRoute,
    this.secondaryLabel,
    this.secondaryRoute,
  });

  final RewardEvent event;
  final String primaryLabel;
  final String primaryRoute;
  final String? secondaryLabel;
  final String? secondaryRoute;
}
