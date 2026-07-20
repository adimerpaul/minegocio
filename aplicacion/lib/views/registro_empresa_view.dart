import 'package:flutter/material.dart';

import '../config/paleta.dart';
import '../services/auth_service.dart';
import '../services/idioma_service.dart';
import '../viewmodels/empresa_viewmodel.dart';
import 'home_view.dart';
import 'widgets/campo_texto.dart';
import 'widgets/selector_codigo_pais.dart';

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
  String? _codigoPais;

  final _monedas = {
    'BOB': tr('moneda.BOB'),
    'USD': tr('moneda.USD'),
    'PEN': tr('moneda.PEN'),
    'EUR': tr('moneda.EUR'),
    'BRL': tr('moneda.BRL'),
    'ARS': tr('moneda.ARS'),
    'CLP': tr('moneda.CLP'),
    'COP': tr('moneda.COP'),
    'MXN': tr('moneda.MXN'),
    'UYU': tr('moneda.UYU'),
    'PYG': tr('moneda.PYG'),
    'AOA': tr('moneda.AOA'),
    'MZN': tr('moneda.MZN'),
    'CVE': tr('moneda.CVE'),
    'STN': tr('moneda.STN'),
    'XOF': tr('moneda.XOF'),
    'GBP': tr('moneda.GBP'),
    'JPY': tr('moneda.JPY'),
    'CNY': tr('moneda.CNY'),
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
        SnackBar(content: Text(tr('registro.nombre_obligatorio'))),
      );
      return;
    }

    final user = await _viewModel.crear(widget.session, {
      'nombre': _nombre.text.trim(),
      'nit': _nit.text.trim(),
      'telefono': _telefono.text.trim(),
      'codigo_pais': _codigoPais,
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
                  Text(
                    tr('registro.cuenta_verificada'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Paleta.primario,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('registro.titulo'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Paleta.texto,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('registro.subtitulo'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Paleta.textoSuave,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  CampoTexto(
                    label: tr('registro.nombre_comercial'),
                    hint: tr('registro.nombre_hint'),
                    controller: _nombre,
                  ),
                  const SizedBox(height: 16),
                  CampoTexto(
                    label: tr('registro.nit'),
                    hint: tr('registro.nit_hint'),
                    controller: _nit,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('registro.telefono'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Paleta.textoMedio,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectorCodigoPais(
                        codigo: _codigoPais,
                        onChanged: (codigo) => setState(() => _codigoPais = codigo),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoTexto(
                          label: '',
                          hint: tr('registro.telefono_hint'),
                          controller: _telefono,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CampoTexto(
                    label: tr('registro.direccion'),
                    hint: tr('registro.direccion_hint'),
                    controller: _direccion,
                  ),
                  const SizedBox(height: 16),
                  CampoTexto(
                    label: tr('registro.correo'),
                    hint: tr('registro.correo_hint'),
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('registro.moneda'),
                    style: const TextStyle(
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
                  Text(
                    tr('registro.logo'),
                    style: const TextStyle(
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
                    child: Column(
                      children: [
                        const Image(
                          image: AssetImage('assets/images/logo_default.webp'),
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr('registro.logo_nota'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                          ? tr('registro.creando')
                          : tr('registro.crear'),
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
