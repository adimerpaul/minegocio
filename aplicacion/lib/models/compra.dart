/// Ítem de una compra (copia del nombre y costo al momento de comprar).
class CompraItem {
  final int id;
  final int? productoId;
  final String nombre;
  final double costo;
  final int cantidad;
  final double subtotal;

  const CompraItem({
    required this.id,
    this.productoId,
    required this.nombre,
    required this.costo,
    required this.cantidad,
    required this.subtotal,
  });

  factory CompraItem.fromJson(Map<String, dynamic> json) => CompraItem(
        id: json['id'] as int,
        productoId: json['producto_id'] as int?,
        nombre: json['nombre'] as String,
        costo: (json['costo'] as num).toDouble(),
        cantidad: (json['cantidad'] as num).toInt(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

/// Compra registrada (aumenta el inventario).
class Compra {
  final int id;
  final String codigo;
  final String proveedor;
  final double total;
  final String estado; // completada | anulada
  final DateTime fecha;
  final List<CompraItem> items;

  const Compra({
    required this.id,
    required this.codigo,
    required this.proveedor,
    required this.total,
    this.estado = 'completada',
    required this.fecha,
    required this.items,
  });

  bool get anulada => estado == 'anulada';

  int get cantidadItems => items.fold(0, (a, i) => a + i.cantidad);

  factory Compra.fromJson(Map<String, dynamic> json) => Compra(
        id: json['id'] as int,
        codigo: json['codigo'] as String,
        proveedor: (json['proveedor'] as String?) ?? 'S/N',
        total: (json['total'] as num).toDouble(),
        estado: (json['estado'] as String?) ?? 'completada',
        fecha: DateTime.parse(json['created_at'] as String).toLocal(),
        items: ((json['items'] as List?) ?? [])
            .map((i) => CompraItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}
