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
  final _slugTienda = TextEditingController();
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
    for (final c in [_nombre, _slugTienda, _nit, _telefono, _direccion, _correo]) {
      c.dispose();
    }
    super.dispose();
  }

  String _normalizarSlug(String valor) {
    return valor
        .toLowerCase()
        .replaceAll('ñ', 'n')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAllMapped(RegExp(r'[^a-z0-9]+'), (m) => '-')
        .trim()
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _crearEmpresa() async {
    if (_nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre comercial es obligatorio.')),
      );
      return;
    }

    final slug = _normalizarSlug(_slugTienda.text.trim());
    if (slug.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El nombre de tienda debe tener al menos 3 caracteres válidos.',
          ),
        ),
      );
      return;
    }

    final user = await _viewModel.crear(widget.session, {
      'nombre': _nombre.text.trim(),
      'slug_tienda': slug,
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
                  CampoTexto(
                    label: 'Nombre de tu tienda en línea',
                    hint: 'Ej. comercial-andina',
                    controller: _slugTienda,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Solo minúsculas, números y guiones. '
                      'URL: tu-dominio.com/tienda/${_normalizarSlug(_slugTienda.text)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Paleta.textoSuave,
                      ),
                    ),
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFCFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD9CFC6),
                        width: 1.5,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Image(
                          image: AssetImage('assets/images/logo_default.webp'),
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Este será el logo por defecto de tu empresa. '
                          'Puedes cambiarlo más adelante en Configuración.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Paleta.textoSuave,
                          ),
                        ),
                      ],
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
