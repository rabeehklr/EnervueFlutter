import 'package:flutter/material.dart';
import '../models/appliance.dart';
import '../widgets/consumption_graph.dart';

class ApplianceDetailScreen extends StatelessWidget {
  final Appliance appliance;

  const ApplianceDetailScreen({required this.appliance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.withOpacity(0.5),
        title: Text(
          '${appliance.name} Details',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Stats Section
              const Text(
                "Today's Stats",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // First Row - Consumption and Usage Time
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.electric_bolt,
                      iconColor: Colors.blue,
                      title: 'Consumption',
                      value: appliance.consumption,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.access_time,
                      iconColor: Colors.green,
                      title: 'Usage Time',
                      value: appliance.usageTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Second Row - Average Power and Peak Power
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.speed,
                      iconColor: Colors.orange,
                      title: 'Avg. Power',
                      value: appliance.avgPower,  // Replace with actual data
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.bolt,
                      iconColor: Colors.red,
                      title: 'Peak Power',
                      value: appliance.peakPower,  // Replace with actual data
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Third Row - ON/OFF Cycles
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.replay_circle_filled,
                      iconColor: Colors.purple,
                      title: 'ON/OFF Cycles',
                      value: appliance.onOffCycles,  // Replace with actual data
                    ),
                  ),
                  const Expanded(child: SizedBox()), // Empty space for alignment
                ],
              ),
              const SizedBox(height: 24),

              // Consumption Graph
              SizedBox(
                height: 400,
                child: ConsumptionGraph(appliance: appliance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}