import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../services/auth_service.dart';

/// Dashboard de inicio (mockup): resumen de ventas, accesos rápidos y
/// pedidos. Los contadores arrancan en cero hasta conectar cada módulo.
class InicioPage extends StatelessWidget {
  final Session session;
  final ValueChanged<String> onIrModulo;

  const InicioPage({
    super.key,
    required this.session,
    required this.onIrModulo,
  });

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final fecha = '${hoy.day} ${_meses[hoy.month - 1]}';
    final moneda = session.user.empresa?.moneda == 'USD' ? '\$us' : 'Bs';

    return ListView(
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
                'Ventas de hoy · $fecha',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFB3A89F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$moneda 0,00',
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
                child: const Text(
                  '0 ventas',
                  style: TextStyle(
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            _kpi(Icons.schedule, '0', 'Pedidos en línea', 'pedidos'),
            _kpi(Icons.grid_view, '0', 'Productos', 'productos'),
            _kpi(Icons.south_west, '0', 'Compras pendientes', 'compras'),
            _kpi(
              Icons.warning_amber_rounded,
              '0',
              'Stock crítico',
              'inventario',
              alerta: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _tarjeta(
          titulo: 'Ventas de la semana',
          trailing: '$moneda 0,00',
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aún no registraste ventas. Usa Venta rápida para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Paleta.textoSuave),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _tarjeta(
          titulo: 'Pedidos en línea',
          accion: 'Ver todos ›',
          onAccion: () => onIrModulo('pedidos'),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Sin pedidos todavía. Llegarán desde tu tienda en línea.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Paleta.textoSuave),
            ),
          ),
        ),
      ],
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
        onTap: () => onIrModulo(modulo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Paleta.bordeSuave),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
                  color: alerta
                      ? Paleta.alertaTexto
                      : const Color(0xFFC2410C),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                valor,
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
