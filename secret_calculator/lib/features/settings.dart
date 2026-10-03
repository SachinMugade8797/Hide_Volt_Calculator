import 'package:flutter/material.dart';

import 'package:secret_calculator/pages/image_picker_page.dart';

import '../functions/storage_permission_check.dart';
import '../widgets/perminssion_denied_snackbar.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [

          _settingsTile(
            context,
            icon: Icons.security_outlined,
            title: "Security",
            subtitle: "PIN, biometric and auto-lock settings",
            onTap: () {
              // Open Security settings
            },
          ),

          const SizedBox(height: 6),

          _settingsTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: "Vault Settings",
            subtitle: "Manage private vault behavior",
            onTap: () {
              // Open Vault settings
            },
          ),

          const SizedBox(height: 6),

          _settingsTile(
            context,
            icon: Icons.language_outlined,
            title: "Private Browser",
            subtitle: "Search engine, cache and browsing data",
            onTap: () {
              // Open Browser settings
            },
          ),

          const SizedBox(height: 6),

          _settingsTile(
            context,
            icon: Icons.palette_outlined,
            title: "Appearance",
            subtitle: "Theme and app appearance",
            onTap: () {
              // Open Appearance settings
            },
          ),

          const SizedBox(height: 6),

          _settingsTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: "Notifications",
            subtitle: "Manage app notifications and alerts",
            onTap: () {
              // Open Notification settings
            },
          ),

          const SizedBox(height: 6),
          _settingsTile(
            context,
            icon: Icons.cloud_outlined,
            title: "Backup & Recovery",
            subtitle: "Backup and restore your private data",
            onTap: () {
              // Open Backup settings
            },
          ),

          const SizedBox(height: 6),

          _settingsTile(
            context,
            icon: Icons.storage_outlined,
            title: "Storage",
            subtitle: "Manage vault storage and cache",
            onTap: () {
              // Open Storage settings
            },
          ),

          const SizedBox(height: 6),

          _settingsTile(
            context,
            icon: Icons.tune_rounded,
            title: "App Settings",
            subtitle: "Calculator behavior and preferences",
            onTap: () {
              // Open App settings
            },
          ),

          const SizedBox(height: 6),

          _settingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: "About",
            subtitle: "Version, privacy and app information",
            onTap: () {
              // Open About page
            },
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // SECTION TITLE
  // ==================================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ==================================================================
  // SETTINGS TILE
  // ==================================================================

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF202020),
            ),
          ),
          child: Row(
            children: [
              // --------------------------------------------------------
              // ICON
              // --------------------------------------------------------

              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 14),

              // --------------------------------------------------------
              // TITLE + SUBTITLE
              // --------------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // --------------------------------------------------------
              // ARROW
              // --------------------------------------------------------

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
