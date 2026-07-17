import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../widgets/campo_texto.dart';

/// Venta rápida (POS). Todavía no hay productos registrados, así que
/// muestra el buscador y un estado vacío que lleva a Gestión de productos.
class VentaPage extends StatelessWidget {
  final ValueChanged<String> onIrModulo;

  const VentaPage({super.key, required this.onIrModulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            style: const TextStyle(fontSize: 14, color: Paleta.texto),
            decoration: decoracionCampo(
              'Nombre del producto o código de barras',
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Paleta.primario,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Todos',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Paleta.blanco,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Paleta.tinte,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.bolt,
                      size: 32,
                      color: Paleta.primario,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no tienes productos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Paleta.texto,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 260,
                    child: Text(
                      'Registra tu catálogo para empezar a vender desde el celular.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Paleta.textoSuave,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => onIrModulo('productos'),
                    child: const Text(
                      'Ir a Gestión de productos',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
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
}
