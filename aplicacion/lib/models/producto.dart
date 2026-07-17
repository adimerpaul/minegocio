import '../config/env.dart';

/// Producto del catálogo (tabla productos del backend).
class Producto {
  final int id;
  final String codigo;
  final String nombre;
  final double precio;
  final int stock;
  final int? categoriaId;
  final String? imagenUrl;

  const Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.categoriaId,
    this.imagenUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final imagen = json['imagen_path'] as String?;

    return Producto(
      id: json['id'] as int,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      categoriaId: json['categoria_id'] as int?,
      // El back guarda la imagen como ruta relativa (/storage/productos/...).
      imagenUrl: imagen == null || imagen.startsWith('http')
          ? imagen
          : '${Env.apiUrl}$imagen',
    );
  }
}
