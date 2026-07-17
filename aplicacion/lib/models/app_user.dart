import '../config/env.dart';
import 'empresa.dart';

/// Usuario devuelto por el backend, con su empresa (si ya la registró)
/// y la copia local de su foto guardada en el teléfono.
class AppUser {
  final int id;
  final String name;
  final String email;
  final String? photoUrl;

  /// Ruta de la copia de la foto guardada en el almacenamiento del teléfono.
  final String? photoLocal;

  final Empresa? empresa;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.photoLocal,
    this.empresa,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final photo = json['photo_url'] as String?;
    final empresaJson = json['empresa'] as Map<String, dynamic>?;

    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      // El back guarda la foto como ruta relativa (/storage/avatars/...).
      photoUrl: photo == null || photo.startsWith('http')
          ? photo
          : '${Env.apiUrl}$photo',
      empresa: empresaJson == null ? null : Empresa.fromJson(empresaJson),
    );
  }

  AppUser copyWith({String? photoLocal, Empresa? empresa}) => AppUser(
        id: id,
        name: name,
        email: email,
        photoUrl: photoUrl,
        photoLocal: photoLocal ?? this.photoLocal,
        empresa: empresa ?? this.empresa,
      );

  /// Fila de la tabla `usuario` de la base local (SQLite del teléfono).
  Map<String, Object?> toDbMap() => {
        'id': id,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'photo_local': photoLocal,
      };

  factory AppUser.fromDb(Map<String, Object?> row, {Empresa? empresa}) =>
      AppUser(
        id: row['id'] as int,
        name: row['name'] as String,
        email: row['email'] as String,
        photoUrl: row['photo_url'] as String?,
        photoLocal: row['photo_local'] as String?,
        empresa: empresa,
      );
}
