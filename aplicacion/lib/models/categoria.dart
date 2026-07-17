/// Categoría de productos (tabla categorias del backend).
class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;

  const Categoria({required this.id, required this.nombre, this.descripcion});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
      );
}
