import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/app_user.dart';
import 'local_db.dart';

/// Servicio HTTP de la empresa: registro (pantalla "Registra tu empresa")
/// y actualización (Configuración). Mantiene la copia local en SQLite.
class EmpresaService {
  EmpresaService._();

  static final EmpresaService instance = EmpresaService._();

  /// POST /api/empresas — crea la empresa y vincula la cuenta.
  /// Devuelve el usuario actualizado (ya con empresa).
  Future<AppUser> crearEmpresa({
    required String token,
    required AppUser user,
    required Map<String, String?> datos,
  }) {
    return _enviar(
      metodo: 'POST',
      uri: Uri.parse('${Env.apiUrl}/api/empresas'),
      token: token,
      user: user,
      datos: datos,
      esperado: 201,
    );
  }

  /// PUT /api/empresa — actualiza los datos de la empresa.
  Future<AppUser> actualizarEmpresa({
    required String token,
    required AppUser user,
    required Map<String, String?> datos,
  }) {
    return _enviar(
      metodo: 'PUT',
      uri: Uri.parse('${Env.apiUrl}/api/empresa'),
      token: token,
      user: user,
      datos: datos,
      esperado: 200,
    );
  }

  Future<AppUser> _enviar({
    required String metodo,
    required Uri uri,
    required String token,
    required AppUser user,
    required Map<String, String?> datos,
    required int esperado,
  }) async {
    final request = http.Request(metodo, uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode(datos..removeWhere((_, v) => v == null || v.isEmpty));

    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 15)),
    );

    if (response.statusCode != esperado) {
      throw Exception(_mensajeDeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final actualizado = AppUser.fromJson(
      json['user'] as Map<String, dynamic>,
    ).copyWith(photoLocal: user.photoLocal);

    await LocalDb.instance.guardarSesion(actualizado);

    return actualizado;
  }

  /// Extrae un mensaje legible de la respuesta de error de Laravel.
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
      // Cuerpo no JSON: se usa el mensaje genérico.
    }

    return 'El servidor respondió ${response.statusCode}.';
  }
}
