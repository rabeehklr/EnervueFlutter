import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../models/appliance.dart';
import '../models/consumption_data.dart';

class ConsumptionGraph extends StatelessWidget {
  final Appliance appliance;

  const ConsumptionGraph({required this.appliance});

  @override
  Widget build(BuildContext context) {
    List<charts.Series<ConsumptionData, num>> series = [
      charts.Series<ConsumptionData, num>(
        id: 'Consumption',
        domainFn: (ConsumptionData data, int? index) => index ?? 0,
        measureFn: (ConsumptionData data, _) => data.usage,
        data: appliance.data,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        areaColorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault.lighter,
      )
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Power Consumption',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: charts.LineChart(
                series,
                animate: true,
                defaultRenderer: charts.LineRendererConfig(
                  includeArea: true,
                  stacked: false,
                  includePoints: true,
                  radiusPx: 4.0,
                  strokeWidthPx: 2.0,
                  areaOpacity: 0.2,
                ),
                primaryMeasureAxis: charts.NumericAxisSpec(
                  tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                    desiredTickCount: 5,
                  ),
                  renderSpec: charts.GridlineRendererSpec(
                    labelStyle: charts.TextStyleSpec(
                      fontSize: 12,
                      color: charts.MaterialPalette.gray.shade600,
                    ),
                    lineStyle: charts.LineStyleSpec(
                      color: charts.MaterialPalette.gray.shade300,
                    ),
                  ),
                ),
                domainAxis: charts.NumericAxisSpec(
                  tickFormatterSpec: charts.BasicNumericTickFormatterSpec(
                        (value) {
                      if (value == null) return '';
                      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      return days[value.toInt() % days.length];
                    },
                  ),
                  renderSpec: charts.SmallTickRendererSpec(
                    labelStyle: charts.TextStyleSpec(
                      fontSize: 12,
                      color: charts.MaterialPalette.gray.shade600,
                    ),
                    lineStyle: charts.LineStyleSpec(
                      color: charts.MaterialPalette.gray.shade300,
                    ),
                  ),
                ),
                behaviors: [
                  charts.ChartTitle(
                    'Daily Usage (Wh)',
                    behaviorPosition: charts.BehaviorPosition.start,
                    titleStyleSpec: charts.TextStyleSpec(
                      fontSize: 12,
                      color: charts.MaterialPalette.gray.shade600,
                    ),
                  ),
                  charts.SeriesLegend(
                    position: charts.BehaviorPosition.bottom,
                    outsideJustification: charts.OutsideJustification.start,
                    horizontalFirst: false,
                    desiredMaxRows: 1,
                    showMeasures: true,
                    measureFormatter: (num? value) {
                      if (value == null) return '-';
                      return '${value.toInt()} Wh';
                    },
                  ),
                  charts.LinePointHighlighter(
                    showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType.nearest,
                    showVerticalFollowLine: charts.LinePointHighlighterFollowLineType.nearest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}