import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../models/app_user.dart';
import 'catalogo_service.dart';
import 'cliente_service.dart';
import 'local_db.dart';

/// Sesión activa: usuario (con su empresa, si la tiene) y token de API.
class Session {
  final AppUser user;
  final String token;

  const Session({required this.user, required this.token});

  Session copyWith({AppUser? user}) =>
      Session(user: user ?? this.user, token: token);
}

/// Resultado del login completo (Google + backend).
class AuthResult {
  final Session session;
  final bool isNew;

  const AuthResult({required this.session, required this.isNew});
}

/// Servicio único de autenticación: login con Google, verificación en el
/// backend Laravel y guardado de la sesión en el teléfono (token en
/// shared_preferences; usuario, empresa y copia de la foto en SQLite).
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

  /// Restaura la sesión guardada en el teléfono (sin pasar por Google ni el
  /// backend). Devuelve null si no hay sesión.
  Future<Session?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return null;

    final user = await LocalDb.instance.obtenerUsuario();
    if (user == null) return null;

    return Session(user: user, token: token);
  }

  /// Flujo completo: login con Google → POST /api/auth/google → guarda el
  /// token en shared_preferences y el usuario + empresa en SQLite, con una
  /// copia de la foto en el almacenamiento del teléfono.
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
      var user = AppUser.fromJson(json['user'] as Map<String, dynamic>);
      final token = json['token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_token', token);

      await LocalDb.instance.guardarSesion(user);

      // Copia local de la foto para recuperarla luego sin conexión.
      final fotoLocal = await LocalDb.instance.guardarFotoLocal(user);
      if (fotoLocal != null) {
        user = user.copyWith(photoLocal: fotoLocal);
      }

      return AuthResult(
        session: Session(user: user, token: token),
        isNew: json['is_new'] as bool,
      );
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

    await LocalDb.instance.limpiar();
    CatalogoService.instance.limpiar();
    ClienteService.instance.limpiar();

    await GoogleSignIn.instance.signOut();
  }
}
