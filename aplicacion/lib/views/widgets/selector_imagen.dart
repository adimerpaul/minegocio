import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/paleta.dart';

/// Hoja inferior para elegir una imagen desde la cámara o la galería.
/// Devuelve el archivo elegido, o null si se cancela. Lanza una excepción
/// con mensaje legible si la cámara/galería falla (p. ej. sin permiso).
Future<File?> seleccionarImagen(BuildContext context) async {
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_camera, color: Paleta.primario),
            title: const Text('Tomar foto con la cámara'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Paleta.primario),
            title: const Text('Elegir de la galería / archivos'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (origen == null) return null;

  try {
    final foto = await ImagePicker().pickImage(
      source: origen,
      maxWidth: 1200,
      imageQuality: 85,
    );
    return foto == null ? null : File(foto.path);
  } catch (_) {
    throw Exception(
      origen == ImageSource.camera
          ? 'No se pudo usar la cámara. Revisa que la app tenga el '
                'permiso de cámara en los ajustes del teléfono.'
          : 'No se pudo abrir la galería.',
    );
  }
}
