import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../config/paises.dart';
import '../../services/idioma_service.dart';

/// Muestra un bottom sheet para elegir un código de país.
/// Devuelve el código numérico seleccionado (ej. `+591`) o null si cierra.
Future<String?> mostrarSelectorPais(
  BuildContext context, {
  String? codigoActual,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Paleta.blanco,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SelectorPais(codigoActual: codigoActual),
  );
}

class _SelectorPais extends StatefulWidget {
  final String? codigoActual;

  const _SelectorPais({this.codigoActual});

  @override
  State<_SelectorPais> createState() => _SelectorPaisState();
}

class _SelectorPaisState extends State<_SelectorPais> {
  final TextEditingController _busqueda = TextEditingController();
  List<Pais> _filtrados = paises;

  @override
  void initState() {
    super.initState();
    _busqueda.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busqueda.removeListener(_filtrar);
    _busqueda.dispose();
    super.dispose();
  }

  void _filtrar() {
    final texto = _busqueda.text.toLowerCase();
    setState(() {
      _filtrados = paises.where((p) {
        return p.nombre.toLowerCase().contains(texto) ||
            p.codigo.contains(texto);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                tr('registro.codigo_pais'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _busqueda,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: tr('registro.buscar_pais'),
                  hintStyle: const TextStyle(color: Paleta.grisClaro),
                  prefixIcon:
                      const Icon(Icons.search, color: Paleta.textoSuave),
                  filled: true,
                  fillColor: Paleta.fondo,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtrados.length,
                itemBuilder: (context, index) {
                  final pais = _filtrados[index];
                  final seleccionado = pais.codigo == widget.codigoActual;

                  return ListTile(
                    leading: Text(
                      pais.bandera,
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(
                      pais.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Paleta.texto,
                      ),
                    ),
                    subtitle: Text(
                      pais.codigo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Paleta.textoSuave,
                      ),
                    ),
                    trailing: seleccionado
                        ? const Icon(Icons.check_circle, color: Paleta.primario)
                        : null,
                    onTap: () => Navigator.of(context).pop(pais.codigo),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
