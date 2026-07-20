import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/env.dart';
import '../../config/paleta.dart';
import '../../services/auth_service.dart';
import '../../services/idioma_service.dart';
import '../../services/tienda_launcher.dart';
import '../../viewmodels/empresa_viewmodel.dart';
import '../widgets/campo_texto.dart';
import '../widgets/selector_idioma.dart';
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

  final _monedas = {
    'BOB': tr('moneda.BOB'),
    'USD': tr('moneda.USD'),
    'PEN': tr('moneda.PEN'),
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
      ).showSnackBar(SnackBar(content: Text(tr('config.guardado'))));
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
                  Text(
                    tr('config.datos'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Paleta.texto,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(child: _logoWidget()),
                  const SizedBox(height: 14),
                  CampoTexto(
                    label: tr('registro.nombre_comercial'),
                    controller: _nombre,
                    denso: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CampoTexto(
                          label: tr('registro.nit'),
                          controller: _nit,
                          denso: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CampoTexto(
                          label: tr('registro.telefono'),
                          controller: _telefono,
                          denso: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CampoTexto(
                    label: tr('registro.direccion'),
                    controller: _direccion,
                    denso: true,
                  ),
                  const SizedBox(height: 10),
                  CampoTexto(
                      label: tr('config.correo'),
                      controller: _correo,
                      denso: true),
                  const SizedBox(height: 10),
                  Text(
                    tr('config.moneda'),
                    style: const TextStyle(
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
                      _viewModel.loading
                          ? tr('config.guardando')
                          : tr('config.guardar'),
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
        // Material (no Container) para que el ListTile pinte su fondo y el
        // efecto de toque; con un DecoratedBox encima Flutter lo reclama.
        Material(
          color: Paleta.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Paleta.bordeSuave),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.language, color: Paleta.primario),
            title: Text(
              tr('comun.idioma'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Paleta.texto,
              ),
            ),
            subtitle: Text(
              tr('config.idioma_nota'),
              style: const TextStyle(fontSize: 12.5, color: Paleta.textoSuave),
            ),
            trailing: Text(
              IdiomaService.instance.codigo.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Paleta.primarioOscuro,
              ),
            ),
            onTap: () => mostrarSelectorIdioma(context),
          ),
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
              Text(
                tr('config.tienda'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.session.user.empresa?.slugTienda != null
                    ? tr('config.tienda_activa')
                    : tr('config.tienda_inactiva'),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => abrirTienda(
                      context,
                      widget.session.user.empresa,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Paleta.primarioOscuro,
                      side: const BorderSide(color: Paleta.primario),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      tr('config.abrir_tienda'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
