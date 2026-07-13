import 'package:flutter/foundation.dart';

import '../models/google_account.dart';
import '../services/auth_service.dart';

/// ViewModel del login: expone el estado y orquesta el AuthService.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthService? auth}) : _auth = auth ?? AuthService.instance;

  final AuthService _auth;

  bool loading = false;
  String? error;
  GoogleAccount? account;

  Future<void> signIn() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _auth.signInWithGoogle();
      if (result != null) {
        account = result;
        debugPrint('===== LOGIN GOOGLE =====');
        debugPrint('Nombre: ${result.name}');
        debugPrint('Correo: ${result.email}');
        debugPrint('Foto:   ${result.photoUrl}');
        debugPrint('========================');
      }
    } catch (e) {
      error = 'No se pudo iniciar sesión: $e';
      debugPrint('Error de login: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    account = null;
    notifyListeners();
  }
}
