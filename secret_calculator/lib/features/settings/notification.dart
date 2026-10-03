import 'package:flutter/material.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool notifications = true;
  bool securityAlerts = true;
  bool downloadNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title('NOTIFICATIONS'),

          _tile(
            Icons.notifications_outlined,
            'Allow Notifications',
            'Enable app notifications',
            Switch(
              value: notifications,
              onChanged: (value) {
                setState(() => notifications = value);
              },
            ),
          ),

          const SizedBox(height: 22),

          _title('ALERTS'),

          _tile(
            Icons.security_outlined,
            'Security Alerts',
            'Receive security-related alerts',
            Switch(
              value: securityAlerts,
              onChanged: (value) {
                setState(() => securityAlerts = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          _tile(
            Icons.download_outlined,
            'Download Notifications',
            'Show download status notifications',
            Switch(
              value: downloadNotifications,
              onChanged: (value) {
                setState(() => downloadNotifications = value);
              },
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
      String subtitle,
      Widget trailing,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
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
      trailing: trailing,
    );
  }
}