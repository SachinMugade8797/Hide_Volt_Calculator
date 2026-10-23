import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/gallery_model.dart';
import '../ui/colors.dart';

class DeletedPage extends StatelessWidget {
  const DeletedPage({super.key});

  void _restoreItem(Box<Gallery> trashBox, Gallery item) async {
    if (item.type == 'note') {
      try {
        final noteData = jsonDecode(utf8.decode(item.bytes));
        final notesBox = await Hive.openBox('notes');
        notesBox.add(noteData);
      } catch (_) {}
    } else {
      final galleryBox = await Hive.openBox<Gallery>('gallery');
      galleryBox.add(Gallery(
        type: item.type,
        thumbnailBytes: item.thumbnailBytes,
        bytes: item.bytes,
        dateTime: DateTime.now(),
        localPath: item.localPath,
      ));
    }
    item.delete();
    Fluttertoast.showToast(msg: "Restored to vault");
  }

  void _deleteForever(Gallery item) {
    item.delete();
    Fluttertoast.showToast(msg: "Permanently deleted");
  }

  void _confirmEmptyTrash(BuildContext context, Box<Gallery> box) {
    if (box.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: mainColorDark,
        title: const Text("Empty Trash?"),
        content: const Text("All items in trash will be permanently deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              box.clear();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Trash emptied");
            },
            child: const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _leadingIcon(Gallery item) {
    if (item.type == 'image' && (item.thumbnailBytes.isNotEmpty || item.bytes.isNotEmpty)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          item.thumbnailBytes.isNotEmpty ? item.thumbnailBytes : item.bytes,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    if (item.type == 'video' && item.thumbnailBytes.isNotEmpty) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(item.thumbnailBytes, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const Icon(Icons.play_circle_fill, color: secondaryColor, size: 20),
        ],
      );
    }
    IconData icon = Icons.insert_drive_file;
    if (item.type == 'note') icon = Icons.note_alt_outlined;
    if (item.type == 'document') icon = Icons.description_outlined;
    return CircleAvatar(
      backgroundColor: mainColor,
      child: Icon(icon, color: secondaryColor),
    );
  }

  String _itemTitle(Gallery item) {
    if (item.type == 'note') return item.localPath.isNotEmpty ? item.localPath : 'Deleted Note';
    if (item.type == 'document') return item.localPath;
    if (item.type == 'video') return 'Video (${item.dateTime.day}/${item.dateTime.month})';
    return 'Photo (${item.dateTime.day}/${item.dateTime.month})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deleted Items"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: "Empty Trash",
            onPressed: () async {
              final box = await Hive.openBox<Gallery>('trash');
              if (context.mounted) _confirmEmptyTrash(context, box);
            },
          ),
        ],
      ),
      body: FutureBuilder<Box<Gallery>>(
        future: Hive.openBox<Gallery>('trash'),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ValueListenableBuilder<Box<Gallery>>(
              valueListenable: snapshot.data!.listenable(),
              builder: (context, box, _) {
                final items = box.values.toList().reversed.toList();
                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("Trash is empty", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      tileColor: mainColorDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: _leadingIcon(item),
                      title: Text(
                        _itemTitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Deleted on ${item.dateTime.day}/${item.dateTime.month}/${item.dateTime.year}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore_rounded, color: secondaryColor),
                            tooltip: "Restore",
                            onPressed: () => _restoreItem(box, item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                            tooltip: "Delete Forever",
                            onPressed: () => _deleteForever(item),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
