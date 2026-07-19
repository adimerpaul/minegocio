import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/categoria.dart';
import 'catalogo_service.dart';

/// Servicio de gestión de categorías (crear, editar, eliminar) contra la API.
class CategoriaService {
  CategoriaService._();

  static final CategoriaService instance = CategoriaService._();

  /// Crea una categoría en la empresa del usuario autenticado.
  Future<Categoria> crear({
    required String token,
    required Map<String, String> datos,
    File? imagen,
  }) async {
    final uri = Uri.parse('${Env.apiUrl}/api/categorias');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      ])
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
    final categoria = Categoria.fromJson(json['categoria'] as Map<String, dynamic>);

    await CatalogoService.instance.listar(token, refrescar: true);

    return categoria;
  }

  /// Actualiza una categoría existente.
  Future<Categoria> actualizar({
    required String token,
    required Categoria categoria,
    required Map<String, String> datos,
    File? imagen,
  }) async {
    final uri = Uri.parse('${Env.apiUrl}/api/categorias/${categoria.id}');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      ])
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
    final actualizada = Categoria.fromJson(json['categoria'] as Map<String, dynamic>);

    await CatalogoService.instance.listar(token, refrescar: true);

    return actualizada;
  }

  /// Elimina una categoría que no tenga productos asociados.
  Future<void> eliminar({
    required String token,
    required int categoriaId,
  }) async {
    final uri = Uri.parse('${Env.apiUrl}/api/categorias/$categoriaId');

    final response = await http.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_mensajeError(response));
    }

    await CatalogoService.instance.listar(token, refrescar: true);
  }

  String _mensajeError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // cuerpo no JSON
    }
    return 'No se pudo guardar la categoría (${response.statusCode}).';
  }
}
