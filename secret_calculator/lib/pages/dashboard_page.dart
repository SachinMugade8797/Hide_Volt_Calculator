import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:secret_calculator/features/notes.dart';
import 'package:secret_calculator/features/private_browser.dart';
import 'package:secret_calculator/features/settings.dart';
import 'package:secret_calculator/features/video_page.dart';
import 'package:secret_calculator/features/documents.dart';
import 'package:secret_calculator/features/gallery_page.dart';
import 'package:secret_calculator/models/gallery_model.dart';
import 'package:secret_calculator/pages/deleted_page.dart';
import 'package:secret_calculator/pages/homepage.dart';
import 'package:secret_calculator/ui/colors.dart';

class VaultDashboardScreen extends StatelessWidget {
  const VaultDashboardScreen({super.key});

  Future<void> _lockVault(BuildContext context) async {
    final box = await Hive.openBox<String>('appPassword');
    final password = box.get('password') ?? '';
    if (context.mounted) {
      Fluttertoast.showToast(msg: "Vault locked");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(appPassword: password),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _openCamera(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: mainColorDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: secondaryColor),
                title: const Text("Take Photo", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    final box = await Hive.openBox<Gallery>('gallery');
                    box.add(Gallery(
                      type: 'image',
                      thumbnailBytes: bytes,
                      bytes: bytes,
                      dateTime: DateTime.now(),
                      localPath: image.path,
                    ));
                    Fluttertoast.showToast(msg: "Photo saved to vault", backgroundColor: Colors.green);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: secondaryColor),
                title: const Text("Record Video", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final picker = ImagePicker();
                  final video = await picker.pickVideo(source: ImageSource.camera);
                  if (video != null) {
                    final bytes = await video.readAsBytes();
                    final box = await Hive.openBox<Gallery>('gallery');
                    box.add(Gallery(
                      type: 'video',
                      thumbnailBytes: Uint8List(0),
                      bytes: bytes,
                      dateTime: DateTime.now(),
                      localPath: video.path,
                    ));
                    Fluttertoast.showToast(msg: "Video saved to vault", backgroundColor: Colors.green);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDownloads(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BrowserDownloadsPage(),
      ),
    );
  }

  void _openDeleted(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeletedPage(),
      ),
    );
  }

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
            onPressed: () => _lockVault(context),
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
                    children: [
                      _MainFeature(
                        icon: Icons.photo_library_outlined,
                        title: 'Photos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GalleryPage(),
                            ),
                          );
                        },
                      ),
                      _MainFeature(
                        icon: Icons.video_library_outlined,
                        title: 'Videos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VideoPage(),
                            ),
                          );
                        },
                      ),
                      _MainFeature(
                        icon: Icons.description_outlined,
                        title: 'Documents',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Documents(),
                            ),
                          );
                        },
                      ),
                      _MainFeature(
                        icon: Icons.note_alt_outlined,
                        title: 'Notes',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Notes(),
                            ),
                          );
                        },
                      ),
                      _MainFeature(
                        icon: Icons.language_outlined,
                        title: 'Private Browser',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivateBrowser(),
                            ),
                          );
                        },
                      ),
                      _MainFeature(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Settings(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                children: [
                  _FooterItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Camera',
                    onTap: () => _openCamera(context),
                  ),
                  _FooterItem(
                    icon: Icons.download_outlined,
                    title: 'Downloads',
                    onTap: () => _openDownloads(context),
                  ),
                  _FooterItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Lock',
                    onTap: () => _lockVault(context),
                  ),
                  _FooterItem(
                    icon: Icons.delete_outline_rounded,
                    title: 'Deleted',
                    onTap: () => _openDeleted(context),
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

class _MainFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MainFeature({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
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
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _FooterItem({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: SizedBox(
            width: 56,
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
          ),
        ),
      ),
    );
  }
}
