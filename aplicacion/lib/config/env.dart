import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración leída de .env / .env.production.
class Env {
  Env._();

  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000';
}
