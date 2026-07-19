import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/compra.dart';
import 'idioma_service.dart';

/// Ítem por registrar en una compra: un producto del catálogo
/// ([productoId], aumenta stock) o un gasto libre (solo [nombre]:
/// aceite, gas, bolsas…), con cantidad y costo unitario.
class CompraItemNuevo {
  final int? productoId;
  final String? nombre;
  final int cantidad;
  final double costo;

  const CompraItemNuevo({
    this.productoId,
    this.nombre,
    required this.cantidad,
    required this.costo,
  });
}

/// Servicio de compras: registrar (aumenta stock), listar y anular.
class CompraService {
  CompraService._();

  static final CompraService instance = CompraService._();

  /// GET /api/compras — las más recientes primero.
  Future<List<Compra>> listar(String token) async {
    final response = await http
        .get(
          Uri.parse('${Env.apiUrl}/api/compras'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        trp('error.cargar_compras', {'codigo': '${response.statusCode}'}),
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return (json['compras'] as List)
        .map((c) => Compra.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/compras — registra la compra y aumenta el stock.
  /// Sin [proveedorId] el backend usa el proveedor S/N de la empresa.
  Future<Compra> crear({
    required String token,
    required List<CompraItemNuevo> items,
    int? proveedorId,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Env.apiUrl}/api/compras'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'proveedor_id': ?proveedorId,
            'items': items
                .map((i) => {
                      'producto_id': ?i.productoId,
                      'nombre': ?i.nombre,
                      'cantidad': i.cantidad,
                      'costo': i.costo,
                    })
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_mensajeDeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return Compra.fromJson(json['compra'] as Map<String, dynamic>);
  }

  /// POST /api/compras/{id}/anular — anula la compra y descuenta el stock.
  Future<Compra> anular({required String token, required int compraId}) async {
    final response = await http
        .post(
          Uri.parse('${Env.apiUrl}/api/compras/$compraId/anular'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_mensajeDeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return Compra.fromJson(json['compra'] as Map<String, dynamic>);
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
