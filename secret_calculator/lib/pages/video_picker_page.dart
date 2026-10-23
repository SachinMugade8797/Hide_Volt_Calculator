import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/gallery_model.dart';
import '../ui/colors.dart';

class VideoPickerPage extends StatefulWidget {
  const VideoPickerPage({super.key});

  @override
  State<VideoPickerPage> createState() => _VideoPickerPageState();
}

class _VideoPickerPageState extends State<VideoPickerPage> {
  List<AssetEntity> assets = [];
  final List<AssetEntity> selectedAssets = [];
  bool loading = true;
  bool hiding = false;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.video);
    if (albums.isNotEmpty) {
      final total = await albums[0].assetCountAsync;
      assets = await albums[0].getAssetListRange(start: 0, end: total);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _hideVideos() async {
    setState(() => hiding = true);
    final box = Hive.box<Gallery>('gallery');
    final existingPaths = box.values.map((e) => e.localPath).toSet();
    int count = 0;

    for (final asset in selectedAssets) {
      final file = await asset.loadFile();
      if (file != null && !existingPaths.contains(file.path)) {
        final thumb = await asset.thumbnailDataWithSize(const ThumbnailSize.square(256));
        box.add(Gallery(
          type: 'video',
          thumbnailBytes: thumb ?? Uint8List(0),
          bytes: file.readAsBytesSync(),
          dateTime: DateTime.now(),
          localPath: file.path,
        ));
        count++;
      }
    }

    if (mounted) {
      setState(() => hiding = false);
      Fluttertoast.showToast(
        msg: count > 0 ? "Hidden successfully" : "Skipped hiding",
        backgroundColor: count > 0 ? Colors.green : null,
      );
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Videos")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : assets.isEmpty
              ? const Center(child: Text("No videos found"))
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: assets.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 128,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    final isSelected = selectedAssets.contains(asset);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          isSelected ? selectedAssets.remove(asset) : selectedAssets.add(asset);
                        });
                      },
                      child: FutureBuilder<Uint8List?>(
                        future: asset.thumbnailDataWithSize(const ThumbnailSize.square(256)),
                        builder: (context, snapshot) {
                          return Container(
                            decoration: BoxDecoration(
                              border: isSelected ? Border.all(color: secondaryColor, width: 2) : null,
                              image: snapshot.data != null
                                  ? DecorationImage(
                                      image: MemoryImage(snapshot.data!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: mainColorDark,
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    color: Colors.black54,
                                    child: Text(
                                      _formatDuration(asset.duration),
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.check_circle, color: secondaryColor),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: selectedAssets.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: hiding ? null : _hideVideos,
              label: hiding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text("Hide Videos (${selectedAssets.length})"),
            )
          : null,
    );
  }
}
