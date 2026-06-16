import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:clutr/core/platform/storage_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class TrashItem {
  final String originalPath;
  final String trashedPath;
  final int deletedAt;

  TrashItem({
    required this.originalPath,
    required this.trashedPath,
    required this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
        'originalPath': originalPath,
        'trashedPath': trashedPath,
        'deletedAt': deletedAt,
      };

  factory TrashItem.fromJson(Map<String, dynamic> json) => TrashItem(
        originalPath: json['originalPath'],
        trashedPath: json['trashedPath'],
        deletedAt: json['deletedAt'],
      );
}

class TrashService {
  static const String _registryKey = 'trash_registry';
  static Directory? _trashDir;

  static Future<void> init() async {
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      _trashDir = Directory(p.join(extDir.path, '.clutr_trash'));
      if (!await _trashDir!.exists()) {
        await _trashDir!.create(recursive: true);
      }
    }
  }

  static Future<List<TrashItem>> getTrashItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? registryJson = prefs.getString(_registryKey);
    if (registryJson == null) return [];
    
    final List<dynamic> decodedList = json.decode(registryJson);
    return decodedList.map((e) => TrashItem.fromJson(e)).toList();
  }

  static Future<void> _saveRegistry(List<TrashItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_registryKey, encoded);
  }

  static Future<bool> moveToTrash(String filePath) async {
    if (_trashDir == null) await init();
    if (_trashDir == null) return false;

    final fileName = p.basename(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${timestamp}_$fileName';
    final destPath = p.join(_trashDir!.path, newFileName);

    final success = await StorageChannel.moveFile(filePath, destPath);
    if (success) {
      final items = await getTrashItems();
      items.add(TrashItem(
        originalPath: filePath,
        trashedPath: destPath,
        deletedAt: timestamp,
      ));
      await _saveRegistry(items);
      return true;
    }
    return false;
  }

  static Future<bool> restore(TrashItem item) async {
    final success = await StorageChannel.moveFile(item.trashedPath, item.originalPath);
    if (success) {
      final items = await getTrashItems();
      items.removeWhere((e) => e.trashedPath == item.trashedPath);
      await _saveRegistry(items);
      return true;
    }
    return false;
  }

  static Future<bool> permanentlyDelete(TrashItem item) async {
    final success = await StorageChannel.deleteFile(item.trashedPath);
    if (success) {
      final items = await getTrashItems();
      items.removeWhere((e) => e.trashedPath == item.trashedPath);
      await _saveRegistry(items);
      return true;
    }
    return false;
  }

  static Future<void> cleanExpiredItems(int maxDays) async {
    final items = await getTrashItems();
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxAgeMs = maxDays * 24 * 60 * 60 * 1000;
    
    final expiredItems = items.where((item) => (now - item.deletedAt) > maxAgeMs).toList();
    
    if (expiredItems.isEmpty) return;

    for (final item in expiredItems) {
      await StorageChannel.deleteFile(item.trashedPath);
    }
    
    items.removeWhere((item) => (now - item.deletedAt) > maxAgeMs);
    await _saveRegistry(items);
  }
}
