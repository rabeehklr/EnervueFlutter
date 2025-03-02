class CostEstimate {
  final String applianceName;
  final double consumption; // in Wh
  double rate; // Changed from final to allow modification
  double totalCost; // Changed from final to allow modification
  final DateTime generatedAt;
  final String duration;

  CostEstimate({
    required this.applianceName,
    required this.consumption,
    required this.rate,
    required this.totalCost,
    required this.generatedAt,
    required this.duration,
  });
}