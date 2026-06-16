import 'package:workmanager/workmanager.dart';
import 'package:clutr/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clutr/core/platform/storage_channel.dart';
import 'package:clutr/core/utils/size_formatter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:clutr/core/services/trash_service.dart';

const String backgroundTaskName = "clutrNotificationTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case backgroundTaskName:
        final prefs = await SharedPreferences.getInstance();
        final spaceLimitGb = prefs.getDouble('settings_space_limit_gb') ?? 5.0;
        final spaceLimitEnabled = prefs.getBool('settings_space_limit_enabled') ?? false;
        final trashAutoEmptyDays = prefs.getInt('settings_trash_auto_empty_days') ?? 30;

        // Auto empty trash
        try {
          await TrashService.cleanExpiredItems(trashAutoEmptyDays);
        } catch (e) {
          print("Error cleaning trash in background: $e");
        }

        // Scan device for space
        final mediaList = await StorageChannel.getMediaFiles();
        final whatsappMedia = await StorageChannel.getWhatsAppHiddenMedia();
        
        double totalBytes = 0;
        for (var item in [...mediaList, ...whatsappMedia]) {
          totalBytes += (item['size'] as num?)?.toDouble() ?? 0.0;
        }

        final formattedSize = SizeFormatter.formatBytes(totalBytes.toInt());
        
        // Update Android Widget automatically
        await HomeWidget.saveWidgetData<String>('space_to_clean', formattedSize);
        await HomeWidget.updateWidget(androidName: 'ClutrWidgetProvider');

        // Check if limit exceeded
        if (spaceLimitEnabled) {
          final limitBytes = spaceLimitGb * 1024 * 1024 * 1024;
          if (totalBytes > limitBytes) {
            final notificationService = NotificationService();
            await notificationService.init();
            
            await notificationService.showNotification(
              id: 1,
              title: 'Storage Limit Reached!',
              body: 'You have $formattedSize of clutter. Time to clean up!',
            );
          }
        }
        break;
    }
    return Future.value(true);
  });
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();

  factory BackgroundTaskService() {
    return _instance;
  }

  BackgroundTaskService._internal();

  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "clutr_periodic_task_1", // Unique ID
      backgroundTaskName,
      frequency: const Duration(minutes: 15), // 15 mins is the minimum on Android
      initialDelay: const Duration(minutes: 1),
    );
  }

  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}
