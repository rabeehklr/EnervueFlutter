import 'package:flutter/material.dart';
import '../models/appliance.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class AnomalyDetailScreen extends StatelessWidget {
  final Appliance appliance;

  const AnomalyDetailScreen({required this.appliance});

  @override
  Widget build(BuildContext context) {
    // Sample data for the week - replace with actual data
    final weeklyAnomalies = [
      {'day': 'Mon', 'count': 2},
      {'day': 'Tue', 'count': 1},
      {'day': 'Wed', 'count': 3},
      {'day': 'Thu', 'count': 0},
      {'day': 'Fri', 'count': 2},
      {'day': 'Sat', 'count': 1},
      {'day': 'Sun', 'count': 2},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.withOpacity(0.5),
        title: Text(
          '${appliance.name} Anomalies',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Stats Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Today's Anomaly Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Detections Today',
                          '3',
                          Icons.warning_amber_rounded,
                          Colors.orange,
                        ),
                        _buildStatColumn(
                          'Current Status',
                          appliance.anomaly ? 'Active' : 'Normal',
                          appliance.anomaly
                              ? Icons.error_outline
                              : Icons.check_circle,
                          appliance.anomaly ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Weekly Anomalies Graph
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Anomaly Detections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: charts.BarChart(
                        [
                          charts.Series<Map<String, dynamic>, String>(
                            id: 'Anomalies',
                            colorFn: (_, __) =>
                            charts.MaterialPalette.red.shadeDefault,
                            domainFn: (Map<String, dynamic> data, _) =>
                            data['day'] as String,
                            measureFn: (Map<String, dynamic> data, _) =>
                            data['count'] as int,
                            data: weeklyAnomalies,
                          ),
                        ],
                        animate: true,
                        domainAxis: charts.OrdinalAxisSpec(
                          renderSpec: charts.SmallTickRendererSpec(
                            labelStyle: charts.TextStyleSpec(
                              fontSize: 12,
                              color: charts.MaterialPalette.gray.shade600,
                            ),
                          ),
                        ),
                        primaryMeasureAxis: charts.NumericAxisSpec(
                          tickProviderSpec:
                          charts.BasicNumericTickProviderSpec(zeroBound: true),
                          renderSpec: charts.GridlineRendererSpec(
                            labelStyle: charts.TextStyleSpec(
                              fontSize: 12,
                              color: charts.MaterialPalette.gray.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}