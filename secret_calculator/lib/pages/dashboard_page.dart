import 'package:flutter/material.dart';

class VaultDashboardScreen extends StatelessWidget {
  const VaultDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Private Vault',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------------
            // MAIN FEATURES (pinned to the bottom, scrolls only if the
            // screen is too small, so it can never overflow)
            // ------------------------------------------------------------
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(18, 8, 10, 5),
                  child: GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _MainFeature(
                        icon: Icons.photo_library_outlined,
                        title: 'Photos',
                      ),
                      _MainFeature(
                        icon: Icons.video_library_outlined,
                        title: 'Videos',
                      ),
                      _MainFeature(
                        icon: Icons.description_outlined,
                        title: 'Documents',
                      ),
                      _MainFeature(
                        icon: Icons.note_alt_outlined,
                        title: 'Notes',
                      ),
                      _MainFeature(
                        icon: Icons.language_outlined,
                        title: 'Private Browser',
                      ),
                      _MainFeature(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ------------------------------------------------------------
            // FOOTER
            // ------------------------------------------------------------
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF101010),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF1D1D1D),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _FooterItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Camera',
                  ),
                  _FooterItem(
                    icon: Icons.download_outlined,
                    title: 'Downloads',
                  ),
                  _FooterItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Lock',
                  ),
                  _FooterItem(
                    icon: Icons.delete_outline_rounded,
                    title: 'Deleted',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// MAIN FEATURE
// ==========================================================================

class _MainFeature extends StatelessWidget {
  final IconData icon;
  final String title;

  const _MainFeature({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF202020),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 25,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8E8E8),
              fontSize: 12,
              height: 1.15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// FOOTER ITEM
// ==========================================================================

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FooterItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9E9E9E),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
