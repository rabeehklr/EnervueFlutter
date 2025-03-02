import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/appliance.dart';
import '../models/consumption_data.dart';
import '../notification_service.dart';
import 'package:http/http.dart' as http;

class RealTimeDataProvider with ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  Map<String, dynamic> _latestData = {};
  final NotificationService _notificationService = NotificationService();
  Map<String, bool> _notificationSettings = {};
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 50;
  static const String baseUrl = 'http://192.168.62.152:5001';

  // Dynamic consumption limits, default values can be overridden by user
  Map<String, double> _consumptionLimits = {
    'bulb': 65.0,
    'laptop charger': 150.0,
    'unknown': double.infinity,
  };

  bool get isConnected => _isConnected;
  Map<String, dynamic> get latestData => _latestData;
  List<Appliance> _appliances = [];
  List<Appliance> get appliances => _appliances;

  RealTimeDataProvider() {
    initialize();
  }

  void initialize() async {
    await _notificationService.initialize();
    connectToServer();
    _notificationSettings['laptop charger'] = true;
    _notificationSettings['bulb'] = true;
    print('Initialized with limits: $_consumptionLimits');
  }

  // Method to update consumption limit for an appliance
  void updateConsumptionLimit(String applianceName, double limit) {
    _consumptionLimits[applianceName.toLowerCase()] = limit;
    syncLimitWithBackend(applianceName, limit); // Sync with backend
    notifyListeners();
    print('Updated limit for $applianceName to $limit');
    _updateData(_latestData); // Reprocess data with new limits
  }

  // Method to get the current limit for an appliance
  double getConsumptionLimit(String applianceName) {
    return _consumptionLimits[applianceName.toLowerCase()] ?? double.infinity;
  }

  Future<void> syncLimitWithBackend(String applianceName, double limit) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/update-limit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'appliance_name': applianceName,
          'limit': limit,
        }),
      );
      if (response.statusCode == 200) {
        print('Successfully synced limit for $applianceName with backend');
      } else {
        print('Failed to sync limit: ${response.body}');
      }
    } catch (e) {
      print('Error syncing limit with backend: $e');
    }
  }

  void toggleNotifications(String applianceName, bool enabled) {
    _notificationSettings[applianceName.toLowerCase()] = enabled;
    notifyListeners();
  }

  bool isNotificationEnabled(String applianceName) {
    return _notificationSettings[applianceName.toLowerCase()] ?? false;
  }

  void connectToServer() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }
    try {
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'reconnectionAttempts': maxReconnectAttempts,
      });
      _setupSocketListeners();
    } catch (e) {
      print('Error connecting to Socket.IO server: $e');
      _handleConnectionError();
    }
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('Connected to Socket.IO server');
      _isConnected = true;
      _reconnectAttempts = 0;
      notifyListeners();
    });
    _socket?.onDisconnect((_) {
      print('Disconnected from Socket.IO server');
      _isConnected = false;
      notifyListeners();
    });
    _socket?.onConnectError((error) {
      print('Connection error: $error');
      _handleConnectionError();
    });
    _socket?.onError((error) {
      print('Socket error: $error');
    });
    _socket?.on('real_time_data', (data) {
      print('Received real-time data: $data');
      _updateData(data);
    });
  }

  void _handleConnectionError() {
    _isConnected = false;
    _reconnectAttempts++;
    notifyListeners();
    if (_reconnectAttempts < maxReconnectAttempts) {
      Future.delayed(Duration(seconds: 5), () {
        print('Attempting to reconnect... (Attempt $_reconnectAttempts)');
        connectToServer();
      });
    }
  }

  void _updateData(Map<String, dynamic> data) {
    _latestData = data;
    try {
      List<dynamic> activeAppliances = data['active_appliances'] ?? [];
      List<dynamic> inactiveAppliances = data['inactive_appliances'] ?? [];
      List<dynamic> allApplianceData = [...activeAppliances, ...inactiveAppliances];

      print('Consumption limits: $_consumptionLimits');

      _appliances = allApplianceData.map((applianceData) {
        String rawName = applianceData['name'];
        double currentPower = applianceData['current_power'].toDouble();
        double kWh = double.tryParse(applianceData['consumption'] ?? '0') ?? 0;
        String name = rawName.toLowerCase().trim();
        double limit = getConsumptionLimit(name);
        bool isAnomalyFromBackend = applianceData['anomaly'] ?? false;
        bool customAnomaly = currentPower > limit;
        bool notificationsEnabled = isNotificationEnabled(name);
        bool isOn = applianceData['status'] == 'on';

        print('Checking $name: currentPower=$currentPower, limit=$limit, '
            'isAnomalyFromBackend=$isAnomalyFromBackend, customAnomaly=$customAnomaly, '
            'notificationsEnabled=$notificationsEnabled, isOn=$isOn');

        if ((isAnomalyFromBackend || customAnomaly) && notificationsEnabled && isOn) {
          print('Triggering notification for $name');
          _notificationService.showAnomalyNotification(
            applianceName: name,
            playSound: true,
            context: null,
          );
        }

        return Appliance(
          name: name,
          consumption: '${kWh.toStringAsFixed(3)} Wh',
          usageTime: '${applianceData["time_used"]} mins',
          imageAsset: 'assets/images/$name.png',
          data: _processWeeklyData(applianceData['weekly_data']),
          isOn: isOn,
          avgPower: '${currentPower.round()}W',
          peakPower: '${(applianceData["peak_power"] ?? 0).round()}W',
          onOffCycles: '${applianceData['cycles'] ?? 0} times',
          anomaly: isAnomalyFromBackend || customAnomaly,
          anomaliesToday: applianceData['anomalies_today'] ?? 0,
          weeklyAnomalies: _processWeeklyAnomalies(applianceData['weekly_anomalies']),
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error processing appliance data: $e');
    }
  }

  List<ConsumptionData> _processWeeklyData(dynamic weeklyData) {
    if (weeklyData == null || weeklyData is! List) {
      return _getDefaultWeeklyData();
    }
    try {
      return weeklyData.map<ConsumptionData>((data) {
        return ConsumptionData(
          day: data['day'] as String,
          usage: (data['usage'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Error processing weekly data: $e');
      return _getDefaultWeeklyData();
    }
  }

  List<ConsumptionData> _getDefaultWeeklyData() {
    return [
      ConsumptionData(day: 'Mon', usage: 0.0),
      ConsumptionData(day: 'Tue', usage: 0.0),
      ConsumptionData(day: 'Wed', usage: 0.0),
      ConsumptionData(day: 'Thu', usage: 0.0),
      ConsumptionData(day: 'Fri', usage: 0.0),
      ConsumptionData(day: 'Sat', usage: 0.0),
      ConsumptionData(day: 'Sun', usage: 0.0),
    ];
  }

  List<Map<String, dynamic>> _processWeeklyAnomalies(dynamic weeklyAnomalies) {
    if (weeklyAnomalies == null || weeklyAnomalies is! List) {
      return _getDefaultWeeklyAnomalies();
    }
    try {
      return List<Map<String, dynamic>>.from(weeklyAnomalies);
    } catch (e) {
      print('Error processing weekly anomalies: $e');
      return _getDefaultWeeklyAnomalies();
    }
  }

  List<Map<String, dynamic>> _getDefaultWeeklyAnomalies() {
    return [
      {'day': 'Mon', 'count': 0},
      {'day': 'Tue', 'count': 0},
      {'day': 'Wed', 'count': 0},
      {'day': 'Thu', 'count': 0},
      {'day': 'Fri', 'count': 0},
      {'day': 'Sat', 'count': 0},
      {'day': 'Sun', 'count': 0},
    ];
  }

  Future<List<ConsumptionData>> fetchHistoricalData(
      String applianceName, DateTime startDate, DateTime endDate) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/historical-data'
            '?appliance_name=$applianceName'
            '&start_date=${startDate.toIso8601String()}'
            '&end_date=${endDate.toIso8601String()}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((item) {
          return ConsumptionData(
            day: item['day'],
            usage: (item['usage'] as num).toDouble(),
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch historical data');
      }
    } catch (e) {
      print('Error fetching historical data: $e');
      return _getDefaultWeeklyData();
    }
  }

  Future<Map<String, dynamic>> fetchCostEstimation(
      List<String> appliances, String duration) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cost-estimation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'appliances': appliances.map((name) => {'name': name}).toList(),
          'duration': duration,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch cost estimation');
      }
    } catch (e) {
      print('Error fetching cost estimation: $e');
      return {'estimates': [], 'total_cost': 0.0};
    }
  }

  List<Appliance> getActiveAppliances() {
    return _appliances.where((appliance) => appliance.isOn).toList();
  }

  List<Appliance> getInactiveAppliances() {
    return _appliances.where((appliance) => !appliance.isOn).toList();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _notificationService.dispose();
    super.dispose();
  }
}