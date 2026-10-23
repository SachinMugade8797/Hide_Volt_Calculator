import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:secret_calculator/models/gallery_model.dart';
import 'package:secret_calculator/ui/colors.dart';

class ImageViewPage extends StatelessWidget {
  final Gallery image;
  const ImageViewPage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [popUpMenu(context)],
      ),
      body: Center(
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          panAxis: PanAxis.aligned,
          child: Hero(
            tag: image.key.toString(),
            child: Image.memory(image.bytes),
          ),
        ),
      ),
    );
  }

  Widget popUpMenu(BuildContext context) {
    return PopupMenuButton<int>(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          onTap: () async {
            final trashBox = await Hive.openBox<Gallery>('trash');
            trashBox.add(Gallery(
              type: image.type,
              thumbnailBytes: image.thumbnailBytes,
              bytes: image.bytes,
              dateTime: DateTime.now(),
              localPath: image.localPath,
            ));
            image.delete();
            Fluttertoast.showToast(msg: "Moved to trash");
            if (context.mounted) Navigator.pop(context);
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
          style: TextStyle(color: color ?? Colors.white),
        ),
        const Spacer(),
      ],
    );
  }
}
