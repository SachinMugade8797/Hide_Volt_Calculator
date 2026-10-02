import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:secret_calculator/functions/selection_mixin.dart';
import 'package:secret_calculator/functions/vault_storage.dart';
import 'package:secret_calculator/models/vault_models.dart';
import 'package:secret_calculator/ui/colors.dart';

import '../functions/storage_permission_check.dart';
import '../widgets/perminssion_denied_snackbar.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage>
    with SelectionMixin<DocumentsPage> {
  final Box<DocumentItem> _box =
      Hive.box<DocumentItem>(VaultStorage.documentsBox);
  bool _importing = false;

  static const _allowed = [
    'pdf',
    'doc',
    'docx',
    'rtf',
    'txt',
    'xls',
    'xlsx',
    'csv',
    'ppt',
    'pptx',
  ];

  @override
  Widget build(BuildContext context) {
    return wrapPop(
      Scaffold(
        appBar: selectionEnabled
            ? buildSelectionAppBar(onDelete: _deleteSelected)
            : AppBar(title: const Text('Documents')),
        body: Column(
          children: [
            if (_importing) const LinearProgressIndicator(),
            Expanded(
              child: ValueListenableBuilder<Box<DocumentItem>>(
                valueListenable: _box.listenable(),
                builder: (context, box, _) {
                  final docs = box.values.toList().reversed.toList();
                  if (docs.isEmpty) {
                    return const Center(child: Text('Add Documents Here!'));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) => _tile(docs[i]),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: selectionEnabled || _importing
            ? null
            : FloatingActionButton(
                onPressed: () => storagePermissionCheck(
                  onPermissionGranted: _pickDocuments,
                  onPermissionDenied: () => permissionDeniedSnackBar(context),
                ),
                child: const Icon(Icons.add_rounded),
              ),
      ),
    );
  }

  Widget _tile(DocumentItem doc) {
    final selected = selectedKeys.contains(doc.key);
    final (icon, color) = _iconFor(doc.extension);
    return ListTile(
      selected: selected,
      selectedTileColor: secondaryColor.withOpacity(0.12),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${doc.extension.toUpperCase()} • ${VaultStorage.formatBytes(doc.sizeBytes)} • ${VaultStorage.formatDate(doc.addedAt)}',
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: secondaryColor)
          : null,
      onTap: () => selectionEnabled ? toggleSelection(doc.key) : _open(doc),
      onLongPress: () => startSelection(doc.key),
    );
  }

  (IconData, Color) _iconFor(String ext) {
    return switch (ext) {
      'pdf' => (Icons.picture_as_pdf_outlined, Colors.redAccent),
      'doc' || 'docx' || 'rtf' => (
          Icons.description_outlined,
          Colors.blueAccent
        ),
      'xls' || 'xlsx' || 'csv' => (Icons.table_chart_outlined, Colors.green),
      'ppt' || 'pptx' => (Icons.slideshow_outlined, Colors.orange),
      _ => (Icons.insert_drive_file_outlined, Colors.grey),
    };
  }

  Future<void> _open(DocumentItem doc) async {
    final result = await OpenFilex.open(doc.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No app found to open .${doc.extension} files')),
      );
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowed,
      allowMultiple: true,
    );
    if (result == null) return;

    setState(() => _importing = true);
    try {
      for (final file in result.files) {
        final source = file.path;
        if (source == null) continue;
        final saved = await VaultStorage.importFile(source, 'documents');
        await _box.add(DocumentItem(
          path: saved,
          name: file.name,
          extension: p.extension(file.name).replaceFirst('.', '').toLowerCase(),
          sizeBytes: file.size,
          addedAt: DateTime.now(),
        ));
      }
      await FilePicker.platform.clearTemporaryFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _deleteSelected() async {
    if (!await confirmDelete()) return;
    for (final key in selectedKeys.toList()) {
      final item = _box.get(key);
      if (item != null) await VaultStorage.deleteFile(item.path);
      await _box.delete(key);
    }
    if (mounted) clearSelection();
  }
}
