// lib/widgets/home_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/real_time_data_provider.dart';
import 'appliance_widget.dart';

class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    // Connect to WebSocket when the home content initializes
    Future.microtask(() =>
        Provider.of<RealTimeDataProvider>(context, listen: false).connectToServer());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealTimeDataProvider>(
      builder: (context, provider, child) {
        if (!provider.isConnected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Connecting to server...'),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.appliances.length,
          itemBuilder: (context, index) {
            return ApplianceWidget(appliance: provider.appliances[index]);
          },
        );
      },
    );
  }
}