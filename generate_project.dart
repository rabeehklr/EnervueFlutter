import 'dart:io';

void main() async {
  // Define base directory
  final baseDir = Directory('lib');

  // Create directories if they don't exist
  await createDirectories();

  // Generate all files
  await generateFiles();

  print('Project structure created successfully!');
}

Future<void> createDirectories() async {
  final directories = [
    'lib/models',
    'lib/screens',
    'lib/widgets',
  ];

  for (var dir in directories) {
    await Directory(dir).create(recursive: true);
    print('Created directory: $dir');
  }
}

Future<void> generateFiles() async {
  // Map of file paths and their content
  final files = {
    'lib/main.dart': mainContent,
    'lib/models/appliance.dart': applianceModelContent,
    'lib/models/consumption_data.dart': consumptionDataModelContent,
    'lib/screens/splash_screen.dart': splashScreenContent,
    'lib/screens/login_screen.dart': loginScreenContent,
    'lib/screens/home_page.dart': homePageContent,
    'lib/screens/appliance_detail_screen.dart': applianceDetailScreenContent,
    'lib/screens/anomaly_detection_page.dart': anomalyDetectionPageContent,
    'lib/screens/cost_estimation_page.dart': costEstimationPageContent,
    'lib/screens/report_generation_page.dart': reportGenerationPageContent,
    'lib/widgets/home_content.dart': homeContentContent,
    'lib/widgets/appliance_widget.dart': applianceWidgetContent,
    'lib/widgets/consumption_graph.dart': consumptionGraphContent,
  };

  for (var entry in files.entries) {
    final file = File(entry.key);
    await file.writeAsString(entry.value);
    print('Generated file: ${entry.key}');
  }
}

// File contents
const mainContent = '''
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Home Analytics',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
''';

const applianceModelContent = '''
import 'consumption_data.dart';

class Appliance {
  final String name;
  final String consumption;
  final String usageTime;
  final String imageAsset;
  final List<ConsumptionData> data;

  Appliance({
    required this.name, 
    required this.consumption, 
    required this.usageTime, 
    required this.imageAsset, 
    required this.data
  });
}
''';

const consumptionDataModelContent = '''
class ConsumptionData {
  final String day;
  final int usage;

  ConsumptionData({required this.day, required this.usage});
}
''';

const splashScreenContent = '''
import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/picture1.jpg',
              width: 300,
              height: 300,
            ),
            SizedBox(height: 20),
            Text(
              'EnerVue',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''';

const loginScreenContent = '''
import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
''';

const homePageContent = '''
import 'package:flutter/material.dart';
import '../widgets/home_content.dart';
import 'anomaly_detection_page.dart';
import 'cost_estimation_page.dart';
import 'report_generation_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeContent(),
    AnomalyDetectionPage(),
    CostEstimationPage(),
    ReportGenerationPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Home Dashboard')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Anomaly Detection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee_sharp),
            label: 'Cost Estimation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'Reports',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
''';

const applianceDetailScreenContent = '''
import 'package:flutter/material.dart';
import '../models/appliance.dart';
import '../widgets/consumption_graph.dart';

class ApplianceDetailScreen extends StatelessWidget {
  final Appliance appliance;

  ApplianceDetailScreen({required this.appliance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('\${appliance.name} Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consumption: \${appliance.consumption}', style: TextStyle(fontSize: 18)),
            Text('Usage Time: \${appliance.usageTime}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Text('Weekly Data:', style: TextStyle(fontSize: 18)),
            Expanded(child: ConsumptionGraph(appliance: appliance)),
          ],
        ),
      ),
    );
  }
}
''';

const anomalyDetectionPageContent = '''
import 'package:flutter/material.dart';

class AnomalyDetectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Anomaly Detection Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
''';

const costEstimationPageContent = '''
import 'package:flutter/material.dart';

class CostEstimationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Cost Estimation Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
''';

const reportGenerationPageContent = '''
import 'package:flutter/material.dart';

class ReportGenerationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Report Generation Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
''';

const homeContentContent = '''
import 'package:flutter/material.dart';
import '../models/appliance.dart';
import '../models/consumption_data.dart';
import 'appliance_widget.dart';

class HomeContent extends StatelessWidget {
  final List<Appliance> appliances = [
    Appliance(
      name: 'Fan',
      consumption: '50 Wh',
      usageTime: '30 hours',
      imageAsset: 'assets/fan.jpg',
      data: [
        ConsumptionData(day: 'Mon', usage: 10),
        ConsumptionData(day: 'Tue', usage: 20),
        ConsumptionData(day: 'Wed', usage: 30),
        ConsumptionData(day: 'Thu', usage: 40),
        ConsumptionData(day: 'Fri', usage: 50),
        ConsumptionData(day: 'Sat', usage: 45),
        ConsumptionData(day: 'Sun', usage: 35),
      ],
    ),
    Appliance(
      name: 'Bulb',
      consumption: '20 kWh',
      usageTime: '50 hours',
      imageAsset: 'assets/bulb.jpg',
      data: [
        ConsumptionData(day: 'Mon', usage: 15),
        ConsumptionData(day: 'Tue', usage: 25),
        ConsumptionData(day: 'Wed', usage: 35),
        ConsumptionData(day: 'Thu', usage: 45),
        ConsumptionData(day: 'Fri', usage: 55),
        ConsumptionData(day: 'Sat', usage: 50),
        ConsumptionData(day: 'Sun', usage: 40),
      ],
    ),
    Appliance(
      name: 'Laptop Charger',
      consumption: '10 kWh',
      usageTime: '10 hours',
      imageAsset: 'assets/laptop.jpg',
      data: [
        ConsumptionData(day: 'Mon', usage: 12),
        ConsumptionData(day: 'Tue', usage: 22),
        ConsumptionData(day: 'Wed', usage: 32),
        ConsumptionData(day: 'Thu', usage: 42),
        ConsumptionData(day: 'Fri', usage: 52),
        ConsumptionData(day: 'Sat', usage: 47),
        ConsumptionData(day: 'Sun', usage: 37),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: appliances.length,
      itemBuilder: (context, index) {
        return ApplianceWidget(appliance: appliances[index]);
      },
    );
  }
}
''';

const applianceWidgetContent = '''
import 'package:flutter/material.dart';
import '../models/appliance.dart';
import '../screens/appliance_detail_screen.dart';

class ApplianceWidget extends StatelessWidget {
  final Appliance appliance;

  ApplianceWidget({required this.appliance});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ApplianceDetailScreen(appliance: appliance)),
        );
      },
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              appliance.imageAsset,
              width: 80,
              height: 80,
            ),
            SizedBox(height: 8),
            Text(
              appliance.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Consumption: \${appliance.consumption}'),
          ],
        ),
      ),
    );
  }
}
''';

const consumptionGraphContent = '''
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../models/appliance.dart';
import '../models/consumption_data.dart';

class ConsumptionGraph extends StatelessWidget {
  final Appliance appliance;

  ConsumptionGraph({required this.appliance});

  @override
  Widget build(BuildContext context) {
    List<charts.Series<ConsumptionData, String>> series = [
      charts.Series<ConsumptionData, String>(
        id: 'Consumption',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ConsumptionData data, _) => data.day,
        measureFn: (ConsumptionData data, _) => data.usage,
        data: appliance.data,
      )
    ];

    return charts.BarChart(
      series,
      animate: true,
      vertical: true,
    );
  }
}
''';