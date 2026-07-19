import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/env.dart';
import '../../config/paleta.dart';
import '../../services/auth_service.dart';
import '../../viewmodels/empresa_viewmodel.dart';
import '../widgets/campo_texto.dart';
import '../widgets/selector_imagen.dart';

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
  File? _logo; // logo nuevo elegido, aún sin guardar

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

  Future<void> _elegirLogo() async {
    try {
      final logo = await seleccionarImagen(context);
      if (logo == null || !mounted) return;
      setState(() => _logo = logo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _guardar() async {
    final user = await _viewModel.actualizar(widget.session, {
      'nombre': _nombre.text.trim(),
      'nit': _nit.text.trim(),
      'telefono': _telefono.text.trim(),
      'direccion': _direccion.text.trim(),
      'correo': _correo.text.trim(),
      'moneda': _moneda,
    }, logo: _logo);
    if (!mounted) return;

    if (user != null) {
      setState(() => _logo = null); // ya quedó guardado en el backend
      widget.onSessionActualizada(widget.session.copyWith(user: user));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
    }
  }

  /// Logo actual (o el recién elegido) con el botón para cambiarlo.
  Widget _logoWidget() {
    const lado = 96.0;
    final logoUrl = widget.session.user.empresa?.logoUrl;

    Widget imagen;
    if (_logo != null) {
      imagen = Image.file(_logo!, width: lado, height: lado, fit: BoxFit.cover);
    } else if (logoUrl != null) {
      imagen = Image.network(
        logoUrl,
        width: lado,
        height: lado,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _sinLogo(lado),
      );
    } else {
      imagen = _sinLogo(lado);
    }

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: imagen),
        Positioned(
          right: 2,
          bottom: 2,
          child: Material(
            color: Paleta.primario,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _viewModel.loading ? null : _elegirLogo,
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.photo_camera, size: 17, color: Paleta.blanco),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sinLogo(double lado) {
    return Container(
      width: lado,
      height: lado,
      color: Paleta.tinte,
      alignment: Alignment.center,
      child: const Icon(Icons.storefront, size: 36, color: Color(0xFFC2410C)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Padding inferior amplio para que el botón no quede oculto
      // detrás de la barra de navegación.
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 48),
      children: [
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Container(
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 12),
                  Center(child: _logoWidget()),
                  const SizedBox(height: 14),
                  CampoTexto(
                    label: 'Nombre comercial',
                    controller: _nombre,
                    denso: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CampoTexto(
                          label: 'NIT',
                          controller: _nit,
                          denso: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoTexto(
                          label: 'Teléfono',
                          controller: _telefono,
                          denso: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CampoTexto(
                    label: 'Dirección',
                    controller: _direccion,
                    denso: true,
                  ),
                  const SizedBox(height: 10),
                  CampoTexto(label: 'Correo', controller: _correo, denso: true),
                  const SizedBox(height: 10),
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
                    decoration: decoracionCampo(null, denso: true),
                    style: const TextStyle(fontSize: 14, color: Paleta.texto),
                    items: _monedas.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _moneda = v ?? 'BOB'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _viewModel.loading ? null : _guardar,
                    child: Text(
                      _viewModel.loading ? 'Guardando...' : 'Guardar cambios',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tienda en línea',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.session.user.empresa?.slugTienda != null
                    ? 'Tu tienda se genera automáticamente desde el nombre de tu empresa.'
                    : 'Guarda el nombre comercial para activar tu catálogo público. '
                        'Tus clientes podrán ver tus productos y hacer pedidos.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Paleta.textoSuave,
                  height: 1.5,
                ),
              ),
              if (widget.session.user.empresa?.slugTienda != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Paleta.tinte,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: Paleta.primario),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${Env.apiUrl}/tienda/${widget.session.user.empresa!.slugTienda}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Paleta.primarioOscuro,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
