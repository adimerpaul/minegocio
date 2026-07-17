import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../services/auth_service.dart';
import '../../viewmodels/empresa_viewmodel.dart';
import '../widgets/campo_texto.dart';

/// Configuración de empresa: edita los datos reales contra el backend
/// (PUT /api/empresa) y muestra el estado de la tienda en línea.
class ConfigPage extends StatefulWidget {
  final Session session;
  final ValueChanged<Session> onSessionActualizada;

  const ConfigPage({
    super.key,
    required this.session,
    required this.onSessionActualizada,
  });

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final EmpresaViewModel _viewModel = EmpresaViewModel();

  late final TextEditingController _nombre;
  late final TextEditingController _nit;
  late final TextEditingController _telefono;
  late final TextEditingController _direccion;
  late final TextEditingController _correo;
  late String _moneda;

  static const _monedas = {
    'BOB': 'BOB — Boliviano (Bs)',
    'USD': 'USD — Dólar (\$us)',
    'PEN': 'PEN — Sol (S/.)',
  };

  @override
  void initState() {
    super.initState();
    final empresa = widget.session.user.empresa;
    _nombre = TextEditingController(text: empresa?.nombre ?? '');
    _nit = TextEditingController(text: empresa?.nit ?? '');
    _telefono = TextEditingController(text: empresa?.telefono ?? '');
    _direccion = TextEditingController(text: empresa?.direccion ?? '');
    _correo = TextEditingController(text: empresa?.correo ?? '');
    _moneda = empresa?.moneda ?? 'BOB';
  }

  @override
  void dispose() {
    _viewModel.dispose();
    for (final c in [_nombre, _nit, _telefono, _direccion, _correo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final user = await _viewModel.actualizar(widget.session, {
      'nombre': _nombre.text.trim(),
      'nit': _nit.text.trim(),
      'telefono': _telefono.text.trim(),
      'direccion': _direccion.text.trim(),
      'correo': _correo.text.trim(),
      'moneda': _moneda,
    });
    if (!mounted) return;

    if (user != null) {
      widget.onSessionActualizada(widget.session.copyWith(user: user));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Paleta.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Paleta.bordeSuave),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Datos de la empresa',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Paleta.texto,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CampoTexto(label: 'Nombre comercial', controller: _nombre),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CampoTexto(label: 'NIT', controller: _nit),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoTexto(
                          label: 'Teléfono',
                          controller: _telefono,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CampoTexto(label: 'Dirección', controller: _direccion),
                  const SizedBox(height: 12),
                  CampoTexto(label: 'Correo', controller: _correo),
                  const SizedBox(height: 12),
                  const Text(
                    'Moneda',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Paleta.textoMedio,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _monedas.containsKey(_moneda)
                        ? _moneda
                        : 'BOB',
                    decoration: decoracionCampo(null),
                    style: const TextStyle(fontSize: 14, color: Paleta.texto),
                    items: _monedas.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _moneda = v ?? 'BOB'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _viewModel.loading ? null : _guardar,
                    child: Text(
                      _viewModel.loading
                          ? 'Guardando...'
                          : 'Guardar cambios',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
                    ),
                  ),
                  if (_viewModel.error != null) ...[
                    const SizedBox(height: 12),
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
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Paleta.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Paleta.bordeSuave),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tienda en línea',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tu catálogo público estará disponible en una próxima etapa: '
                'tus clientes podrán ver tus productos y hacer pedidos.',
                style: TextStyle(
                  fontSize: 13,
                  color: Paleta.textoSuave,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
