import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:gixt_worker/Components/Toast.dart';
import 'package:gixt_worker/Components/inputs/Pick_Image.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:image_picker/image_picker.dart';

enum _TipoArchivo { imagen, pdf }

Future<File?> pickAndCropDoc(BuildContext context) async {
  final _TipoArchivo? tipo = await showModalBottomSheet<_TipoArchivo>(
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
              title: Text('Imagen (Cámara/Galería)',
                  style: TextStyle(color: colorWhite)),
              onTap: () => Navigator.pop(context, _TipoArchivo.imagen),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: colorWhite),
              title: Text('PDF',
                  style: TextStyle(color: colorWhite)),
              onTap: () => Navigator.pop(context, _TipoArchivo.pdf),
            ),
          ],
        ),
      );
    },
  );

  if (tipo == null) return null;

  File? archivo;

  // 📸 IMAGEN
  if (tipo == _TipoArchivo.imagen) {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
  );
 if (pickedFile == null) return null;
  return File(pickedFile.path);
  }

  // 📄 PDF
  if (tipo == _TipoArchivo.pdf) {
    final resultado = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (resultado == null || resultado.files.single.path == null) {
      return null;
    }

    archivo = File(resultado.files.single.path!);

    final int tamano = await archivo.length();

    // ⚠️ límite 10MB
    if (tamano > 10 * 1024 * 1024) {
      Toast(
        context,
        title: 'Archivo muy pesado',
        message: 'El PDF no debe superar los 10 MB',
        type: alert_type.advertencia,
      );
      return null;
    }

    return archivo;
  }

  return null;
}