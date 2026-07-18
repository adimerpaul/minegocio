import '../config/env.dart';

/// Producto del catálogo (tabla productos del backend).
class Producto {
  final int id;
  final String codigo;
  final String? codigoBarras;
  final String nombre;
  final double precio;
  final int stock;
  final int stockMinimo;
  final int? categoriaId;
  final String? imagenUrl;

  const Producto({
    required this.id,
    required this.codigo,
    this.codigoBarras,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.stockMinimo = 5,
    this.categoriaId,
    this.imagenUrl,
  });

  /// El stock llegó al mínimo configurado para el producto.
  bool get stockBajo => stock <= stockMinimo;

  factory Producto.fromJson(Map<String, dynamic> json) {
    final imagen = json['imagen_path'] as String?;

    return Producto(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      codigoBarras: json['codigo_barras'] as String?,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      stockMinimo: ((json['stock_minimo'] as num?) ?? 5).toInt(),
      categoriaId: json['categoria_id'] as int?,
      // El back guarda la imagen como ruta relativa (/storage/productos/...).
      imagenUrl: imagen == null || imagen.startsWith('http')
          ? imagen
          : '${Env.apiUrl}$imagen',
    );
  }
}
