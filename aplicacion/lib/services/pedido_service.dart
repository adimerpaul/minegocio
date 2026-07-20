import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/pedido.dart';
import 'idioma_service.dart';

/// Ítem por registrar en un pedido manual desde la app.
class PedidoItemNuevo {
  final int productoId;
  final int cantidad;

  const PedidoItemNuevo({required this.productoId, required this.cantidad});
}

/// Servicio de pedidos: los que llegan de la tienda en línea pública y los
/// que se registran a mano desde la app (mismo endpoint, sin autenticación).
class PedidoService {
  PedidoService._();

  static final PedidoService instance = PedidoService._();

  /// GET /api/pedidos — los más recientes primero.
  Future<List<Pedido>> listar(String token) async {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/api/pedidos'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        trp('error.cargar_pedidos', {'codigo': '${response.statusCode}'}),
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return (json['pedidos'] as List)
        .map((p) => Pedido.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/pedidos — endpoint público (así lo usa también la tienda en
  /// línea); no requiere token, solo el id de la empresa.
  Future<Pedido> crear({
    required int empresaId,
    required List<PedidoItemNuevo> items,
    String? clienteNombre,
    String? clienteTelefono,
    String? direccion,
    String? notas,
  }) async {
    final response = await http
        .post(
          Uri.parse('${Env.apiUrl}/api/pedidos'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'empresa_id': empresaId,
            'cliente_nombre': ?clienteNombre,
            'cliente_telefono': ?clienteTelefono,
            'direccion': ?direccion,
            'notas': ?notas,
            'items': items
                .map((i) => {
                      'producto_id': i.productoId,
                      'cantidad': i.cantidad,
                    })
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(_mensajeDeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return Pedido.fromJson(json['pedido'] as Map<String, dynamic>);
  }

  /// PUT /api/pedidos/{id} — cambia el estado; al cancelar devuelve el
  /// stock, y si se reactiva desde cancelado lo vuelve a descontar.
  Future<Pedido> actualizarEstado({
    required String token,
    required int pedidoId,
    required String estado,
  }) async {
    final response = await http
        .put(
          Uri.parse('${Env.apiUrl}/api/pedidos/$pedidoId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'estado': estado}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(_mensajeDeError(response));
    }

    return Pedido.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
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
