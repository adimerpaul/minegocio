import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/categoria.dart';
import '../models/producto.dart';

/// Catálogo de la empresa: categorías y productos.
class Catalogo {
  final List<Categoria> categorias;
  final List<Producto> productos;

  const Catalogo({required this.categorias, required this.productos});
}

/// Servicio del catálogo (GET /api/productos) con caché en memoria para no
/// repetir la descarga al cambiar de módulo.
class CatalogoService {
  CatalogoService._();

  static final CatalogoService instance = CatalogoService._();

  Catalogo? _cache;

  Future<Catalogo> listar(String token, {bool refrescar = false}) async {
    if (!refrescar && _cache != null) return _cache!;

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/api/productos'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el catálogo '
          '(${response.statusCode}).');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    _cache = Catalogo(
      categorias: (json['categorias'] as List)
          .map((c) => Categoria.fromJson(c as Map<String, dynamic>))
          .toList(),
      productos: (json['productos'] as List)
          .map((p) => Producto.fromJson(p as Map<String, dynamic>))
          .toList(),
    );

    return _cache!;
  }

  /// Olvida la caché (por ejemplo al cerrar sesión).
  void limpiar() => _cache = null;
}
