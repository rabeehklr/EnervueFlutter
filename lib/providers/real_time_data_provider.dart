// lib/providers/real_time_data_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/appliance.dart';
import '../models/consumption_data.dart';

class RealTimeDataProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Map<String, dynamic> _latestData = {};

  // Number of reconnection attempts
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  bool get isConnected => _isConnected;
  Map<String, dynamic> get latestData => _latestData;

  List<Appliance> _appliances = [];
  List<Appliance> get appliances => _appliances;

  String getWebSocketUrl() {
    // If running on Android emulator, use 10.0.2.2 instead of localhost
    // If running on iOS simulator, use localhost
    // For physical devices, use your computer's actual IP address
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:8000/ws';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ws://localhost:8000/ws';
    } else {
      return 'ws://localhost:8000/ws';
    }
  }

  void connectToServer() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    try {
      final wsUrl = getWebSocketUrl();
      print('Connecting to WebSocket at: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
            (message) {
          final data = jsonDecode(message);
          _updateData(data);
          _isConnected = true;
          _reconnectAttempts = 0; // Reset attempts on successful connection
          notifyListeners();
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleConnectionError();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleConnectionError();
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    _isConnected = false;
    _reconnectAttempts++;
    notifyListeners();

    // Try to reconnect after 5 seconds if max attempts not reached
    if (_reconnectAttempts < maxReconnectAttempts) {
      Future.delayed(const Duration(seconds: 5), connectToServer);
    }
  }

  void _updateData(Map<String, dynamic> data) {
    _latestData = data;

    _appliances = (data['appliances'] as List).map((applianceData) {
      double kWh = applianceData['current_power'] / 1000;

      List<ConsumptionData> weeklyData = [
        ConsumptionData(day: 'Mon', usage: (kWh * 24).round()),
        ConsumptionData(day: 'Tue', usage: (kWh * 24).round()),
        ConsumptionData(day: 'Wed', usage: (kWh * 24).round()),
        ConsumptionData(day: 'Thu', usage: (kWh * 24).round()),
        ConsumptionData(day: 'Fri', usage: (kWh * 24).round()),
        ConsumptionData(day: 'Sat', usage: (kWh * 24).round()),
        ConsumptionData(day: 'Sun', usage: (kWh * 24).round()),
      ];

      // Weekly anomalies data
      List<Map<String, dynamic>> weeklyAnomalies = [
        {'day': 'Mon', 'count': 2},
        {'day': 'Tue', 'count': 1},
        {'day': 'Wed', 'count': 3},
        {'day': 'Thu', 'count': 0},
        {'day': 'Fri', 'count': 2},
        {'day': 'Sat', 'count': 1},
        {'day': 'Sun', 'count': 2},
      ];

      return Appliance(
        name: applianceData['name'],
        consumption: '${kWh.toStringAsFixed(2)} kWh',
        usageTime: '${applianceData["time_used"]} mins',
        imageAsset: 'assets/${applianceData["name"].toLowerCase()}.png',
        data: weeklyData,
        isOn: applianceData['status'] == 'on',
        avgPower: '${(applianceData['current_power'] as num).round()}W',
        peakPower: '${(applianceData['peak_power'] ?? applianceData['current_power'] * 1.2).round()}W',
        onOffCycles: '${applianceData['cycles'] ?? 0} times',
        anomaly: applianceData['anomaly'] ?? false,
        anomaliesToday: applianceData['anomalies_today'] ?? 0,
        weeklyAnomalies: weeklyAnomalies,
      );
    }).toList();

    notifyListeners();
  }

  void dispose() {
    _channel?.sink.close();
  }
}