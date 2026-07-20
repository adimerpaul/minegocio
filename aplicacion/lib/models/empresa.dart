import '../config/env.dart';

/// Empresa vinculada a la cuenta (tabla empresas del backend).
class Empresa {
  final int id;
  final String nombre;
  final String? nit;
  final String? telefono;
  final String? codigoPais;
  final String? direccion;
  final String? correo;
  final String moneda;
  final String? logoUrl;
  final String? slugTienda;

  const Empresa({
    required this.id,
    required this.nombre,
    this.nit,
    this.telefono,
    this.codigoPais,
    this.direccion,
    this.correo,
    this.moneda = 'BOB',
    this.logoUrl,
    this.slugTienda,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    final logo = json['logo_path'] as String?;

    return Empresa(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      nit: json['nit'] as String?,
      telefono: json['telefono'] as String?,
      codigoPais: json['codigo_pais'] as String?,
      direccion: json['direccion'] as String?,
      correo: json['correo'] as String?,
      moneda: (json['moneda'] as String?) ?? 'BOB',
      slugTienda: json['slug_tienda'] as String?,
      // El back guarda el logo como ruta relativa (/storage/logos/...).
      logoUrl: logo == null || logo.startsWith('http')
          ? logo
          : '${Env.apiUrl}$logo',
    );
  }

  /// URL pública del catálogo (tienda en línea), o null si aún no tiene slug.
  String? get urlTienda => slugTienda == null ? null : '${Env.apiUrl}/tienda/$slugTienda';

  /// Fila de la tabla `empresa` de la base local (SQLite del teléfono).
  Map<String, Object?> toDbMap() => {
        'id': id,
        'nombre': nombre,
        'nit': nit,
        'telefono': telefono,
        'codigo_pais': codigoPais,
        'direccion': direccion,
        'correo': correo,
        'moneda': moneda,
        'logo_url': logoUrl,
        'slug_tienda': slugTienda,
      };

  factory Empresa.fromDb(Map<String, Object?> row) => Empresa(
        id: row['id'] as int,
        nombre: row['nombre'] as String,
        nit: row['nit'] as String?,
        telefono: row['telefono'] as String?,
        codigoPais: row['codigo_pais'] as String?,
        direccion: row['direccion'] as String?,
        correo: row['correo'] as String?,
        moneda: (row['moneda'] as String?) ?? 'BOB',
        logoUrl: row['logo_url'] as String?,
        slugTienda: row['slug_tienda'] as String?,
      );
}
