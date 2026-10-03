import 'package:flutter/material.dart';

class StorageSettings extends StatelessWidget {
  const StorageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _storageCard(),

          const SizedBox(height: 24),

          _title('STORAGE MANAGEMENT'),

          _tile(
            Icons.delete_sweep_outlined,
            'Clear Cache',
            'Remove temporary files',
            onTap: () {
              // Clear cache
            },
          ),

          const SizedBox(height: 10),

          _tile(
            Icons.delete_outline,
            'Deleted Items',
            'Manage permanently deleted files',
            onTap: () {
              // Open deleted items
            },
          ),

          const SizedBox(height: 10),

          _tile(
            Icons.cleaning_services_outlined,
            'Storage Cleanup',
            'Find files that can be removed',
            onTap: () {
              // Storage cleanup
            },
          ),
        ],
      ),
    );
  }

  Widget _storageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vault Storage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14),
          LinearProgressIndicator(value: 0.35),
          SizedBox(height: 10),
          Text(
            '0.0 GB used',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
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