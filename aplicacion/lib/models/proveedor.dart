/// Proveedor de la empresa. El "S/N" ([esDefault]) es el que usa la compra
/// cuando no se elige otro; no se edita ni se borra.
class Proveedor {
  final int id;
  final String nombre;
  final String? nit;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final bool esDefault;

  const Proveedor({
    required this.id,
    required this.nombre,
    this.nit,
    this.telefono,
    this.correo,
    this.direccion,
    this.esDefault = false,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        nit: json['nit'] as String?,
        telefono: json['telefono'] as String?,
        correo: json['correo'] as String?,
        direccion: json['direccion'] as String?,
        esDefault: json['es_default'] == true || json['es_default'] == 1,
      );

  /// Nombre para mostrar: el S/N se explica solo.
  String get etiqueta => esDefault ? 'S/N (sin proveedor)' : nombre;
}
