import 'package:flutter/material.dart';
import '../models/appliance.dart';

class AnomalyApplianceWidget extends StatefulWidget {
  final Appliance appliance;
  final VoidCallback onTap;

  const AnomalyApplianceWidget({super.key,
    required this.appliance,
    required this.onTap,
  });

  @override
  _AnomalyApplianceWidgetState createState() => _AnomalyApplianceWidgetState();
}

class _AnomalyApplianceWidgetState extends State<AnomalyApplianceWidget> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: widget.appliance.anomaly ? Colors.red : Colors.green,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with name and notification bell
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.appliance.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: _notificationsEnabled ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _notificationsEnabled = !_notificationsEnabled;
                      });
                      // Add notification toggle logic here
                    },
                  ),
                ],
              ),
              // Appliance image
              Expanded(
                child: Center(
                  child: Image.asset(
                    widget.appliance.imageAsset,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              // Anomaly status
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.appliance.anomaly
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.appliance.anomaly
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color: widget.appliance.anomaly ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      widget.appliance.anomaly
                          ? 'Anomaly Detected'
                          : 'Normal Operation',
                      style: TextStyle(
                        color: widget.appliance.anomaly
                            ? Colors.red
                            : Colors.green,
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
      ),
    );
  }
}