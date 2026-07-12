import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Maneja el inicio de sesión con Google a través de Firebase Auth.
///
/// En Android el `serverClientId` (el "Web client ID" de Firebase) se lee
/// automáticamente de google-services.json. Si el login falla con un error
/// de configuración, pásalo explícitamente en [init].
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  /// Usuario actual de Firebase (null si no hay sesión).
  User? get currentUser => _auth.currentUser;

  /// Cambios de sesión: emite el usuario al iniciar sesión y null al cerrarla.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Debe llamarse una vez antes de usar [signInWithGoogle].
  Future<void> init({String? serverClientId}) async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  /// Abre el selector de cuentas de Google y crea la sesión en Firebase.
  ///
  /// Devuelve el [User] autenticado, o null si el usuario canceló.
  /// Lanza [AuthException] con un mensaje legible si algo falla.
  Future<User?> signInWithGoogle() async {
    await init();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthException('No se pudo iniciar sesión con Google (${e.code.name}).');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw AuthException('Google no devolvió credenciales válidas.');
    }

    try {
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Error de autenticación con Firebase.');
    }
  }

  /// Cierra la sesión en Firebase y en Google.
  Future<void> signOut() async {
    await _auth.signOut();
    if (_initialized) {
      await _googleSignIn.signOut();
    }
  }
}

/// Error de autenticación con mensaje apto para mostrar al usuario.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
