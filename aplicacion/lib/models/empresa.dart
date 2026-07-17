import '../config/env.dart';

/// Empresa vinculada a la cuenta (tabla empresas del backend).
class Empresa {
  final int id;
  final String nombre;
  final String? nit;
  final String? telefono;
  final String? direccion;
  final String? correo;
  final String moneda;
  final String? logoUrl;

  const Empresa({
    required this.id,
    required this.nombre,
    this.nit,
    this.telefono,
    this.direccion,
    this.correo,
    this.moneda = 'BOB',
    this.logoUrl,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    final logo = json['logo_path'] as String?;

    return Empresa(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      nit: json['nit'] as String?,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      correo: json['correo'] as String?,
      moneda: (json['moneda'] as String?) ?? 'BOB',
      // El back guarda el logo como ruta relativa (/storage/logos/...).
      logoUrl: logo == null || logo.startsWith('http')
          ? logo
          : '${Env.apiUrl}$logo',
    );
  }

  /// Fila de la tabla `empresa` de la base local (SQLite del teléfono).
  Map<String, Object?> toDbMap() => {
        'id': id,
        'nombre': nombre,
        'nit': nit,
        'telefono': telefono,
        'direccion': direccion,
        'correo': correo,
        'moneda': moneda,
        'logo_url': logoUrl,
      };

  factory Empresa.fromDb(Map<String, Object?> row) => Empresa(
        id: row['id'] as int,
        nombre: row['nombre'] as String,
        nit: row['nit'] as String?,
        telefono: row['telefono'] as String?,
        direccion: row['direccion'] as String?,
        correo: row['correo'] as String?,
        moneda: (row['moneda'] as String?) ?? 'BOB',
        logoUrl: row['logo_url'] as String?,
      );
}
