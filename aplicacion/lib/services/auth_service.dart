import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../models/app_user.dart';

/// Resultado del login completo (Google + backend).
class AuthResult {
  final AppUser user;
  final String token;
  final bool isNew;

  const AuthResult({
    required this.user,
    required this.token,
    required this.isNew,
  });
}

/// Servicio único de autenticación: login con Google, verificación en el
/// backend Laravel y guardado de la sesión en el teléfono.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Client ID web (client_type 3) del proyecto Firebase mi-negocio-4e604.
  static const String _serverClientId =
      '922337090570-hugtos92g0quaqba260kilsau95d0uu4.apps.googleusercontent.com';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Flujo completo: login con Google → POST /api/auth/google → guarda el
  /// token de API y el usuario en shared_preferences.
  /// Devuelve `null` si el usuario cancela.
  Future<AuthResult?> signIn() async {
    await _ensureInitialized();

    final GoogleSignInAccount googleAccount;
    try {
      googleAccount = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final idToken = googleAccount.authentication.idToken;
    if (idToken == null) {
      await GoogleSignIn.instance.signOut();
      throw Exception('Google no devolvió el ID token.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${Env.apiUrl}/api/auth/google'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'El backend respondió ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final result = AuthResult(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
        isNew: json['is_new'] as bool,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_token', result.token);
      await prefs.setString('user', jsonEncode(json['user']));

      return result;
    } catch (_) {
      // Sin backend no hay sesión: se revierte el login de Google.
      await GoogleSignIn.instance.signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('user');

    await GoogleSignIn.instance.signOut();
  }
}
