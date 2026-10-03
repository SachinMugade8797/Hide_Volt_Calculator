import 'package:flutter/material.dart';

class VaultSettings extends StatefulWidget {
  const VaultSettings({super.key});

  @override
  State<VaultSettings> createState() => _VaultSettingsState();
}

class _VaultSettingsState extends State<VaultSettings> {
  bool moveInsteadOfCopy = false;
  bool showHiddenFiles = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title('IMPORT SETTINGS'),

          _tile(
            Icons.file_copy_outlined,
            'Move Files',
            'Remove the original after importing',
            Switch(
              value: moveInsteadOfCopy,
              onChanged: (value) {
                setState(() => moveInsteadOfCopy = value);
              },
            ),
          ),

          const SizedBox(height: 22),

          _title('VAULT'),

          _tile(
            Icons.visibility_outlined,
            'Show Hidden Files',
            'Display hidden vault files',
            Switch(
              value: showHiddenFiles,
              onChanged: (value) {
                setState(() => showHiddenFiles = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          _tile(
            Icons.delete_outline,
            'Deleted Items',
            'Manage deleted private files',
          ),

          const SizedBox(height: 10),

          _tile(
            Icons.folder_outlined,
            'Default Folder',
            'Choose default vault folder',
          ),
        ],
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _tile(
      IconData icon,
      String title,
      String subtitle, [
        Widget? trailing,
        VoidCallback? onTap,
      ]) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: const Color(0xFF121212),
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
          ),
    );
  }
}