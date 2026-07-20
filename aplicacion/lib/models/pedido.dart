/// Ítem de un pedido (copia del nombre y precio al momento de pedir).
class PedidoItem {
  final int id;
  final int? productoId;
  final String nombre;
  final double precio;
  final int cantidad;
  final double subtotal;

  const PedidoItem({
    required this.id,
    this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
  });

  factory PedidoItem.fromJson(Map<String, dynamic> json) => PedidoItem(
        id: json['id'] as int,
        productoId: json['producto_id'] as int?,
        nombre: json['nombre'] as String,
        precio: (json['precio'] as num).toDouble(),
        cantidad: (json['cantidad'] as num).toInt(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

/// Pedido de la tienda en línea (o registrado a mano desde la app).
/// estado: pendiente | confirmado | entregado | cancelado.
class Pedido {
  final int id;
  final String? clienteNombre;
  final String? clienteTelefono;
  final String? direccion;
  final String? notas;
  final double total;
  final String estado;
  final DateTime fecha;
  final List<PedidoItem> items;

  const Pedido({
    required this.id,
    this.clienteNombre,
    this.clienteTelefono,
    this.direccion,
    this.notas,
    required this.total,
    this.estado = 'pendiente',
    required this.fecha,
    required this.items,
  });

  bool get pendiente => estado == 'pendiente';
  bool get cancelado => estado == 'cancelado';
  bool get entregado => estado == 'entregado';

  int get cantidadItems => items.fold(0, (a, i) => a + i.cantidad);

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        id: json['id'] as int,
        clienteNombre: json['cliente_nombre'] as String?,
        clienteTelefono: json['cliente_telefono'] as String?,
        direccion: json['direccion'] as String?,
        notas: json['notas'] as String?,
        total: (json['total'] as num).toDouble(),
        estado: (json['estado'] as String?) ?? 'pendiente',
        fecha: DateTime.parse(json['created_at'] as String).toLocal(),
        items: ((json['items'] as List?) ?? [])
            .map((i) => PedidoItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}
