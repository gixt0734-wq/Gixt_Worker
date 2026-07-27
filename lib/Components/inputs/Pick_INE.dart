import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';



Future<File?> pickAndCropImage(BuildContext context) async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: colorprimario,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: colorWhite),
              title: Text('Cámara', style: TextStyle(color: colorWhite)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: colorWhite),
              title: Text('Galería', style: TextStyle(color: colorWhite)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );

  if (source == null) return null;

  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(
    source: source,
    imageQuality: 85,
  );

  if (pickedFile == null) return null;

  //  CÁMARA → RECORTE AUTOMÁTICO CUADRADO
  if (source == ImageSource.camera) {
    return File(pickedFile.path);
  }

  // GALERÍA → RECORTE MANUAL
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: pickedFile.path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Recortar imagen',
        toolbarColor: Colors.black,
        toolbarWidgetColor: Colors.white,
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
      ),
      IOSUiSettings(
        title: 'Recortar imagen',
        aspectRatioLockEnabled: true,
        aspectRatioPresets: [CropAspectRatioPreset.square],
      ),
    ],
  );

  if (croppedFile == null) return null;

  return File(croppedFile.path);
}