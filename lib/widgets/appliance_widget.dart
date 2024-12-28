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
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: appliance.isOn ? Colors.green : Colors.red,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
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
            Text('Consumption: ${appliance.consumption}'),
            SizedBox(height: 4),
            // Add status indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: appliance.isOn ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: appliance.isOn ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    appliance.isOn ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: appliance.isOn ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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