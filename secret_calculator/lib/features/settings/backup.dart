import 'package:flutter/material.dart';

class BackupSettings extends StatelessWidget {
  const BackupSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Recovery'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title('BACKUP'),

          _tile(
            Icons.backup_outlined,
            'Create Backup',
            'Create a backup of your private data',
            onTap: () {
              // Create backup
            },
          ),

          const SizedBox(height: 10),

          _tile(
            Icons.restore_outlined,
            'Restore Backup',
            'Restore private data from a backup',
            onTap: () {
              // Restore backup
            },
          ),

          const SizedBox(height: 22),

          _title('CLOUD'),

          _tile(
            Icons.cloud_outlined,
            'Cloud Backup',
            'Manage encrypted cloud backups',
            onTap: () {
              // Open Cloud Backup
            },
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
      String subtitle, {
        required VoidCallback onTap,
      }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: const Color(0xFF121212),
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
      ),
    );
  }
}