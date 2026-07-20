import 'package:flutter/material.dart';

import '../config/paleta.dart';
import '../services/idioma_service.dart';
import '../viewmodels/login_viewmodel.dart';
import 'home_view.dart';
import 'registro_empresa_view.dart';
import 'widgets/selector_idioma.dart';

/// Pantalla de login (diseño del mockup ejemplo.html: fondo oscuro y
/// hoja inferior clara con las acciones).
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginViewModel _viewModel = LoginViewModel();

  @override
  void initState() {
    super.initState();
    // El selector de idioma se abre desde esta pantalla: hay que redibujarla
    // al instante cuando cambia (la reconstrucción de MaterialApp no llega
    // hasta aquí porque los widgets const y las rutas no se reconstruyen).
    IdiomaService.instance.addListener(_idiomaCambiado);
  }

  void _idiomaCambiado() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    IdiomaService.instance.removeListener(_idiomaCambiado);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final session = await _viewModel.signIn();
    if (session == null || !mounted) return;

    final destino = session.user.empresa == null
        ? RegistroEmpresaView(session: session)
        : HomeView(session: session);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destino),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.fondo,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, right: 12),
                      child: Material(
                        color: Paleta.blanco,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 0,
                        child: InkWell(
                          onTap: () => mostrarSelectorIdioma(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Paleta.blanco,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Paleta.bordeSuave),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A221A15),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.language_rounded,
                                  color: Paleta.primario,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tr('comun.idioma'),
                                  style: const TextStyle(
                                    color: Paleta.texto,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Paleta.blanco,
                        shape: BoxShape.circle,
                        border: Border.all(color: Paleta.bordeSuave, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26221A15),
                            blurRadius: 28,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_default.webp',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      tr('app.nombre'),
                      style: const TextStyle(
                        color: Paleta.texto,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 280,
                      child: Text(
                        tr('login.eslogan'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Paleta.textoSuave,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Paleta.fondo,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Paleta.blanco,
                          side: const BorderSide(color: Paleta.borde),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _viewModel.loading ? null : _iniciarSesion,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_viewModel.loading)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Paleta.primario,
                                ),
                              )
                            else
                              Image.asset(
                                'assets/images/gmail_logo.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            const SizedBox(width: 10),
                            Text(
                              _viewModel.loading
                                  ? tr('login.iniciando')
                                  : tr('login.con_gmail'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Paleta.texto,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_viewModel.error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _viewModel.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Paleta.alertaTexto,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
