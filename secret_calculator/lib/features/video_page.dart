import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../functions/storage_permission_check.dart';
import '../models/gallery_model.dart';
import '../pages/setting_page.dart';
import '../pages/video_picker_page.dart';
import '../ui/colors.dart';
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
              return Center(child: Text(galleryBoxSnapshot.error.toString()));
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
                      return videoGrid(
                        context,
                        videos[index],
                        selectedVideoKeys.contains(videos[index].key),
                      );
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
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            storagePermissionCheck(
              onPermissionGranted: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoPickerPage(),
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
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        ),
        icon: const Icon(Icons.settings),
      );
    }
    return IconButton(
      onPressed: () async {
        final box = Hive.box<Gallery>('gallery');
        final trashBox = await Hive.openBox<Gallery>('trash');
        for (var key in selectedVideoKeys) {
          final item = box.get(key);
          if (item != null) {
            trashBox.add(Gallery(
              type: item.type,
              thumbnailBytes: item.thumbnailBytes,
              bytes: item.bytes,
              dateTime: DateTime.now(),
              localPath: item.localPath,
            ));
            box.delete(key);
          }
        }
        _clearSelection();
        Fluttertoast.showToast(msg: "Moved to trash");
      },
      icon: const Icon(Icons.delete),
    );
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(video: video),
          ),
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
  final Gallery video;
  const VideoPlayerPage({super.key, required this.video});

  Future<void> _playVideo(BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = video.localPath.split('.').last;
      final file = File('${dir.path}/temp_${video.key}.$ext');
      await file.writeAsBytes(video.bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        Fluttertoast.showToast(msg: result.message);
      }
    } catch (_) {
      Fluttertoast.showToast(msg: "Could not open video");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final trashBox = await Hive.openBox<Gallery>('trash');
              trashBox.add(Gallery(
                type: video.type,
                thumbnailBytes: video.thumbnailBytes,
                bytes: video.bytes,
                dateTime: DateTime.now(),
                localPath: video.localPath,
              ));
              video.delete();
              Fluttertoast.showToast(msg: "Moved to trash");
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (video.thumbnailBytes.isNotEmpty)
              Image.memory(
                video.thumbnailBytes,
                fit: BoxFit.contain,
              ),
            IconButton(
              iconSize: 72,
              icon: const Icon(Icons.play_circle_fill, color: secondaryColor),
              onPressed: () => _playVideo(context),
            ),
          ],
        ),
      ),
    );
  }
}
