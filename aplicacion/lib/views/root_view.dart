import 'package:flutter/material.dart';

import '../config/paleta.dart';
import '../services/auth_service.dart';
import 'home_view.dart';
import 'login_view.dart';
import 'registro_empresa_view.dart';

/// Decide la primera pantalla según la sesión guardada en el teléfono:
/// sin sesión → login; con sesión sin empresa → registro; con empresa → home.
class RootView extends StatefulWidget {
  const RootView({super.key});

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  late final Future<Session?> _sesion = AuthService.instance.restoreSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Session?>(
      future: _sesion,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _Splash();
        }

        final session = snapshot.data;
        if (session == null) return const LoginView();
        if (session.user.empresa == null) {
          return RegistroEmpresaView(session: session);
        }
        return HomeView(session: session);
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.fondoOscuro,
      body: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Paleta.primario,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const Text(
            'M',
            style: TextStyle(
              color: Paleta.blanco,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
