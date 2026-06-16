import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:clutr/core/services/trash_service.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<TrashItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await TrashService.getTrashItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _restore(TrashItem item) async {
    final success = await TrashService.restore(item);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item restored successfully')),
      );
      _loadItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to restore item')),
      );
    }
  }

  Future<void> _permanentlyDelete(TrashItem item) async {
    final success = await TrashService.permanentlyDelete(item);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item permanently deleted')),
      );
      _loadItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Bin'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LOADING',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          letterSpacing: 4.0,
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'Trash is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final fileName = p.basename(item.originalPath);
                    final date = DateTime.fromMillisecondsSinceEpoch(item.deletedAt);
                    
                    return ListTile(
                      leading: _buildThumbnail(item.trashedPath),
                      title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Deleted: ${date.toLocal().toString().split('.')[0]}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const HugeIcon(icon: HugeIcons.strokeRoundedTime01, color: Colors.green),
                            onPressed: () => _restore(item),
                            tooltip: 'Restore',
                          ),
                          IconButton(
                            icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: Colors.red),
                            onPressed: () => _permanentlyDelete(item),
                            tooltip: 'Permanently Delete',
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildThumbnail(String path) {
    final isVideo = path.toLowerCase().endsWith('.mp4');
    if (isVideo) {
      return const HugeIcon(icon: HugeIcons.strokeRoundedVideo01, size: 40.0, color: Colors.grey);
    }
    return Image.file(
      File(path),
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const HugeIcon(icon: HugeIcons.strokeRoundedImageRemove01, size: 40.0, color: Colors.grey),
    );
  }
}
