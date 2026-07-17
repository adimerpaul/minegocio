import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF4632C)),
      ),
      home: const LoginView(),
    );
  }
}
