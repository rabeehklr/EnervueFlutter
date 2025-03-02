// Updated HomePage implementation with drawer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/home_content.dart';
import 'anomaly_detection_page.dart';
import 'cost_estimation_page.dart';
import 'report_generation_page.dart';
import '../auth_service.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isDarkMode = false;

  final List<Widget> _pages = [
    HomeContent(),
    AnomalyDetectionPage(),
    CostEstimationPage(),
    ReportGenerationPage(),
  ];

  final List<String> _titles = [
    'Consumption Details',
    'Anomaly Details',
    'Cost Estimation',
    'Reports',
  ];

  void _navigateToPage(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    Navigator.pop(context); // Close the drawer after navigation
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<void> _handleLogout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentIndex = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _isDarkMode
              ? Colors.grey[900]
              : Colors.blue.withOpacity(0.5),
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            _titles[_currentIndex],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[900] : Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/picture1.jpg'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'EnerVue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                selected: _currentIndex == 0,
                onTap: () => _navigateToPage(0),
              ),
              ListTile(
                leading: Icon(Icons.warning),
                title: Text('Anomaly Detection'),
                selected: _currentIndex == 1,
                onTap: () => _navigateToPage(1),
              ),
              ListTile(
                leading: Icon(Icons.currency_rupee),
                title: Text('Cost Estimation'),
                selected: _currentIndex == 2,
                onTap: () => _navigateToPage(2),
              ),
              ListTile(
                leading: Icon(Icons.picture_as_pdf),
                title: Text('Reports'),
                selected: _currentIndex == 3,
                onTap: () => _navigateToPage(3),
              ),
              Divider(),
              ListTile(
                leading: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                title: Text('${_isDarkMode ? "Light" : "Dark"} Mode'),
                onTap: _toggleTheme,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _pages,
        ),
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
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.blueGrey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}