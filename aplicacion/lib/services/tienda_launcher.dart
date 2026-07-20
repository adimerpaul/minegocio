import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/empresa.dart';
import 'idioma_service.dart';

/// Abre la tienda en línea de la empresa en el navegador del teléfono.
/// Se usa desde el botón de tienda del shell principal y desde
/// Configuración > Tienda en línea.
Future<void> abrirTienda(BuildContext context, Empresa? empresa) async {
  final url = empresa?.urlTienda;
  if (url == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('config.tienda_inactiva'))),
    );
    return;
  }

  final abierto = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );

  if (!abierto && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('config.tienda_error'))),
    );
  }
}
