/// Cliente de la empresa. El cliente "S/N" (sin nombre, [esDefault]) es el
/// que usa la venta cuando no se elige otro; no se edita ni se borra.
class Cliente {
  final int id;
  final String nombre;
  final String? nit;
  final String? telefono;
  final String? correo;
  final String? direccion;
  final bool esDefault;

  const Cliente({
    required this.id,
    required this.nombre,
    this.nit,
    this.telefono,
    this.correo,
    this.direccion,
    this.esDefault = false,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        nit: json['nit'] as String?,
        telefono: json['telefono'] as String?,
        correo: json['correo'] as String?,
        direccion: json['direccion'] as String?,
        esDefault: json['es_default'] == true || json['es_default'] == 1,
      );

  /// Nombre para mostrar: el S/N se explica solo.
  String get etiqueta => esDefault ? 'S/N (sin nombre)' : nombre;
}
