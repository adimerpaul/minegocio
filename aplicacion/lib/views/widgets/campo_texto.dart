import 'package:flutter/material.dart';

import '../../config/paleta.dart';

/// Campo de formulario con etiqueta, con el estilo del mockup.
/// Con [denso] el campo es más compacto (pantallas con muchos campos).
class CampoTexto extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool denso;

  const CampoTexto({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.denso = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: denso ? 14 : 15, color: Paleta.texto),
          decoration: decoracionCampo(hint, denso: denso),
        ),
      ],
    );
  }
}

/// Decoración compartida de los inputs (borde suave, foco naranja).
InputDecoration decoracionCampo(String? hint, {bool denso = false}) {
  OutlineInputBorder borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Paleta.grisClaro, fontSize: denso ? 14 : 15),
    isDense: denso,
    filled: true,
    fillColor: Paleta.blanco,
    contentPadding: denso
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.all(14),
    enabledBorder: borde(Paleta.borde),
    focusedBorder: borde(Paleta.primario),
  );
}
