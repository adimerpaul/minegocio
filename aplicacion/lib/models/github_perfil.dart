/// Perfil público de GitHub (GET https://api.github.com/users/{usuario}),
/// sin autenticación.
class GithubPerfil {
  final String usuario;
  final String? nombre;
  final String? bio;
  final String avatarUrl;
  final String urlPerfil;

  const GithubPerfil({
    required this.usuario,
    this.nombre,
    this.bio,
    required this.avatarUrl,
    required this.urlPerfil,
  });

  factory GithubPerfil.fromJson(Map<String, dynamic> json) => GithubPerfil(
        usuario: json['login'] as String,
        nombre: json['name'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String,
        urlPerfil: json['html_url'] as String,
      );
}
