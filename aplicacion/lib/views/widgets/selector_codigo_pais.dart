import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../config/paises.dart';
import 'selector_pais.dart';

/// Botón que muestra el código de país actual (con bandera) y abre el selector.
class SelectorCodigoPais extends StatelessWidget {
  final String? codigo;
  final ValueChanged<String?> onChanged;

  const SelectorCodigoPais({
    super.key,
    this.codigo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pais = paisPorCodigo(codigo);

    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () async {
          final seleccionado = await mostrarSelectorPais(
            context,
            codigoActual: codigo,
          );
          if (seleccionado != null) onChanged(seleccionado);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Paleta.blanco,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Paleta.borde),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pais?.bandera ?? '🌐',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 6),
              Text(
                pais?.codigo ?? '+--',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Paleta.texto,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Paleta.textoSuave,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
