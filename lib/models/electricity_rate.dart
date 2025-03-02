class ElectricityRate {
  final double ratePerUnit; // Rate per Wh
  final String category;
  final int minUnits;
  final int maxUnits;

  ElectricityRate({
    required this.ratePerUnit,
    required this.category,
    required this.minUnits,
    required this.maxUnits,
  });
}