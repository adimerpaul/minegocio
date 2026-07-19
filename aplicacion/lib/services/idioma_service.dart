import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

/// Idioma disponible según el backend (GET /api/languages).
class IdiomaDisponible {
  final String code;
  final String name;
  final String flag;
  final String version;

  const IdiomaDisponible({
    required this.code,
    required this.name,
    required this.flag,
    required this.version,
  });

  factory IdiomaDisponible.fromJson(Map<String, dynamic> json) {
    return IdiomaDisponible(
      code: json['code'] as String,
      name: json['name'] as String,
      flag: (json['flag'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
    );
  }
}

/// Traducciones controladas por el backend (tablas languages/translations).
///
/// La app descarga el mapa completo de un idioma una sola vez
/// (GET /api/translations/{code}), lo guarda en SharedPreferences y solo
/// vuelve a descargar cuando el backend publica otra versión (la versión
/// viaja en GET /api/languages). El español de fábrica va empaquetado en
/// assets/i18n/es.json como respaldo para el primer arranque sin conexión.
class IdiomaService extends ChangeNotifier {
  IdiomaService._();

  static final IdiomaService instance = IdiomaService._();

  static const String _kCodigo = 'idioma_codigo';
  static const String _kVersion = 'idioma_version';
  static const String _kMapa = 'idioma_mapa';

  String _codigo = 'es';
  Map<String, String> _mapa = {};
  Map<String, String> _respaldo = {};

  String get codigo => _codigo;

  /// Traduce una clave "grupo.clave". Si no existe, cae al español
  /// empaquetado y, en último caso, muestra la clave (para detectarla).
  String t(String clave) => _mapa[clave] ?? _respaldo[clave] ?? clave;

  /// Igual que [t] pero reemplaza parámetros `:nombre` en el texto.
  String tp(String clave, Map<String, String> parametros) {
    var texto = t(clave);
    parametros.forEach((k, v) => texto = texto.replaceAll(':$k', v));
    return texto;
  }

  /// Carga el respaldo empaquetado y el idioma guardado; luego intenta
  /// sincronizar con el backend sin bloquear el arranque.
  Future<void> inicializar() async {
    final crudo = await rootBundle.loadString('assets/i18n/es.json');
    _respaldo = Map<String, String>.from(jsonDecode(crudo) as Map);

    final prefs = await SharedPreferences.getInstance();
    _codigo = prefs.getString(_kCodigo) ?? 'es';

    final guardado = prefs.getString(_kMapa);
    if (guardado != null) {
      _mapa = Map<String, String>.from(jsonDecode(guardado) as Map);
    } else {
      _mapa = Map<String, String>.from(_respaldo);
    }

    // Sincronización en segundo plano: si hay versión nueva, se re-descarga.
    unawaited(sincronizar());
  }

  /// Idiomas activos del backend.
  Future<List<IdiomaDisponible>> idiomasDisponibles() async {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/api/languages'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        trp('error.idiomas', {'codigo': '${response.statusCode}'}),
      );
    }

    return (jsonDecode(response.body) as List)
        .map((j) => IdiomaDisponible.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Cambia el idioma: descarga todas sus traducciones, las guarda
  /// localmente y notifica para que toda la app se reconstruya.
  Future<void> cambiar(String codigo) async {
    await _descargar(codigo);
    notifyListeners();
  }

  /// Re-descarga el idioma actual solo si el backend tiene otra versión.
  Future<void> sincronizar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final versionLocal = prefs.getString(_kVersion);

      final idiomas = await idiomasDisponibles();
      final actual = idiomas.where((i) => i.code == _codigo).firstOrNull;
      if (actual == null) return;

      if (actual.version != versionLocal) {
        await _descargar(_codigo);
        notifyListeners();
      }
    } catch (_) {
      // Sin conexión: se sigue con lo guardado.
    }
  }

  Future<void> _descargar(String codigo) async {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/api/translations/$codigo'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        trp('error.traducciones', {'codigo': '${response.statusCode}'}),
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final mapa = Map<String, String>.from(json['translations'] as Map);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCodigo, codigo);
    await prefs.setString(_kVersion, (json['version'] as String?) ?? '');
    await prefs.setString(_kMapa, jsonEncode(mapa));

    _codigo = codigo;
    _mapa = mapa;
  }
}

/// Atajo global: `tr('venta.cobrar')`.
String tr(String clave) => IdiomaService.instance.t(clave);

/// Atajo global con parámetros: `trp('venta.total', {'monto': '50'})`.
String trp(String clave, Map<String, String> parametros) =>
    IdiomaService.instance.tp(clave, parametros);
