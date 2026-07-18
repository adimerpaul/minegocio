import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../models/proveedor.dart';
import '../../services/auth_service.dart';
import '../../services/proveedor_service.dart';
import '../widgets/campo_texto.dart';

/// Gestión de proveedores: buscador, listado (el S/N primero), alta,
/// edición y borrado contra el backend.
class ProveedoresPage extends StatefulWidget {
  final Session session;

  const ProveedoresPage({super.key, required this.session});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  List<Proveedor>? _proveedores;
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
      final proveedores = await ProveedorService.instance
          .listar(widget.session.token, refrescar: refrescar);
      if (mounted) setState(() => _proveedores = proveedores);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  List<Proveedor> get _filtrados {
    final filtro = _filtro.trim().toLowerCase();
    return (_proveedores ?? [])
        .where((p) =>
            filtro.isEmpty ||
            '${p.nombre} ${p.nit ?? ''} ${p.telefono ?? ''}'
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
    if (_proveedores == null) {
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
                      Icons.add_business_outlined,
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
              itemBuilder: (context, i) => _tarjetaProveedor(_filtrados[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaProveedor(Proveedor proveedor) {
    final detalle = [
      if (proveedor.telefono?.isNotEmpty ?? false) 'Cel. ${proveedor.telefono}',
      if (proveedor.nit?.isNotEmpty ?? false) 'NIT ${proveedor.nit}',
    ].join(' · ');

    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: proveedor.esDefault
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'S/N es el proveedor de las compras sin nombre; '
                      'no se puede editar.',
                    ),
                  ),
                )
            : () => _abrirFormulario(proveedor),
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
                child: Icon(
                  proveedor.esDefault
                      ? Icons.local_shipping_outlined
                      : Icons.storefront_outlined,
                  size: 18,
                  color: Paleta.primarioOscuro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.etiqueta,
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
              if (proveedor.esDefault)
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

  /// Alta ([proveedor] null) o edición de un proveedor, en hoja inferior.
  void _abrirFormulario([Proveedor? proveedor]) {
    final nombre = TextEditingController(text: proveedor?.nombre ?? '');
    final nit = TextEditingController(text: proveedor?.nit ?? '');
    final telefono = TextEditingController(text: proveedor?.telefono ?? '');
    final correo = TextEditingController(text: proveedor?.correo ?? '');
    final direccion = TextEditingController(text: proveedor?.direccion ?? '');

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
                if (proveedor == null) {
                  await ProveedorService.instance.crear(
                    token: widget.session.token,
                    datos: datos,
                  );
                } else {
                  await ProveedorService.instance.actualizar(
                    token: widget.session.token,
                    proveedorId: proveedor.id,
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
                  title: const Text('Borrar proveedor'),
                  content: Text('¿Borrar a ${proveedor!.nombre}? Sus compras '
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
                await ProveedorService.instance.eliminar(
                  token: widget.session.token,
                  proveedorId: proveedor!.id,
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
                        proveedor == null
                            ? 'Nuevo proveedor'
                            : 'Editar proveedor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CampoTexto(
                        label: 'Nombre o razón social',
                        controller: nombre,
                        denso: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CampoTexto(
                              label: 'NIT',
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
                              : (proveedor == null
                                  ? 'Registrar proveedor'
                                  : 'Guardar cambios'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Paleta.blanco,
                          ),
                        ),
                      ),
                      if (proveedor != null) ...[
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: guardando ? null : borrar,
                          child: const Text(
                            'Borrar proveedor',
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
