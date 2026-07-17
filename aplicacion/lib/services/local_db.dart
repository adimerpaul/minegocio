import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/empresa.dart';

/// Base de datos local del teléfono (SQLite con sqflite).
///
/// Guarda al usuario y su empresa para abrir la app sin pedir los datos de
/// nuevo, y una copia de la foto de perfil en el almacenamiento del equipo.
class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'minegocio.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuario(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            photo_url TEXT,
            photo_local TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE empresa(
            id INTEGER PRIMARY KEY,
            nombre TEXT NOT NULL,
            nit TEXT,
            telefono TEXT,
            direccion TEXT,
            correo TEXT,
            moneda TEXT NOT NULL DEFAULT 'BOB',
            logo_url TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  /// Guarda (o reemplaza) al usuario y su empresa. Es una app de una sola
  /// cuenta: siempre hay a lo sumo una fila en cada tabla.
  Future<void> guardarSesion(AppUser user) async {
    final db = await _database;

    await db.transaction((txn) async {
      await txn.delete('usuario');
      await txn.insert('usuario', user.toDbMap());

      await txn.delete('empresa');
      if (user.empresa != null) {
        await txn.insert('empresa', user.empresa!.toDbMap());
      }
    });
  }

  Future<void> guardarEmpresa(Empresa empresa) async {
    final db = await _database;

    await db.transaction((txn) async {
      await txn.delete('empresa');
      await txn.insert('empresa', empresa.toDbMap());
    });
  }

  /// Usuario guardado (con su empresa), o null si nadie inició sesión.
  Future<AppUser?> obtenerUsuario() async {
    final db = await _database;

    final usuarios = await db.query('usuario', limit: 1);
    if (usuarios.isEmpty) return null;

    final empresas = await db.query('empresa', limit: 1);
    final empresa = empresas.isEmpty ? null : Empresa.fromDb(empresas.first);

    var user = AppUser.fromDb(usuarios.first, empresa: empresa);

    // Si la copia local de la foto se borró del almacenamiento, se descarta.
    final local = user.photoLocal;
    if (local != null && !File(local).existsSync()) {
      user = AppUser.fromDb(
        {...usuarios.first, 'photo_local': null},
        empresa: empresa,
      );
    }

    return user;
  }

  /// Descarga la foto del usuario al almacenamiento del teléfono y guarda su
  /// ruta en la tabla usuario. Devuelve la ruta local, o null si falla
  /// (la sesión no depende de la foto).
  Future<String?> guardarFotoLocal(AppUser user) async {
    final url = user.photoUrl;
    if (url == null) return null;

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'avatar-${user.id}.webp'));
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final db = await _database;
      await db.update(
        'usuario',
        {'photo_local': file.path},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Borra los datos locales (cierre de sesión), incluida la copia de la foto.
  Future<void> limpiar() async {
    final db = await _database;

    final usuarios = await db.query('usuario', limit: 1);
    final local = usuarios.isEmpty
        ? null
        : usuarios.first['photo_local'] as String?;
    if (local != null) {
      try {
        final file = File(local);
        if (file.existsSync()) await file.delete();
      } catch (_) {
        // La foto puede no existir; no bloquea el cierre de sesión.
      }
    }

    await db.delete('usuario');
    await db.delete('empresa');
  }
}
