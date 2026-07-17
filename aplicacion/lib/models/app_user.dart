import '../config/env.dart';

/// Usuario devuelto por el backend (tabla users de SQLite).
class AppUser {
  final int id;
  final String name;
  final String email;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final photo = json['photo_url'] as String?;

    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      // El back guarda la foto como ruta relativa (/storage/avatars/...).
      photoUrl: photo == null || photo.startsWith('http')
          ? photo
          : '${Env.apiUrl}$photo',
    );
  }
}
