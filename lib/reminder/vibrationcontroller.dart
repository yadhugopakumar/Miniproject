import 'package:vibration/vibration.dart';

class VibrationController {
  static bool _isVibrating = false;

  static Future<void> startVibration() async {
    if (!await Vibration.hasVibrator()) return;
    if (_isVibrating) return;

    _isVibrating = true;
    Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
  }

  static Future<void> stopVibration() async {
    if (_isVibrating) {
      await Vibration.cancel();
      _isVibrating = false;
    }
  }
}
