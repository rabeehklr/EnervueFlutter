import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/appliance.dart';
import '../providers/real_time_data_provider.dart';

class AnomalyApplianceWidget extends StatefulWidget {
  final Appliance appliance;
  final VoidCallback onTap;

  const AnomalyApplianceWidget({
    Key? key,
    required this.appliance,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnomalyApplianceWidget> createState() => _AnomalyApplianceWidgetState();
}

class _AnomalyApplianceWidgetState extends State<AnomalyApplianceWidget> {
  bool _isInAnomalyState = false;
  Timer? _anomalyTimer;

  @override
  void initState() {
    super.initState();
    _checkAndUpdateAnomalyState();
  }

  @override
  void didUpdateWidget(AnomalyApplianceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appliance.anomaly != widget.appliance.anomaly) {
      _checkAndUpdateAnomalyState();
    }
  }

  void _checkAndUpdateAnomalyState() {
    if (widget.appliance.anomaly && !_isInAnomalyState) {
      _anomalyTimer?.cancel();
      setState(() {
        _isInAnomalyState = true;
      });
      _anomalyTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isInAnomalyState = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _anomalyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealTimeDataProvider>(
      builder: (context, provider, child) {
        final notificationsEnabled = provider.isNotificationEnabled(widget.appliance.name);
        final currentLimit = provider.getConsumptionLimit(widget.appliance.name);

        return GestureDetector(
          onTap: widget.onTap,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _isInAnomalyState ? Colors.red : Colors.green,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top row with limit icon, name, and notification bell
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.tune, color: Colors.blue),
                        onPressed: () => _showLimitSliderDialog(context, widget.appliance.name, currentLimit),
                      ),
                      Expanded(
                        child: Text(
                          widget.appliance.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: notificationsEnabled ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          provider.toggleNotifications(
                            widget.appliance.name,
                            !notificationsEnabled,
                          );
                        },
                      ),
                    ],
                  ),
                  // Centered appliance icon section
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              widget.appliance.imageAsset,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                            if (_isInAnomalyState)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Status section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _isInAnomalyState
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isInAnomalyState
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle,
                          color: _isInAnomalyState ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isInAnomalyState ? 'Anomaly' : 'Normal',
                          style: TextStyle(
                            color: _isInAnomalyState ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isInAnomalyState && widget.appliance.anomaliesToday > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Anomalies today: ${widget.appliance.anomaliesToday}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLimitSliderDialog(BuildContext context, String applianceName, double currentLimit) {
    double newLimit = currentLimit.isFinite ? currentLimit : 100.0; // Default to 100W if infinite
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Power Limit for $applianceName'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current Limit: ${newLimit.round()} W'),
                  Slider(
                    value: newLimit,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '${newLimit.round()} W',
                    onChanged: (value) {
                      setState(() {
                        newLimit = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<RealTimeDataProvider>(context, listen: false)
                    .updateConsumptionLimit(applianceName, newLimit);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}