import 'package:flutter/material.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  bool sound = true;
  bool vibration = true;

  String decimalPrecision = 'Auto';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title('CALCULATOR'),

          _tile(
            Icons.volume_up_outlined,
            'Calculator Sound',
            'Play sound when pressing buttons',
            Switch(
              value: sound,
              onChanged: (value) {
                setState(() => sound = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          _tile(
            Icons.vibration_outlined,
            'Button Vibration',
            'Vibrate when pressing calculator buttons',
            Switch(
              value: vibration,
              onChanged: (value) {
                setState(() => vibration = value);
              },
            ),
          ),

          const SizedBox(height: 22),

          _title('CALCULATION'),

          _tile(
            Icons.calculate_outlined,
            'Decimal Precision',
            decimalPrecision,
          ),

          const SizedBox(height: 22),

          _title('APP BEHAVIOR'),

          _tile(
            Icons.home_outlined,
            'Default Screen',
            'Choose the screen shown when the app opens',
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
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
          ),
    );
  }
}