import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/real_time_data_provider.dart';
import '../providers/electricity_rate_provider.dart';
import '../models/cost_estimate.dart';
import '../models/consumption_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../screens/report_generation_page.dart';
import 'package:flutter/services.dart' show rootBundle;

class CostEstimationPage extends StatefulWidget {
  @override
  _CostEstimationPageState createState() => _CostEstimationPageState();
}

class _CostEstimationPageState extends State<CostEstimationPage> {
  String _selectedDuration = 'Weekly';
  List<CostEstimate> _estimates = [];
  bool _showEstimates = false;
  double _totalConsumption = 0.0;

  Future<void> _calculateEstimates(BuildContext context) async {
    final rateProvider = Provider.of<ElectricityRateProvider>(context, listen: false);
    final dataProvider = Provider.of<RealTimeDataProvider>(context, listen: false);

    _estimates.clear();
    _totalConsumption = 0.0;

    DateTime endDate = DateTime.now();
    DateTime startDate = _selectedDuration == 'Weekly'
        ? endDate.subtract(Duration(days: 7))
        : endDate.subtract(Duration(days: 30));

    for (var appliance in dataProvider.appliances) {
      List<ConsumptionData> historicalData = await dataProvider.fetchHistoricalData(
        appliance.name,
        startDate,
        endDate,
      );

      double totalConsumptionForPeriodWh = historicalData.fold(
        0.0,
            (sum, data) => sum + data.usage,
      );

      double totalConsumptionForPeriodKWh = totalConsumptionForPeriodWh / 1000.0;

      _totalConsumption += totalConsumptionForPeriodWh;
      _estimates.add(CostEstimate(
        applianceName: appliance.name,
        consumption: totalConsumptionForPeriodWh,
        rate: 0.0,
        totalCost: 0.0,
        generatedAt: DateTime.now(),
        duration: _selectedDuration,
      ));
    }

    double totalConsumptionKWh = _totalConsumption / 1000.0;
    double totalCost = rateProvider.calculateTotalCost(totalConsumptionKWh);

    for (var estimate in _estimates) {
      if (_totalConsumption > 0) {
        double consumptionKWh = estimate.consumption / 1000.0;
        estimate.totalCost = (consumptionKWh / totalConsumptionKWh) * totalCost;
        estimate.rate = rateProvider.getApplicableRate(totalConsumptionKWh);
      }
    }

    setState(() {
      _showEstimates = true;
    });
  }

  Future<void> _generateReport() async {
    final pdf = pw.Document();

    // Load Open Sans fonts (ensure they support ₹)
    final regularFont = pw.Font.ttf(await rootBundle.load("assets/fonts/OpenSans-Regular.ttf"));
    final boldFont = pw.Font.ttf(await rootBundle.load("assets/fonts/OpenSans-Bold.ttf"));

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData(
            defaultTextStyle: pw.TextStyle(font: regularFont),
            // Explicitly set fonts for headings and tables
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.blue100, PdfColors.white],
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        header: (context) => pw.Container(
          padding: pw.EdgeInsets.all(16),
          color: PdfColors.blue800,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'EnerVue',
                style: pw.TextStyle(
                  fontSize: 24,
                  font: boldFont,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Generated: ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(
                  fontSize: 12,
                  font: regularFont,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Electricity Cost Estimation Report',
              style: pw.TextStyle(
                fontSize: 28,
                font: boldFont,
                color: PdfColors.blue900,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 1, color: PdfColors.grey400),
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue600),
            cellStyle: pw.TextStyle(font: regularFont),
            cellAlignment: pw.Alignment.center,
            data: <List<String>>[
              ['Appliance', 'Consumption (kWh)', 'Rate (Per kWh)', 'Cost (INR)'],
              ..._estimates.map((e) => [
                e.applianceName,
                (e.consumption / 1000.0).toStringAsFixed(2),
                '${e.rate.toStringAsFixed(2)}', // Rupee symbol handled in cell content
                '${e.totalCost.toStringAsFixed(2)}', // Explicit ₹ symbol
              ]).toList(),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Consumption: ${(_totalConsumption / 1000.0).toStringAsFixed(2)} kWh',
                style: pw.TextStyle(fontSize: 16, font: regularFont, color: PdfColors.grey800),
              ),
              pw.Text(
                'Total Cost: ${_estimates.fold(0.0, (sum, e) => sum + e.totalCost).toStringAsFixed(2)} INR',
                style: pw.TextStyle(fontSize: 18, font: boldFont, color: PdfColors.green800),
              ),
            ],
          ),
        ],
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '© 2025 EnerVue | All Rights Reserved',
                  style: pw.TextStyle(fontSize: 10, font: regularFont, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Notice: This is a projected electricity bill generated by EnerVue, developed as part of the project by Group 1, S8 CSE-2. Actual costs may differ.',
              style: pw.TextStyle(fontSize: 8, font: regularFont, color: PdfColors.grey500),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/EnerVue_Cost_Estimate_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportGenerationPage(pdfPath: file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Duration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'Weekly',
                          label: Text('Weekly'),
                          icon: Icon(Icons.calendar_view_week),
                        ),
                        ButtonSegment(
                          value: 'Monthly',
                          label: Text('Monthly'),
                          icon: Icon(Icons.calendar_month),
                        ),
                      ],
                      selected: {_selectedDuration},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          _selectedDuration = selection.first;
                          _showEstimates = false;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _calculateEstimates(context),
                      child: Text('Calculate Estimate'),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
            ),
            if (_showEstimates) ...[
              SizedBox(height: 24),
              Text(
                'Cost Estimates ($_selectedDuration)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _estimates.length + 1,
                itemBuilder: (context, index) {
                  if (index == _estimates.length) {
                    double totalCost = _estimates.fold(0.0, (sum, estimate) => sum + estimate.totalCost);
                    return Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${totalCost.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final estimate = _estimates[index];
                  return Card(
                    child: ListTile(
                      title: Text(estimate.applianceName),
                      subtitle: Text(
                        'Consumption: ${(estimate.consumption / 1000.0).toStringAsFixed(2)} kWh\n'
                            'Rate: ₹${estimate.rate.toStringAsFixed(2)}/kWh',
                      ),
                      trailing: Text(
                        '₹${estimate.totalCost.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _generateReport,
                icon: Icon(Icons.picture_as_pdf),
                label: Text('Generate Report'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}