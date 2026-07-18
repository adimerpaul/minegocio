import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../models/cliente.dart';
import '../../services/auth_service.dart';
import '../../services/cliente_service.dart';
import '../widgets/campo_texto.dart';

/// Gestión de clientes: buscador, listado (el S/N primero), alta, edición
/// y borrado contra el backend.
class ClientesPage extends StatefulWidget {
  final Session session;

  const ClientesPage({super.key, required this.session});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List<Cliente>? _clientes;
  String? _error;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar({bool refrescar = false}) async {
    setState(() => _error = null);
    try {
      final clientes = await ClienteService.instance
          .listar(widget.session.token, refrescar: refrescar);
      if (mounted) setState(() => _clientes = clientes);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  List<Cliente> get _filtrados {
    final filtro = _filtro.trim().toLowerCase();
    return (_clientes ?? [])
        .where((c) =>
            filtro.isEmpty ||
            '${c.nombre} ${c.nit ?? ''} ${c.telefono ?? ''}'
                .toLowerCase()
                .contains(filtro))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Paleta.textoSuave),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _cargar,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Paleta.primario),
              ),
            ),
          ],
        ),
      );
    }
    if (_clientes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Paleta.primario),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _filtro = v),
                  style: const TextStyle(fontSize: 14, color: Paleta.texto),
                  decoration: decoracionCampo('Nombre, NIT o teléfono'),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Paleta.primario,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _abrirFormulario(),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.person_add_alt_1,
                      size: 22,
                      color: Paleta.blanco,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Paleta.primario,
            onRefresh: () => _cargar(refrescar: true),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
              itemCount: _filtrados.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _tarjetaCliente(_filtrados[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaCliente(Cliente cliente) {
    final detalle = [
      if (cliente.telefono?.isNotEmpty ?? false) 'Cel. ${cliente.telefono}',
      if (cliente.nit?.isNotEmpty ?? false) 'NIT ${cliente.nit}',
    ].join(' · ');

    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: cliente.esDefault
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'S/N es el cliente de las ventas sin nombre; '
                      'no se puede editar.',
                    ),
                  ),
                )
            : () => _abrirFormulario(cliente),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Paleta.bordeSuave),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: Paleta.tinte,
                child: Text(
                  _iniciales(cliente),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Paleta.primarioOscuro,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Paleta.texto,
                      ),
                    ),
                    if (detalle.isNotEmpty)
                      Text(
                        detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Paleta.textoSuave,
                        ),
                      ),
                  ],
                ),
              ),
              if (cliente.esDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Paleta.tinte,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Por defecto',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Paleta.primarioOscuro,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Paleta.grisClaro,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _iniciales(Cliente cliente) {
    if (cliente.esDefault) return 'S/N';
    return cliente.nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  /// Alta ([cliente] null) o edición de un cliente, en una hoja inferior.
  void _abrirFormulario([Cliente? cliente]) {
    final nombre = TextEditingController(text: cliente?.nombre ?? '');
    final nit = TextEditingController(text: cliente?.nit ?? '');
    final telefono = TextEditingController(text: cliente?.telefono ?? '');
    final correo = TextEditingController(text: cliente?.correo ?? '');
    final direccion = TextEditingController(text: cliente?.direccion ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        var guardando = false;
        String? errorSheet;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> guardar() async {
              if (nombre.text.trim().isEmpty) {
                setSheetState(() => errorSheet = 'El nombre es obligatorio.');
                return;
              }
              setSheetState(() {
                guardando = true;
                errorSheet = null;
              });

              final datos = {
                'nombre': nombre.text.trim(),
                'nit': nit.text.trim(),
                'telefono': telefono.text.trim(),
                'correo': correo.text.trim(),
                'direccion': direccion.text.trim(),
              };

              try {
                if (cliente == null) {
                  await ClienteService.instance.crear(
                    token: widget.session.token,
                    datos: datos,
                  );
                } else {
                  await ClienteService.instance.actualizar(
                    token: widget.session.token,
                    clienteId: cliente.id,
                    datos: datos,
                  );
                }
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                await _cargar(refrescar: true);
              } catch (e) {
                setSheetState(() {
                  guardando = false;
                  errorSheet = '$e'.replaceFirst('Exception: ', '');
                });
              }
            }

            Future<void> borrar() async {
              final confirmado = await showDialog<bool>(
                context: sheetContext,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Borrar cliente'),
                  content: Text('¿Borrar a ${cliente!.nombre}? Sus ventas '
                      'registradas no se pierden.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Paleta.alertaTexto,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Borrar'),
                    ),
                  ],
                ),
              );
              if (confirmado != true) return;

              setSheetState(() {
                guardando = true;
                errorSheet = null;
              });

              try {
                await ClienteService.instance.eliminar(
                  token: widget.session.token,
                  clienteId: cliente!.id,
                );
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                await _cargar(refrescar: true);
              } catch (e) {
                setSheetState(() {
                  guardando = false;
                  errorSheet = '$e'.replaceFirst('Exception: ', '');
                });
              }
            }

            return Padding(
              // Sube la hoja cuando el teclado está abierto.
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        cliente == null ? 'Nuevo cliente' : 'Editar cliente',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CampoTexto(
                        label: 'Nombre completo',
                        controller: nombre,
                        denso: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CampoTexto(
                              label: 'NIT / CI',
                              controller: nit,
                              keyboardType: TextInputType.number,
                              denso: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CampoTexto(
                              label: 'Teléfono',
                              controller: telefono,
                              keyboardType: TextInputType.phone,
                              denso: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CampoTexto(
                        label: 'Correo',
                        controller: correo,
                        keyboardType: TextInputType.emailAddress,
                        denso: true,
                      ),
                      const SizedBox(height: 10),
                      CampoTexto(
                        label: 'Dirección',
                        controller: direccion,
                        denso: true,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Paleta.primario,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: guardando ? null : guardar,
                        child: Text(
                          guardando
                              ? 'Guardando...'
                              : (cliente == null
                                  ? 'Registrar cliente'
                                  : 'Guardar cambios'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Paleta.blanco,
                          ),
                        ),
                      ),
                      if (cliente != null) ...[
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: guardando ? null : borrar,
                          child: const Text(
                            'Borrar cliente',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Paleta.alertaTexto,
                            ),
                          ),
                        ),
                      ],
                      if (errorSheet != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorSheet!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Paleta.alertaTexto,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
