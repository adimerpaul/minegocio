import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/pedido.dart';
import '../../services/auth_service.dart';
import '../../services/idioma_service.dart';
import '../../services/pedido_service.dart';
import '../widgets/campo_texto.dart';
import 'nuevo_pedido_page.dart';

/// Pedidos de la empresa: los que llegan de la tienda en línea y los
/// registrados a mano. Tocar uno abre el detalle con acciones para
/// confirmar, marcar como entregado o cancelar.
class PedidosPage extends StatefulWidget {
  final Session session;

  const PedidosPage({super.key, required this.session});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  List<Pedido>? _pedidos;
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
      final pedidos = await PedidoService.instance.listar(
        widget.session.token,
      );
      if (mounted) setState(() => _pedidos = pedidos);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _nuevoPedido() async {
    final pedido = await Navigator.of(context).push<Pedido>(
      MaterialPageRoute(
        builder: (_) => NuevoPedidoPage(session: widget.session),
      ),
    );
    if (pedido == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trp('ventas.registrada', {'codigo': '#${pedido.id}'})),
      ),
    );
    await _cargar();
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'confirmado':
        return const Color(0xFF1D7A3E);
      case 'entregado':
        return Paleta.primarioOscuro;
      case 'cancelado':
        return Paleta.alertaTexto;
      default:
        return const Color(0xFFB58A00);
    }
  }

  Color _fondoEstado(String estado) {
    switch (estado) {
      case 'confirmado':
        return const Color(0xFFE8F5EC);
      case 'entregado':
        return Paleta.tinte;
      case 'cancelado':
        return Paleta.alertaFondo;
      default:
        return const Color(0xFFFBF0D9);
    }
  }

  String _etiquetaEstado(String estado) => switch (estado) {
        'confirmado' => tr('pedidos.estado_confirmado'),
        'entregado' => tr('pedidos.estado_entregado'),
        'cancelado' => tr('pedidos.estado_cancelado'),
        _ => tr('pedidos.estado_pendiente'),
      };

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
    if (_pedidos == null) {
      return const Center(
        child: CircularProgressIndicator(color: Paleta.primario),
      );
    }

    final ahora = DateTime.now();
    final pendientes =
        _pedidos!.where((p) => p.estado == 'pendiente').length;
    final entregadosMes = _pedidos!
        .where((p) =>
            p.estado == 'entregado' &&
            p.fecha.year == ahora.year &&
            p.fecha.month == ahora.month)
        .length;

    final filtro = _filtro.trim().toLowerCase();
    final pedidos = _pedidos!
        .where((p) =>
            filtro.isEmpty ||
            '#${p.id} ${p.clienteNombre ?? ''}'.toLowerCase().contains(filtro))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _stat(tr('pedidos.pendientes'), '$pendientes'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _stat(tr('pedidos.entregados'), '$entregadosMes'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Paleta.primario,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _nuevoPedido,
            icon: const Icon(Icons.add, size: 19, color: Paleta.blanco),
            label: Text(
              tr('pedidos.registrar'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Paleta.blanco,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: TextField(
            onChanged: (v) => setState(() => _filtro = v),
            style: const TextStyle(fontSize: 14, color: Paleta.texto),
            decoration: decoracionCampo(tr('pedidos.buscar')),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Paleta.primario,
            onRefresh: _cargar,
            child: pedidos.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 60,
                        ),
                        child: Text(
                          tr('pedidos.vacio'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                    itemCount: pedidos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _tarjeta(pedidos[i]),
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

  Widget _tarjeta(Pedido pedido) {
    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirDetalle(pedido),
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
                  color: _fondoEstado(pedido.estado),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: _colorEstado(pedido.estado),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (pedido.clienteNombre?.isNotEmpty ?? false)
                          ? pedido.clienteNombre!
                          : tr('pedidos.sin_datos'),
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
                      '#${pedido.id} · ${formatoFecha(pedido.fecha)} · ${pedido.cantidadItems} ${tr('ventas.items')}',
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
                    formatoMoneda(pedido.total, simbolo: _simbolo),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Paleta.texto,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _fondoEstado(pedido.estado),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _etiquetaEstado(pedido.estado),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _colorEstado(pedido.estado),
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

  void _abrirDetalle(Pedido pedido) {
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
                        '${tr('pedidos.pedido')} #${pedido.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _fondoEstado(pedido.estado),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _etiquetaEstado(pedido.estado),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _colorEstado(pedido.estado),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(pedido.clienteNombre?.isNotEmpty ?? false) ? pedido.clienteNombre! : tr('pedidos.sin_datos')} · ${formatoFecha(pedido.fecha)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Paleta.textoSuave,
                  ),
                ),
                if (pedido.clienteTelefono?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${tr('comun.cel')} ${pedido.clienteTelefono}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Paleta.textoSuave,
                    ),
                  ),
                ],
                if (pedido.direccion?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    pedido.direccion!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Paleta.textoSuave,
                    ),
                  ),
                ],
                if (pedido.notas?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Paleta.tinte,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pedido.notas!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Paleta.textoMedio,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                for (final item in pedido.items)
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
                      Text(
                        tr('comun.total'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Paleta.textoSuave,
                        ),
                      ),
                      Text(
                        formatoMoneda(pedido.total, simbolo: _simbolo),
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
                if (pedido.estado == 'pendiente') ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D7A3E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _cambiarEstado(
                      pedido,
                      'confirmado',
                      sheetContext,
                    ),
                    icon: const Icon(Icons.check, color: Paleta.blanco),
                    label: Text(
                      tr('pedidos.confirmar'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (pedido.estado == 'confirmado') ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _cambiarEstado(
                      pedido,
                      'entregado',
                      sheetContext,
                    ),
                    icon: const Icon(
                      Icons.local_shipping_outlined,
                      color: Paleta.blanco,
                    ),
                    label: Text(
                      tr('pedidos.entregar'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (pedido.estado != 'cancelado' &&
                    pedido.estado != 'entregado') ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Paleta.alertaTexto),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () =>
                        _confirmarCancelacion(pedido, sheetContext),
                    icon: const Icon(
                      Icons.block,
                      size: 18,
                      color: Paleta.alertaTexto,
                    ),
                    label: Text(
                      tr('pedidos.cancelar_boton'),
                      style: const TextStyle(
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

  Future<void> _confirmarCancelacion(
    Pedido pedido,
    BuildContext sheetContext,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('pedidos.cancelar_boton')),
        content: Text(tr('pedidos.cancelar_confirmar')),
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
            child: Text(tr('pedidos.cancelar_boton')),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted || !sheetContext.mounted) return;

    await _cambiarEstado(pedido, 'cancelado', sheetContext);
  }

  Future<void> _cambiarEstado(
    Pedido pedido,
    String estado,
    BuildContext? sheetContext,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await PedidoService.instance.actualizarEstado(
        token: widget.session.token,
        pedidoId: pedido.id,
        estado: estado,
      );

      if (sheetContext != null && sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
      messenger.showSnackBar(
        SnackBar(content: Text(tr('pedidos.estado_actualizado'))),
      );
      await _cargar();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }
}
