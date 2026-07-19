import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../services/idioma_service.dart';
import '../widgets/campo_texto.dart';

/// Definición visual de un módulo de gestión (mockup "Módulo de gestión"):
/// estadísticas, buscador y formulario del alta.
class _DefModulo {
  final String stat1;
  final String stat2;
  final String buscador;
  final String etiquetaNuevo;
  final List<(String, String)> campos;
  final String vacio;

  const _DefModulo({
    required this.stat1,
    required this.stat2,
    required this.buscador,
    required this.etiquetaNuevo,
    required this.campos,
    required this.vacio,
  });
}

/// Página genérica de listas (productos, categorías, clientes, proveedores,
/// compras, ventas, inventario y pedidos). Muestra la estructura del mockup;
/// cada módulo se conectará al backend en las siguientes etapas.
class ListaPage extends StatelessWidget {
  final String modulo;

  const ListaPage({super.key, required this.modulo});

  // Los demás módulos (clientes, proveedores, compras, inventario, etc.)
  // ya tienen página propia con datos reales; aquí solo queda "pedidos"
  // hasta que se conecte con el backend.
  Map<String, _DefModulo> get _defs => {
        'pedidos': _DefModulo(
          stat1: tr('pedidos.pendientes'),
          stat2: tr('pedidos.entregados'),
          buscador: tr('ventas.buscar'),
          etiquetaNuevo: tr('pedidos.registrar'),
          campos: [
            (tr('venta.cliente'), tr('clientes.nombre')),
            (tr('registro.telefono'), tr('registro.telefono_hint')),
            (tr('pedidos.direccion'), tr('pedidos.direccion_hint')),
          ],
          vacio: tr('pedidos.vacio'),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final def = _defs[modulo];
    if (def == null) {
      return Center(
        child: Text(
          tr('comun.en_construccion'),
          style: const TextStyle(color: Paleta.textoSuave),
        ),
      );
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _stat(def.stat1, '0')),
                  const SizedBox(width: 12),
                  Expanded(child: _stat(def.stat2, '—')),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                style: const TextStyle(fontSize: 14, color: Paleta.texto),
                decoration: decoracionCampo(def.buscador),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      def.vacio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Paleta.textoSuave,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            backgroundColor: Paleta.primario,
            foregroundColor: Paleta.blanco,
            shape: const CircleBorder(),
            onPressed: () => _abrirNuevo(context, def),
            child: const Icon(Icons.add, size: 26),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: Paleta.texto,
            ),
          ),
        ],
      ),
    );
  }

  void _abrirNuevo(BuildContext context, _DefModulo def) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: 30 + MediaQuery.of(context).viewInsets.bottom,
          ),
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
              Text(
                def.etiquetaNuevo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              const SizedBox(height: 16),
              for (final (label, hint) in def.campos) ...[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Paleta.textoMedio,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  style: const TextStyle(fontSize: 14, color: Paleta.texto),
                  decoration: decoracionCampo(hint),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Paleta.borde),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        tr('comun.cancelar'),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Paleta.textoMedio,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Paleta.primario,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(tr('comun.proxima_etapa')),
                          ),
                        );
                      },
                      child: Text(
                        tr('comun.guardar'),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Paleta.blanco,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
