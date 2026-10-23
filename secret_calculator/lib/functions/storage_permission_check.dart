import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

Future<void> storagePermissionCheck({
  required Function onPermissionGranted,
  required Function onPermissionDenied,
}) async {
  final ps = await PhotoManager.requestPermissionExtend();
  if (ps.hasAccess) {
    onPermissionGranted();
    return;
  }
  final photos = await Permission.photos.status;
  final videos = await Permission.videos.status;
  final storage = await Permission.storage.status;
  if (photos.isGranted || videos.isGranted || storage.isGranted) {
    onPermissionGranted();
    return;
  }
  final req = await [
    Permission.photos,
    Permission.videos,
    Permission.storage,
  ].request();
  if (req[Permission.photos]?.isGranted == true ||
      req[Permission.videos]?.isGranted == true ||
      req[Permission.storage]?.isGranted == true) {
    onPermissionGranted();
    return;
  }
  onPermissionDenied();
}
