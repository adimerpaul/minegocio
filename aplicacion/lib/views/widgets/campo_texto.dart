import 'package:flutter/material.dart';

import '../../config/paleta.dart';

/// Campo de formulario con etiqueta, con el estilo del mockup.
class CampoTexto extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const CampoTexto({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
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
          style: const TextStyle(fontSize: 15, color: Paleta.texto),
          decoration: decoracionCampo(hint),
        ),
      ],
    );
  }
}

/// Decoración compartida de los inputs (borde suave, foco naranja).
InputDecoration decoracionCampo(String? hint) {
  OutlineInputBorder borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Paleta.grisClaro, fontSize: 15),
    filled: true,
    fillColor: Paleta.blanco,
    contentPadding: const EdgeInsets.all(14),
    enabledBorder: borde(Paleta.borde),
    focusedBorder: borde(Paleta.primario),
  );
}
