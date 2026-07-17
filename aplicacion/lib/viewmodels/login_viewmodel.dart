import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

/// ViewModel del login: expone el estado y orquesta el AuthService.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthService? auth}) : _auth = auth ?? AuthService.instance;

  final AuthService _auth;

  bool loading = false;
  String? error;
  AppUser? account;

  Future<void> signIn() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _auth.signIn();
      if (result != null) {
        account = result.user;
        debugPrint('===== LOGIN GOOGLE =====');
        debugPrint('Nombre: ${result.user.name}');
        debugPrint('Correo: ${result.user.email}');
        debugPrint('Foto:   ${result.user.photoUrl}');
        debugPrint('Token:  ${result.token}');
        debugPrint('Nuevo:  ${result.isNew}');
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
