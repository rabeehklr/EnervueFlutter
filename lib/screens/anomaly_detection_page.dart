import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/real_time_data_provider.dart';
import '../widgets/anomaly_appliance_widget.dart';
import '../screens/anomaly_detail_screen.dart';

class AnomalyDetectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RealTimeDataProvider>(
      builder: (context, provider, child) {
        if (!provider.isConnected) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.appliances.length,
          itemBuilder: (context, index) {
            final appliance = provider.appliances[index];
            return AnomalyApplianceWidget(
              appliance: appliance,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnomalyDetailScreen(appliance: appliance),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}