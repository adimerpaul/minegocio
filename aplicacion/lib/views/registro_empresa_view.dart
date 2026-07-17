import 'package:flutter/material.dart';

import '../config/paleta.dart';
import '../services/auth_service.dart';
import '../viewmodels/empresa_viewmodel.dart';
import 'home_view.dart';
import 'widgets/campo_texto.dart';

/// Pantalla "Registra tu empresa" del mockup: se muestra cuando la cuenta
/// de Gmail todavía no está vinculada a ninguna empresa.
class RegistroEmpresaView extends StatefulWidget {
  final Session session;

  const RegistroEmpresaView({super.key, required this.session});

  @override
  State<RegistroEmpresaView> createState() => _RegistroEmpresaViewState();
}

class _RegistroEmpresaViewState extends State<RegistroEmpresaView> {
  final EmpresaViewModel _viewModel = EmpresaViewModel();

  final _nombre = TextEditingController();
  final _nit = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _correo = TextEditingController();
  String _moneda = 'BOB';

  static const _monedas = {
    'BOB': 'BOB — Boliviano (Bs)',
    'USD': 'USD — Dólar (\$us)',
    'PEN': 'PEN — Sol (S/.)',
  };

  @override
  void dispose() {
    _viewModel.dispose();
    for (final c in [_nombre, _nit, _telefono, _direccion, _correo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _crearEmpresa() async {
    if (_nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre comercial es obligatorio.')),
      );
      return;
    }

    final user = await _viewModel.crear(widget.session, {
      'nombre': _nombre.text.trim(),
      'nit': _nit.text.trim(),
      'telefono': _telefono.text.trim(),
      'direccion': _direccion.text.trim(),
      'correo': _correo.text.trim(),
      'moneda': _moneda,
    });
    if (user == null || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomeView(session: widget.session.copyWith(user: user)),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CUENTA VERIFICADA CON GMAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Paleta.primario,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registra tu empresa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Paleta.texto,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tu cuenta no está vinculada a ninguna empresa. '
                    'Completa estos datos para comenzar.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Paleta.textoSuave,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  CampoTexto(
                    label: 'Nombre comercial',
                    hint: 'Ej. Comercial Andina',
                    controller: _nombre,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CampoTexto(
                          label: 'NIT',
                          hint: '1023456019',
                          controller: _nit,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoTexto(
                          label: 'Teléfono',
                          hint: '+591 700 12345',
                          controller: _telefono,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CampoTexto(
                    label: 'Dirección',
                    hint: 'Av. América #245, Cochabamba',
                    controller: _direccion,
                  ),
                  const SizedBox(height: 16),
                  CampoTexto(
                    label: 'Correo de la empresa',
                    hint: 'ventas@empresa.bo',
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Moneda principal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Paleta.textoMedio,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _moneda,
                    decoration: decoracionCampo(null),
                    style: const TextStyle(fontSize: 15, color: Paleta.texto),
                    items: _monedas.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _moneda = v ?? 'BOB'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Logo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Paleta.textoMedio,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Podrás subir tu logo muy pronto.'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFCFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD9CFC6),
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              color: Paleta.grisClaro, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Toca para subir tu logo',
                            style: TextStyle(
                              fontSize: 13,
                              color: Paleta.textoSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _viewModel.loading ? null : _crearEmpresa,
                    child: Text(
                      _viewModel.loading
                          ? 'Creando empresa...'
                          : 'Crear empresa y entrar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
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
    );
  }
}
