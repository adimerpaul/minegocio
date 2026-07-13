import 'package:google_sign_in/google_sign_in.dart';

import '../models/google_account.dart';

/// Servicio de autenticación con Google (google_sign_in v7).
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

  /// Abre el flujo de login con Google.
  /// Devuelve `null` si el usuario cancela.
  Future<GoogleAccount?> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return GoogleAccount(
        name: account.displayName ?? '',
        email: account.email,
        photoUrl: account.photoUrl,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
