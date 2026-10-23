import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../pages/setting_page.dart';
import '../ui/colors.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  bool selectionEnabled = false;
  List<dynamic> selectedKeys = [];

  void _clearSelection() {
    selectionEnabled = false;
    selectedKeys.clear();
    setState(() {});
  }

  void _openNoteEditor([dynamic key, Map? note]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(noteKey: key, note: note),
      ),
    );
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
          title: const Text("Notes"),
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
                  final box = Hive.box('notes');
                  for (final key in selectedKeys) {
                    box.delete(key);
                  }
                  _clearSelection();
                },
                icon: const Icon(Icons.delete),
              ),
          ],
        ),
        body: FutureBuilder<Box>(
          future: Hive.openBox('notes'),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ValueListenableBuilder<Box>(
                valueListenable: snapshot.data!.listenable(),
                builder: (context, box, _) {
                  if (box.isEmpty) {
                    return const Center(child: Text("Add Notes Here!"));
                  }
                  final keys = box.keys.toList().reversed.toList();
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: keys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final key = keys[index];
                      final note = Map<String, dynamic>.from(box.get(key) ?? {});
                      final title = (note['title'] as String?)?.trim() ?? '';
                      final content = (note['content'] as String?)?.trim() ?? '';
                      final date = note['date'] != null ? DateTime.tryParse(note['date']) : null;
                      final isSelected = selectedKeys.contains(key);

                      return ListTile(
                        tileColor: isSelected ? secondaryColor.withValues(alpha: 0.2) : mainColorDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isSelected ? const BorderSide(color: secondaryColor, width: 1.5) : BorderSide.none,
                        ),
                        title: Text(
                          title.isNotEmpty ? title : 'Untitled Note',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (content.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            if (date != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: secondaryColor) : null,
                        onTap: () {
                          if (selectionEnabled) {
                            setState(() {
                              isSelected ? selectedKeys.remove(key) : selectedKeys.add(key);
                              if (selectedKeys.isEmpty) selectionEnabled = false;
                            });
                          } else {
                            _openNoteEditor(key, note);
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            selectionEnabled = true;
                            selectedKeys.add(key);
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
          onPressed: () => _openNoteEditor(),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  final dynamic noteKey;
  final Map? note;
  const NoteEditorPage({super.key, this.noteKey, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?['title'] ?? '');
    _contentController = TextEditingController(text: widget.note?['content'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final box = Hive.box('notes');
    final noteData = {
      'title': title,
      'content': content,
      'date': DateTime.now().toIso8601String(),
    };

    if (widget.noteKey != null) {
      box.put(widget.noteKey, noteData);
    } else {
      box.add(noteData);
    }

    Fluttertoast.showToast(msg: "Note saved");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteKey != null ? "Edit Note" : "New Note"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: secondaryColor),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Title",
                border: InputBorder.none,
                hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: "Write your private note...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
