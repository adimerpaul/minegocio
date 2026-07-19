import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/venta.dart';
import 'idioma_service.dart';

/// Servicio de ventas: registrar desde el punto de venta y listar.
class VentaService {
  VentaService._();

  static final VentaService instance = VentaService._();

  /// GET /api/ventas — las más recientes primero.
  Future<List<Venta>> listar(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/api/ventas'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        trp('error.cargar_ventas', {'codigo': '${response.statusCode}'}),
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return (json['ventas'] as List)
        .map((v) => Venta.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/ventas — registra la venta y descuenta el stock.
  /// [orden] es productoId → cantidad. Sin [clienteId] el backend usa el
  /// cliente S/N (sin nombre) de la empresa.
  Future<Venta> crear({
    required String token,
    required Map<int, int> orden,
    int? clienteId,
    String? cliente,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Env.apiUrl}/api/ventas'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'cliente_id': ?clienteId,
            if (cliente != null && cliente.isNotEmpty) 'cliente': cliente,
            'items': orden.entries
                .map((e) => {'producto_id': e.key, 'cantidad': e.value})
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_mensajeDeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return Venta.fromJson(json['venta'] as Map<String, dynamic>);
  }

  /// POST /api/ventas/{id}/anular — anula la venta y devuelve el stock.
  Future<Venta> anular({required String token, required int ventaId}) async {
    final response = await http.post(
      Uri.parse('${Env.apiUrl}/api/ventas/$ventaId/anular'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_mensajeDeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return Venta.fromJson(json['venta'] as Map<String, dynamic>);
  }

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
