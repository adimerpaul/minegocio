import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/empresa_service.dart';

/// ViewModel de la empresa: registro (pantalla "Registra tu empresa")
/// y actualización (Configuración).
class EmpresaViewModel extends ChangeNotifier {
  EmpresaViewModel({EmpresaService? service})
    : _service = service ?? EmpresaService.instance;

  final EmpresaService _service;

  bool loading = false;
  String? error;

  /// Crea la empresa y devuelve el usuario actualizado, o null si falla.
  Future<AppUser?> crear(Session session, Map<String, String?> datos) {
    return _ejecutar(
      () => _service.crearEmpresa(
        token: session.token,
        user: session.user,
        datos: datos,
      ),
    );
  }

  /// Actualiza la empresa (con [logo] también cambia su imagen) y
  /// devuelve el usuario actualizado, o null si falla.
  Future<AppUser?> actualizar(
    Session session,
    Map<String, String?> datos, {
    File? logo,
  }) {
    return _ejecutar(
      () => _service.actualizarEmpresa(
        token: session.token,
        user: session.user,
        datos: datos,
        logo: logo,
      ),
    );
  }

  Future<AppUser?> _ejecutar(Future<AppUser> Function() accion) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      return await accion();
    } catch (e) {
      error = '$e'.replaceFirst('Exception: ', '');
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
