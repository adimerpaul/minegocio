import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// ViewModel del login: expone el estado y orquesta el AuthService.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthService? auth}) : _auth = auth ?? AuthService.instance;

  final AuthService _auth;

  bool loading = false;
  String? error;

  /// Inicia sesión y devuelve la sesión lista, o null si el usuario cancela.
  Future<Session?> signIn() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _auth.signIn();
      return result?.session;
    } catch (e) {
      error = 'No se pudo iniciar sesión: $e';
      debugPrint('Error de login: $e');
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
