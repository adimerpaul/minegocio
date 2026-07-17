import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/paleta.dart';
import 'views/root_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // La barra de navegación del sistema (Android) a juego con la app;
  // sin esto se veía con el color por defecto del teléfono (azul).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Paleta.blanco,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await dotenv.load(fileName: kReleaseMode ? '.env.production' : '.env');
  runApp(const MiNegocioApp());
}

class MiNegocioApp extends StatelessWidget {
  const MiNegocioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'miNegocio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Paleta.primario),
        scaffoldBackgroundColor: Paleta.fondo,
      ),
      home: const RootView(),
    );
  }
}
