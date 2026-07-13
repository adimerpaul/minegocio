/// Modelo mínimo del usuario que inició sesión con Google.
class GoogleAccount {
  final String name;
  final String email;
  final String? photoUrl;

  const GoogleAccount({
    required this.name,
    required this.email,
    this.photoUrl,
  });
}
