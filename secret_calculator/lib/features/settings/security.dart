import 'package:flutter/material.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  bool biometric = false;
  bool autoLock = true;
  bool intruderSelfie = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('AUTHENTICATION'),

          _settingTile(
            icon: Icons.pin_outlined,
            title: 'Change PIN',
            subtitle: 'Change your vault PIN',
            onTap: () {
              // Open Change PIN
            },
          ),

          const SizedBox(height: 10),

          _settingTile(
            icon: Icons.fingerprint,
            title: 'Biometric Unlock',
            subtitle: 'Use fingerprint or face unlock',
            trailing: Switch(
              value: biometric,
              onChanged: (value) {
                setState(() => biometric = value);
              },
            ),
          ),

          const SizedBox(height: 22),

          _sectionTitle('VAULT PROTECTION'),

          _settingTile(
            icon: Icons.timer_outlined,
            title: 'Auto Lock',
            subtitle: 'Automatically lock the vault',
            trailing: Switch(
              value: autoLock,
              onChanged: (value) {
                setState(() => autoLock = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          _settingTile(
            icon: Icons.camera_alt_outlined,
            title: 'Intruder Selfie',
            subtitle: 'Capture photo after failed attempts',
            trailing: Switch(
              value: intruderSelfie,
              onChanged: (value) {
                setState(() => intruderSelfie = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          _settingTile(
            icon: Icons.history,
            title: 'Failed Attempts',
            subtitle: 'View failed unlock attempts',
            onTap: () {
              // Open failed attempts
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF202020)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 23),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (trailing == null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}