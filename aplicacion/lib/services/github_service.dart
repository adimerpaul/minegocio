import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/github_perfil.dart';

/// Perfil público de un usuario de GitHub, vía la API pública de GitHub
/// (sin autenticación ni backend propio de por medio).
class GithubService {
  GithubService._();

  static final GithubService instance = GithubService._();

  Future<GithubPerfil> perfil(String usuario) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/users/$usuario'),
      headers: {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('GitHub respondió ${response.statusCode}.');
    }

    return GithubPerfil.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
