import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/proveedor.dart';
import 'idioma_service.dart';

/// Servicio de gestión de proveedores, con caché en memoria para no repetir
/// la descarga al cambiar de módulo (se limpia al cerrar sesión).
class ProveedorService {
  ProveedorService._();

  static final ProveedorService instance = ProveedorService._();

  List<Proveedor>? _cache;

  Map<String, String> _headers(String token, {bool json = false}) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json',
      };

  /// GET /api/proveedores — el S/N primero y el resto en orden alfabético.
  Future<List<Proveedor>> listar(
    String token, {
    bool refrescar = false,
  }) async {
    if (!refrescar && _cache != null) return _cache!;

    final response = await http
        .get(
          Uri.parse('${Env.apiUrl}/api/proveedores'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        trp('error.cargar_proveedores', {'codigo': '${response.statusCode}'}),
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    _cache = (json['proveedores'] as List)
        .map((p) => Proveedor.fromJson(p as Map<String, dynamic>))
        .toList();

    return _cache!;
  }

  /// POST /api/proveedores — registra un proveedor.
  Future<Proveedor> crear({
    required String token,
    required Map<String, String?> datos,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Env.apiUrl}/api/proveedores'),
          headers: _headers(token, json: true),
          body: jsonEncode(datos),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_mensajeDeError(response));
    }

    _cache = null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Proveedor.fromJson(json['proveedor'] as Map<String, dynamic>);
  }

  /// PUT /api/proveedores/{id} — actualiza un proveedor.
  Future<Proveedor> actualizar({
    required String token,
    required int proveedorId,
    required Map<String, String?> datos,
  }) async {
    final response = await http
        .put(
          Uri.parse('${Env.apiUrl}/api/proveedores/$proveedorId'),
          headers: _headers(token, json: true),
          body: jsonEncode(datos),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_mensajeDeError(response));
    }

    _cache = null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Proveedor.fromJson(json['proveedor'] as Map<String, dynamic>);
  }

  /// DELETE /api/proveedores/{id} — borra (suave) un proveedor.
  Future<void> eliminar({
    required String token,
    required int proveedorId,
  }) async {
    final response = await http
        .delete(
          Uri.parse('${Env.apiUrl}/api/proveedores/$proveedorId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_mensajeDeError(response));
    }

    _cache = null;
  }

  /// Olvida la caché (por ejemplo al cerrar sesión).
  void limpiar() => _cache = null;

  String _mensajeDeError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final errors = json['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final primero = errors.values.first;
        if (primero is List && primero.isNotEmpty) return '${primero.first}';
      }
      final message = json['message'] as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // Cuerpo no JSON: mensaje genérico.
    }

    return trp('error.servidor', {'codigo': '${response.statusCode}'});
  }
}
