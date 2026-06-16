import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:clutr/core/platform/storage_channel.dart';
import 'package:clutr/core/services/trash_service.dart';
import 'package:clutr/features/settings/providers/settings_provider.dart';
import 'package:clutr/core/utils/size_formatter.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:io';

final mediaProvider = NotifierProvider<MediaNotifier, AsyncValue<List<Map<String, dynamic>>?>>(MediaNotifier.new);

class MediaNotifier extends Notifier<AsyncValue<List<Map<String, dynamic>>?>> {
  @override
  AsyncValue<List<Map<String, dynamic>>?> build() {
    Future.microtask(() => startScan());
    return const AsyncValue.loading();
  }

  Future<void> startScan() async {
    state = const AsyncValue.loading();
    
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
        Permission.manageExternalStorage,
      ].request();
    }

    // Simulate a deep scan delay for visual effect
    await Future.delayed(const Duration(seconds: 2));

    final mediaList = await StorageChannel.getMediaFiles();
    final whatsappMedia = await StorageChannel.getWhatsAppHiddenMedia();
    
    final allMedia = [...mediaList, ...whatsappMedia];
    final parsedList = allMedia.map((e) => Map<String, dynamic>.from(e)).toList();
    
    state = AsyncValue.data(parsedList);
    _updateWidget(parsedList);
  }

  Future<void> deleteMedia(String path) async {
    final currentList = state.value ?? [];
    
    // Remove from the queue immediately
    final newList = currentList.where((element) => element['path'] != path).toList();
    state = AsyncValue.data(newList);
    _updateWidget(newList);
    
    final isTempDelete = ref.read(settingsProvider).isTemporaryDelete;
    
    bool success;
    if (isTempDelete) {
      success = await TrashService.moveToTrash(path);
    } else {
      success = await StorageChannel.deleteFile(path);
    }
    
    if (!success) {
      print('Note: Could not delete from disk, but removed from UI queue.');
    }
  }

  void keepMedia(String path) {
    final currentList = state.value ?? [];
    final newList = currentList.where((element) => element['path'] != path).toList();
    state = AsyncValue.data(newList);
    _updateWidget(newList);
  }

  Future<void> _updateWidget(List<Map<String, dynamic>> mediaList) async {
    double totalBytes = 0;
    for (var item in mediaList) {
      totalBytes += (item['size'] as num?)?.toDouble() ?? 0.0;
    }
    final formattedSize = SizeFormatter.formatBytes(totalBytes.toInt());
    await HomeWidget.saveWidgetData<String>('space_to_clean', formattedSize);
    await HomeWidget.updateWidget(androidName: 'ClutrWidgetProvider');
  }
}
