import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/pedido.dart';
import '../../models/venta.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/idioma_service.dart';
import '../../services/pedido_service.dart';
import '../../services/venta_service.dart';

/// Dashboard de inicio (mockup): ventas de hoy y de la semana, pedidos y
/// accesos rápidos con contadores del catálogo, todo con datos reales.
class InicioPage extends StatefulWidget {
  final Session session;
  final ValueChanged<String> onIrModulo;

  const InicioPage({
    super.key,
    required this.session,
    required this.onIrModulo,
  });

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  List<String> get _letrasDia => tr('inicio.dias_letras').split(',');

  int _productos = 0;
  int _stockCritico = 0;
  List<Venta> _ventas = [];
  List<Pedido> _pedidos = [];

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    // El dashboard no se rompe si algo falla: se quedan los ceros.
    try {
      final catalogo =
          await CatalogoService.instance.listar(widget.session.token);
      if (!mounted) return;
      setState(() {
        _productos = catalogo.productos.length;
        _stockCritico = catalogo.productos.where((p) => p.stockBajo).length;
      });
    } catch (_) {}

    try {
      final ventas = await VentaService.instance.listar(widget.session.token);
      if (!mounted) return;
      setState(() => _ventas = ventas);
    } catch (_) {}

    try {
      final pedidos = await PedidoService.instance.listar(
        widget.session.token,
      );
      if (!mounted) return;
      setState(() => _pedidos = pedidos);
    } catch (_) {}
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    // Las ventas anuladas no cuentan en los totales.
    final validas = _ventas.where((v) => !v.anulada).toList();
    final ventasHoy = validas.where((v) => _mismoDia(v.fecha, hoy)).toList();
    final totalHoy = ventasHoy.fold(0.0, (a, v) => a + v.total);

    // Últimos 7 días (hoy al final) para el gráfico de la semana.
    final dias = List.generate(7, (i) {
      final dia = hoy.subtract(Duration(days: 6 - i));
      final total = validas
          .where((v) => _mismoDia(v.fecha, dia))
          .fold(0.0, (a, v) => a + v.total);
      return (dia, total);
    });
    final totalSemana = dias.fold(0.0, (a, d) => a + d.$2);
    final pedidosPendientes =
        _pedidos.where((p) => p.estado == 'pendiente').toList();

    return RefreshIndicator(
      color: Paleta.primario,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Paleta.fondoOscuro,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr('inicio.ventas_hoy')} · ${hoy.day} ${_mesCorto(hoy)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB3A89F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatoMoneda(totalHoy, simbolo: _simbolo),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: Paleta.blanco,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Paleta.primario,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${ventasHoy.length} ${ventasHoy.length == 1 ? tr('inicio.venta_singular') : tr('inicio.venta_plural')}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Paleta.blanco,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _kpi(
                  Icons.schedule,
                  '${pedidosPendientes.length}',
                  tr('inicio.pedidos_linea'),
                  'pedidos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpi(Icons.grid_view, '$_productos',
                    tr('inicio.productos'), 'productos'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _kpi(
                  Icons.north_east,
                  '${_ventas.length}',
                  tr('inicio.ventas_registradas'),
                  'ventas',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpi(
                  Icons.warning_amber_rounded,
                  '$_stockCritico',
                  tr('inicio.stock_critico'),
                  'inventario',
                  alerta: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _tarjeta(
            titulo: tr('inicio.ventas_semana'),
            trailing: formatoMoneda(totalSemana, simbolo: _simbolo),
            child: totalSemana == 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      tr('inicio.sin_ventas_semana'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Paleta.textoSuave),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _graficoSemana(dias),
                  ),
          ),
          const SizedBox(height: 16),
          _tarjeta(
            titulo: tr('inicio.pedidos_linea'),
            accion: tr('inicio.ver_todos'),
            onAccion: () => widget.onIrModulo('pedidos'),
            child: _pedidos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      tr('inicio.sin_pedidos'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Paleta.textoSuave),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: [
                        for (final pedido in _pedidos.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => widget.onIrModulo('pedidos'),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (pedido.clienteNombre?.isNotEmpty ??
                                              false)
                                          ? pedido.clienteNombre!
                                          : tr('pedidos.sin_datos'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Paleta.texto,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatoMoneda(pedido.total,
                                        simbolo: _simbolo),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Paleta.texto,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _mesCorto(DateTime d) =>
      tr('inicio.meses_cortos').split(',')[d.month - 1];

  Widget _graficoSemana(List<(DateTime, double)> dias) {
    final maximo =
        dias.fold(0.0, (a, d) => d.$2 > a ? d.$2 : a).clamp(1.0, double.infinity);

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (dia, total) in dias)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: total == 0 ? 3 : 4 + 80 * (total / maximo),
                      constraints: const BoxConstraints(maxWidth: 30),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _mismoDia(dia, DateTime.now())
                            ? Paleta.primario
                            : const Color(0xFFF0E3D8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _letrasDia[dia.weekday - 1],
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Paleta.grisClaro,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kpi(
    IconData icono,
    String valor,
    String label,
    String modulo, {
    bool alerta = false,
  }) {
    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onIrModulo(modulo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Paleta.bordeSuave),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: alerta ? Paleta.alertaFondo : Paleta.tinte,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icono,
                  size: 17,
                  color: alerta ? Paleta.alertaTexto : const Color(0xFFC2410C),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Paleta.texto,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Paleta.textoSuave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta({
    required String titulo,
    required Widget child,
    String? trailing,
    String? accion,
    VoidCallback? onAccion,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Paleta.textoSuave,
                  ),
                ),
              if (accion != null)
                GestureDetector(
                  onTap: onAccion,
                  child: Text(
                    accion,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Paleta.primario,
                    ),
                  ),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
