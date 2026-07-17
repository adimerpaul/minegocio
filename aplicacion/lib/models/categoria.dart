import '../config/env.dart';

/// Categoría de productos (tabla categorias del backend).
class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    final imagen = json['imagen_path'] as String?;

    return Categoria(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      // El back guarda el banner como ruta relativa (/storage/categorias/...).
      imagenUrl: imagen == null || imagen.startsWith('http')
          ? imagen
          : '${Env.apiUrl}$imagen',
    );
  }
}
