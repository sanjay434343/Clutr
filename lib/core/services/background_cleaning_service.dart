import 'package:flutter/services.dart';

class BackgroundCleaningService {
  static const MethodChannel _channel = MethodChannel('com.clutr.app/storage');

  static Future<void> initialize() async {
    // Initialization is handled natively on Android side now
  }

  static Future<void> scheduleAutoClean(int daysInterval, List<String> targetFolders) async {
    int interval = daysInterval;
    
    // No longer mapping 1 to -1 for testing. 1 day is now a real option.
    
    // Cancel if 0 days or no folders selected
    if (interval == 0 || targetFolders.isEmpty) {
      interval = 0;
    }

    try {
      await _channel.invokeMethod('scheduleNativeAutoClean', {
        'daysInterval': interval,
        'targetFolders': targetFolders,
      });
    } catch (e) {
      print('Failed to schedule native auto clean: $e');
    }
  }
}
