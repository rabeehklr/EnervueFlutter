import 'package:final_project_app/models/consumption_data.dart';

class Appliance {
  final String name;
  final String consumption;
  final String usageTime;
  final String imageAsset;
  final List<ConsumptionData> data;
  final bool isOn;
  final String avgPower;
  final String peakPower;
  final String onOffCycles;
  final bool anomaly; // Added this field
  final int anomaliesToday;
  final List<Map<String, dynamic>> weeklyAnomalies;

  Appliance({
    required this.name,
    required this.consumption,
    required this.usageTime,
    required this.imageAsset,
    required this.data,
    required this.isOn,
    required this.avgPower,
    required this.peakPower,
    required this.onOffCycles,
    required this.anomaly, // Added this field
    required this.anomaliesToday,
    required this.weeklyAnomalies,
  });
}