import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/compra.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/compra_service.dart';
import '../../services/idioma_service.dart';
import '../../services/voucher_service.dart';
import 'nueva_compra_page.dart';

/// Compras de la empresa: historial (tocar una abre el detalle con la
/// opción de anular) y registro de compras nuevas que aumentan el stock.
class ComprasPage extends StatefulWidget {
  final Session session;

  const ComprasPage({super.key, required this.session});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  List<Compra>? _compras;
  String? _error;

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final compras = await CompraService.instance.listar(
        widget.session.token,
      );
      if (mounted) setState(() => _compras = compras);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _nuevaCompra() async {
    final compra = await Navigator.of(context).push<Compra>(
      MaterialPageRoute(
        builder: (_) => NuevaCompraPage(session: widget.session),
      ),
    );
    if (compra == null || !mounted) return;

    _mostrarConfirmacion(compra);
    await _cargar();
  }

  /// Hoja de compra registrada, con la opción de imprimir el voucher.
  void _mostrarConfirmacion(Compra compra) {
    final empresa = widget.session.user.empresa;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 30,
                    color: Color(0xFF1D7A3E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  trp('compras.registrada', {'codigo': compra.codigo}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Paleta.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatoMoneda(compra.total, simbolo: _simbolo)} · ${tr('compras.stock_aumento')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Paleta.textoSuave,
                  ),
                ),
                const SizedBox(height: 18),
                if (empresa != null) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => VoucherService.instance.imprimirCompra(
                      empresa: empresa,
                      compra: compra,
                    ),
                    icon: const Icon(Icons.print, color: Paleta.blanco),
                    label: Text(
                      tr('venta.imprimir'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Paleta.primario),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => VoucherService.instance.compartirCompra(
                      empresa: empresa,
                      compra: compra,
                    ),
                    icon: const Icon(Icons.share, color: Paleta.primario),
                    label: Text(
                      tr('venta.compartir_whatsapp'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.primario,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Paleta.borde),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    tr('comun.listo'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Paleta.textoMedio,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _anular(Compra compra, BuildContext sheetContext) async {
    final confirmado = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('compras.anular')),
        content: Text(
          trp('compras.anular_confirmar', {'codigo': compra.codigo}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('comun.cancelar')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Paleta.alertaTexto,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('ventas.anular_boton')),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await CompraService.instance.anular(
        token: widget.session.token,
        compraId: compra.id,
      );
      // El stock cambió: se refresca el catálogo.
      await CatalogoService.instance.listar(
        widget.session.token,
        refrescar: true,
      );

      if (sheetContext.mounted) Navigator.pop(sheetContext);
      messenger.showSnackBar(
        SnackBar(
            content:
                Text(trp('compras.anulada_ok', {'codigo': compra.codigo}))),
      );
      await _cargar();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
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
              child: Text(
                tr('comun.reintentar'),
                style: const TextStyle(color: Paleta.primario),
              ),
            ),
          ],
        ),
      );
    }
    if (_compras == null) {
      return const Center(
        child: CircularProgressIndicator(color: Paleta.primario),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Paleta.primario,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _nuevaCompra,
            icon: const Icon(Icons.add_shopping_cart,
                size: 19, color: Paleta.blanco),
            label: Text(
              tr('compras.registrar'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Paleta.blanco,
              ),
            ),
          ),
        ),
        Expanded(
          child: _compras!.isEmpty
              ? Center(
                  child: Text(
                    tr('compras.vacio'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13.5, color: Paleta.textoSuave),
                  ),
                )
              : RefreshIndicator(
                  color: Paleta.primario,
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                    itemCount: _compras!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _tarjetaCompra(_compras![i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tarjetaCompra(Compra compra) {
    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDetalle(compra),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Paleta.bordeSuave),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          compra.codigo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Paleta.texto,
                          ),
                        ),
                        if (compra.anulada) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE8E8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tr('ventas.anulada'),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Paleta.alertaTexto,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${compra.proveedor} · ${compra.cantidadItems} ${tr('ventas.items')} '
                      '· ${formatoFecha(compra.fecha)}',
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
              Text(
                formatoMoneda(compra.total, simbolo: _simbolo),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: compra.anulada ? Paleta.grisClaro : Paleta.texto,
                  decoration:
                      compra.anulada ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDetalle(Compra compra) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${tr('compras.compra')} ${compra.codigo}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Paleta.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${compra.proveedor} · ${formatoFecha(compra.fecha)}'
                  '${compra.anulada ? ' · ${tr('ventas.anulada').toUpperCase()}' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: compra.anulada
                        ? Paleta.alertaTexto
                        : Paleta.textoSuave,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final item in compra.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.cantidad} × ${item.nombre}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Paleta.texto,
                                  ),
                                ),
                              ),
                              Text(
                                formatoMoneda(
                                  item.subtotal,
                                  simbolo: _simbolo,
                                ),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Paleta.texto,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Paleta.bordeSuave),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('comun.total'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Paleta.textoSuave,
                        ),
                      ),
                      Text(
                        formatoMoneda(compra.total, simbolo: _simbolo),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.session.user.empresa != null) ...[
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => VoucherService.instance.imprimirCompra(
                      empresa: widget.session.user.empresa!,
                      compra: compra,
                    ),
                    icon: const Icon(
                      Icons.print,
                      size: 18,
                      color: Paleta.blanco,
                    ),
                    label: Text(
                      tr('venta.imprimir'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Paleta.primario),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => VoucherService.instance.compartirCompra(
                      empresa: widget.session.user.empresa!,
                      compra: compra,
                    ),
                    icon: const Icon(
                      Icons.share,
                      size: 18,
                      color: Paleta.primario,
                    ),
                    label: Text(
                      tr('venta.compartir_whatsapp'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.primario,
                      ),
                    ),
                  ),
                ],
                if (!compra.anulada) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Paleta.alertaTexto),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _anular(compra, sheetContext),
                    icon: const Icon(
                      Icons.block,
                      size: 18,
                      color: Paleta.alertaTexto,
                    ),
                    label: Text(
                      tr('compras.anular'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.alertaTexto,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
