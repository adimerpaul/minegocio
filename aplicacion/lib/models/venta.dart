/// Ítem de una venta (copia del nombre y precio al momento de vender).
class VentaItem {
  final int id;
  final int? productoId;
  final String nombre;
  final double precio;
  final int cantidad;
  final double subtotal;

  const VentaItem({
    required this.id,
    this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
  });

  factory VentaItem.fromJson(Map<String, dynamic> json) => VentaItem(
        id: json['id'] as int,
        productoId: json['producto_id'] as int?,
        nombre: json['nombre'] as String,
        precio: (json['precio'] as num).toDouble(),
        cantidad: (json['cantidad'] as num).toInt(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

/// Venta registrada desde el punto de venta.
class Venta {
  final int id;
  final String codigo;
  final String? cliente;
  final double total;
  final String estado; // completada | anulada
  final DateTime fecha;
  final List<VentaItem> items;

  const Venta({
    required this.id,
    required this.codigo,
    this.cliente,
    required this.total,
    this.estado = 'completada',
    required this.fecha,
    required this.items,
  });

  bool get anulada => estado == 'anulada';

  int get cantidadItems => items.fold(0, (a, i) => a + i.cantidad);

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
        id: json['id'] as int,
        codigo: json['codigo'] as String,
        cliente: json['cliente'] as String?,
        total: (json['total'] as num).toDouble(),
        estado: (json['estado'] as String?) ?? 'completada',
        fecha: DateTime.parse(json['created_at'] as String).toLocal(),
        items: ((json['items'] as List?) ?? [])
            .map((i) => VentaItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}
