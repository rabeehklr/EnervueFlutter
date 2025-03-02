import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _alertSound = 'assets/alert_sound.mp3';

  Future<void> initialize() async {
    print('NotificationService initialized');
  }

  Future<void> showAnomalyNotification({
    required String applianceName,
    required bool playSound,
    BuildContext? context,
  }) async {
    print('showAnomalyNotification called for $applianceName');

    if (playSound) {
      try {
        await _audioPlayer.play(AssetSource(_alertSound));
        print('Sound played successfully for $applianceName');
      } catch (e) {
        print('Error playing sound for $applianceName: $e');
      }
    }

    try {
      await Fluttertoast.showToast(
        msg: 'Unusual behavior detected in your $applianceName',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      print('Toast displayed successfully for $applianceName');
    } catch (e) {
      print('Error displaying toast for $applianceName: $e');
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    print('NotificationService disposed');
  }
}