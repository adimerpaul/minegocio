import 'package:flutter/material.dart';

import '../viewmodels/login_viewmodel.dart';

/// Pantalla de login (paleta del mockup ejemplo.html).
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginViewModel _viewModel = LoginViewModel();

  static const Color _background = Color(0xFFFAF8F6);
  static const Color _text = Color(0xFF221A15);
  static const Color _primary = Color(0xFFF4632C);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                final account = _viewModel.account;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.storefront, size: 64, color: _primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Mi Negocio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (account == null) ...[
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            _viewModel.loading ? null : _viewModel.signIn,
                        icon: _viewModel.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login, color: Colors.white),
                        label: Text(
                          _viewModel.loading
                              ? 'Iniciando sesión...'
                              : 'Continuar con Google',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ] else ...[
                      if (account.photoUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(account.photoUrl!),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        account.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _text,
                        ),
                      ),
                      Text(
                        account.email,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _text.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: _viewModel.signOut,
                        child: const Text(
                          'Cerrar sesión',
                          style: TextStyle(color: _primary),
                        ),
                      ),
                    ],
                    if (_viewModel.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _viewModel.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
