import 'package:flutter/services.dart';

class StorageChannel {
  static const MethodChannel _channel = MethodChannel('com.clutr.app/storage');

  /// Fetches media files (images, videos) from the device storage.
  /// This will eventually be paginated or chunked for performance.
  static Future<List<dynamic>> getMediaFiles() async {
    try {
      final List<dynamic>? files = await _channel.invokeListMethod('getMediaFiles');
      return files ?? [];
    } on PlatformException catch (e) {
      print("Failed to get media files: '${e.message}'.");
      return [];
    }
  }

  /// Deletes a file permanently.
  static Future<bool> deleteFile(String path) async {
    try {
      final bool? result = await _channel.invokeMethod('deleteFile', {'path': path});
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to delete file at $path: '${e.message}'.");
      return false;
    }
  }

  /// Fetches hidden media like WhatsApp statuses.
  static Future<List<dynamic>> getWhatsAppHiddenMedia() async {
    try {
      final List<dynamic>? files = await _channel.invokeListMethod('getWhatsAppHiddenMedia');
      return files ?? [];
    } on PlatformException catch (e) {
      print("Failed to get WhatsApp hidden media: '${e.message}'.");
      return [];
    }
  }

  /// Moves a file from sourcePath to destPath
  static Future<bool> moveFile(String sourcePath, String destPath) async {
    try {
      final bool? result = await _channel.invokeMethod('moveFile', {
        'sourcePath': sourcePath,
        'destPath': destPath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to move file from $sourcePath to $destPath: '${e.message}'.");
      return false;
    }
  }

  /// Checks if an app is installed by package name
  static Future<bool> isAppInstalled(String packageName) async {
    try {
      final bool? result = await _channel.invokeMethod('isAppInstalled', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to check if app is installed $packageName: '${e.message}'.");
      return false;
    }
  }
}
