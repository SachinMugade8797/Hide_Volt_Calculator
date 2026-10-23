import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/gallery_model.dart';
import '../pages/setting_page.dart';
import '../ui/colors.dart';

class Documents extends StatefulWidget {
  const Documents({super.key});

  @override
  State<Documents> createState() => _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  bool selectionEnabled = false;
  List<int> selectedKeys = [];

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndHideDocuments() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;

    final box = Hive.box<Gallery>('gallery');
    int count = 0;

    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        box.add(Gallery(
          type: 'document',
          thumbnailBytes: Uint8List(0),
          bytes: bytes,
          dateTime: DateTime.now(),
          localPath: file.name,
        ));
        count++;
      } catch (_) {}
    }

    if (mounted) {
      Fluttertoast.showToast(
        msg: count > 0 ? "Hidden successfully" : "Failed to hide",
        backgroundColor: count > 0 ? Colors.green : null,
      );
    }
  }

  Future<void> _openDocument(Gallery doc) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${doc.localPath}');
      await file.writeAsBytes(doc.bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        Fluttertoast.showToast(msg: result.message);
      }
    } catch (_) {
      Fluttertoast.showToast(msg: "Could not open document");
    }
  }

  void _clearSelection() {
    selectionEnabled = false;
    selectedKeys.clear();
    setState(() {});
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx', 'txt', 'rtf'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx', 'csv'].contains(ext)) return Icons.table_chart;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !selectionEnabled,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Documents"),
          actions: [
            if (selectedKeys.isEmpty)
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ),
                icon: const Icon(Icons.settings),
              )
            else
              IconButton(
                onPressed: () {
                  final box = Hive.box<Gallery>('gallery');
                  for (final key in selectedKeys) {
                    box.delete(key);
                  }
                  _clearSelection();
                },
                icon: const Icon(Icons.delete),
              ),
          ],
        ),
        body: FutureBuilder<Box<Gallery>>(
          future: Hive.openBox('gallery'),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ValueListenableBuilder<Box<Gallery>>(
                valueListenable: snapshot.data!.listenable(),
                builder: (context, box, _) {
                  final docs = box.values.where((item) => item.type == 'document').toList();
                  if (docs.isEmpty) {
                    return const Center(child: Text("Add Documents Here!"));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final isSelected = selectedKeys.contains(doc.key);
                      return ListTile(
                        tileColor: isSelected ? secondaryColor.withValues(alpha: 0.2) : mainColorDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isSelected ? const BorderSide(color: secondaryColor, width: 1.5) : BorderSide.none,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: mainColor,
                          child: Icon(_fileIcon(doc.localPath), color: secondaryColor),
                        ),
                        title: Text(
                          doc.localPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${_formatSize(doc.bytes.length)} • ${doc.dateTime.day}/${doc.dateTime.month}/${doc.dateTime.year}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: secondaryColor) : null,
                        onTap: () {
                          if (selectionEnabled) {
                            setState(() {
                              isSelected ? selectedKeys.remove(doc.key) : selectedKeys.add(doc.key);
                              if (selectedKeys.isEmpty) selectionEnabled = false;
                            });
                          } else {
                            _openDocument(doc);
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            selectionEnabled = true;
                            selectedKeys.add(doc.key);
                          });
                        },
                      );
                    },
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickAndHideDocuments,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
