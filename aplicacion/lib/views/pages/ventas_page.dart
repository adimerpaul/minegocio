import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/venta.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/venta_service.dart';
import '../../services/voucher_service.dart';
import '../widgets/campo_texto.dart';

/// Historial de ventas: stats de hoy y del mes, buscador y la lista real.
class VentasPage extends StatefulWidget {
  final Session session;

  const VentasPage({super.key, required this.session});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  List<Venta>? _ventas;
  String? _error;
  String _filtro = '';

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final ventas = await VentaService.instance.listar(widget.session.token);
      if (mounted) setState(() => _ventas = ventas);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
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
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Paleta.primario),
              ),
            ),
          ],
        ),
      );
    }
    if (_ventas == null) {
      return const Center(
        child: CircularProgressIndicator(color: Paleta.primario),
      );
    }

    final ahora = DateTime.now();
    // Las anuladas no cuentan en los totales.
    final validas = _ventas!.where((v) => !v.anulada);
    final hoy = validas
        .where((v) =>
            v.fecha.year == ahora.year &&
            v.fecha.month == ahora.month &&
            v.fecha.day == ahora.day)
        .fold(0.0, (a, v) => a + v.total);
    final mes = validas
        .where((v) => v.fecha.year == ahora.year && v.fecha.month == ahora.month)
        .fold(0.0, (a, v) => a + v.total);

    final filtro = _filtro.trim().toLowerCase();
    final ventas = _ventas!
        .where((v) =>
            filtro.isEmpty ||
            '${v.codigo} ${v.cliente ?? 'venta en mostrador'}'
                .toLowerCase()
                .contains(filtro))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _stat(
                  'Ventas de hoy',
                  formatoMoneda(hoy, simbolo: _simbolo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _stat(
                  'Ventas del mes',
                  formatoMoneda(mes, simbolo: _simbolo),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: TextField(
            onChanged: (v) => setState(() => _filtro = v),
            style: const TextStyle(fontSize: 14, color: Paleta.texto),
            decoration: decoracionCampo('Buscar por número o cliente…'),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Paleta.primario,
            onRefresh: _cargar,
            child: ventas.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 60,
                        ),
                        child: Text(
                          'Todavía no hay ventas. Regístralas desde Venta rápida.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Paleta.textoSuave,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    itemCount: ventas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _tarjeta(ventas[i]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Paleta.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Paleta.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Paleta.textoSuave,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Paleta.texto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Venta venta) {
    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirDetalle(venta),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Paleta.bordeSuave),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: venta.anulada ? Paleta.alertaFondo : Paleta.tinte,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  venta.anulada ? Icons.block : Icons.north_east,
                  size: 18,
                  color: venta.anulada
                      ? Paleta.alertaTexto
                      : const Color(0xFFC2410C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venta.cliente ?? 'Venta en mostrador',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.texto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${venta.codigo} · ${formatoFecha(venta.fecha)} · ${venta.cantidadItems} ítems',
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatoMoneda(venta.total, simbolo: _simbolo),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Paleta.texto,
                      decoration:
                          venta.anulada ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (venta.anulada)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Paleta.alertaFondo,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Anulada',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Paleta.alertaTexto,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDetalle(Venta venta) {
    final empresa = widget.session.user.empresa;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Paleta.borde,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Venta ${venta.codigo}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                    ),
                    if (venta.anulada)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Paleta.alertaFondo,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Anulada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Paleta.alertaTexto,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${venta.cliente ?? 'Venta en mostrador'} · ${formatoFecha(venta.fecha)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Paleta.textoSuave,
                  ),
                ),
                const SizedBox(height: 14),
                for (final item in venta.items)
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
                              fontSize: 14,
                              color: Paleta.texto,
                            ),
                          ),
                        ),
                        Text(
                          formatoMoneda(item.subtotal, simbolo: _simbolo),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Paleta.texto,
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
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          color: Paleta.textoSuave,
                        ),
                      ),
                      Text(
                        formatoMoneda(venta.total, simbolo: _simbolo),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (empresa != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => VoucherService.instance.imprimir(
                      empresa: empresa,
                      venta: venta,
                    ),
                    icon: const Icon(Icons.print, color: Paleta.blanco),
                    label: const Text(
                      'Imprimir voucher',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
                    ),
                  ),
                if (!venta.anulada) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Paleta.alertaTexto),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmarAnulacion(venta);
                    },
                    icon: const Icon(
                      Icons.block,
                      size: 18,
                      color: Paleta.alertaTexto,
                    ),
                    label: const Text(
                      'Anular venta',
                      style: TextStyle(
                        fontSize: 15,
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

  Future<void> _confirmarAnulacion(Venta venta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anular ${venta.codigo}'),
        content: const Text(
          'Los productos de esta venta volverán al inventario. '
          'Esta acción no se puede deshacer. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Paleta.alertaTexto,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await VentaService.instance.anular(
        token: widget.session.token,
        ventaId: venta.id,
      );

      // El stock volvió al inventario: se refresca el catálogo en caché.
      await CatalogoService.instance
          .listar(widget.session.token, refrescar: true);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Venta ${venta.codigo} anulada. El stock volvió al inventario.',
          ),
        ),
      );

      await _cargar();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }
}
