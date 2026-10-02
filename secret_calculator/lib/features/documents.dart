import 'package:flutter/material.dart';
import 'package:secret_calculator/pages/image_picker_page.dart';
import '../functions/storage_permission_check.dart';
import '../widgets/perminssion_denied_snackbar.dart';

class Documents extends StatelessWidget {
  const Documents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Documents"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          storagePermissionCheck(
            onPermissionGranted: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImagePickerPage(),
                ),
              );
            },
            onPermissionDenied: () => permissionDeniedSnackBar(context),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
