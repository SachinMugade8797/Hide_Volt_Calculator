import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:secret_calculator/models/gallery_model.dart';
import 'package:secret_calculator/pages/setting_page.dart';
import 'package:secret_calculator/ui/colors.dart';

import '../functions/storage_permission_check.dart';
import '../widgets/perminssion_denied_snackbar.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  bool selectionEnabled = false;
  List<int> selectedVideoKeys = [];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !selectionEnabled,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Videos"),
          actions: [actionButton()],
        ),
        body: FutureBuilder<Box<Gallery>>(
          future: Hive.openBox('gallery'),
          builder: (context, galleryBoxSnapshot) {
            if (galleryBoxSnapshot.hasError) {
              return Center(
                child: Text(galleryBoxSnapshot.error.toString()),
              );
            }
            if (galleryBoxSnapshot.hasData && galleryBoxSnapshot.data != null) {
              return ValueListenableBuilder<Box<Gallery>>(
                valueListenable: galleryBoxSnapshot.data!.listenable(),
                builder: (context, galleryBox, child) {
                  final videos = galleryBox.values
                      .where((item) => item.type == 'video')
                      .toList();
                  if (videos.isEmpty) {
                    return const Center(child: Text("Add Videos Here!"));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      return videoGrid(context, videos[index],
                          selectedVideoKeys.contains(videos[index].key));
                    },
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            storagePermissionCheck(
              onPermissionGranted: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoPlayerPage(video: null),
                  ),
                );
              },
              onPermissionDenied: () => permissionDeniedSnackBar(context),
            );
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget actionButton() {
    if (selectedVideoKeys.isEmpty) {
      return IconButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        ),
        icon: const Icon(Icons.settings),
      );
    } else {
      return IconButton(
        onPressed: () {
          final box = Hive.box<Gallery>('gallery');
          for (var key in selectedVideoKeys) {
            box.delete(key);
          }
          selectionEnabled = false;
          selectedVideoKeys.clear();
          setState(() {});
        },
        icon: const Icon(Icons.delete),
      );
    }
  }

  GestureDetector videoGrid(
      BuildContext context, Gallery video, bool selected) {
    return GestureDetector(
      onTap: () {
        if (selectionEnabled) {
          selected
              ? selectedVideoKeys.remove(video.key)
              : selectedVideoKeys.add(video.key);
          if (selected && selectedVideoKeys.isEmpty) selectionEnabled = false;
          setState(() {});
          return;
        }
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (context) => VideoPlayerPage(video: video),
        );
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        selectionEnabled = true;
        selectedVideoKeys.add(video.key);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: selected ? Border.all(width: 2, color: secondaryColor) : null,
          image: DecorationImage(
            image: MemoryImage(video.thumbnailBytes),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.play_circle_fill, color: secondaryColor),
              ),
            ),
            if (selected)
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.check_circle, color: secondaryColor),
              ),
          ],
        ),
      ),
    );
  }

  void _clearSelection() {
    selectionEnabled = false;
    selectedVideoKeys.clear();
    setState(() {});
  }
}

class VideoPlayerPage extends StatelessWidget {
  final Gallery? video;
  const VideoPlayerPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    if (video == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Choose Videos"),
        ),
        body: const Center(child: Text("Video picker not added yet")),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [popUpMenu(context)],
      ),
      body: Center(
        child: Image.memory(
          video!.thumbnailBytes,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget popUpMenu(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          onTap: () {
            video!.delete();
            Navigator.pop(context);
          },
          child: menuItem(Icons.delete, "Delete", Colors.red),
        ),
      ],
      offset: const Offset(0, 50),
      color: mainColorDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 128),
    );
  }

  Widget menuItem(IconData iconData, String lable, [Color? color]) {
    return Row(
      children: [
        Icon(iconData, color: color),
        const Spacer(),
        Text(
          lable,
          style: TextStyle(
            color: color ?? Colors.white,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}