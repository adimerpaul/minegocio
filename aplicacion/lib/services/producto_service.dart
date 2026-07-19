import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/producto.dart';
import 'catalogo_service.dart';
import 'idioma_service.dart';

/// Servicio de gestión de productos (actualización contra la API).
class ProductoService {
  ProductoService._();

  static final ProductoService instance = ProductoService._();

  /// Actualiza un producto y opcionalmente su imagen.
  ///
  /// Se envía como POST multipart con `_method=PUT` (PHP no parsea
  /// multipart en un PUT directo); Laravel lo enruta al PUT real.
  Future<Producto> actualizar({
    required String token,
    required Producto producto,
    required Map<String, String> datos,
    File? imagen,
  }) async {
    final uri = Uri.parse('${Env.apiUrl}/api/productos/${producto.id}');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..fields['_method'] = 'PUT'
      ..fields.addAll(datos);

    if (imagen != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagen.path),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(_mensajeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final actualizado = Producto.fromJson(
      json['producto'] as Map<String, dynamic>,
    );

    // Refresca la caché del catálogo para que los listados y Venta rápida
    // muestren el cambio.
    await CatalogoService.instance.listar(token, refrescar: true);

    return actualizado;
  }

  /// Crea un nuevo producto en la empresa del usuario autenticado.
  Future<Producto> crear({
    required String token,
    required Map<String, String> datos,
    File? imagen,
  }) async {
    final uri = Uri.parse('${Env.apiUrl}/api/productos');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..fields.addAll(datos);

    if (imagen != null) {
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagen.path),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 201) {
      throw Exception(_mensajeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final creado = Producto.fromJson(json['producto'] as Map<String, dynamic>);

    await CatalogoService.instance.listar(token, refrescar: true);

    return creado;
  }

  /// Mensaje legible del error de la API (validación o mensaje general).
  String _mensajeError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // cuerpo no JSON: se usa el mensaje genérico
    }
    return trp('error.guardar_producto', {'codigo': '${response.statusCode}'});
  }
}
