import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../services/idioma_service.dart';

/// Hoja inferior para elegir el idioma de la app.
/// Descarga la lista de idiomas activos del backend y, al elegir uno,
/// baja sus traducciones y reconstruye toda la interfaz.
Future<void> mostrarSelectorIdioma(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Paleta.blanco,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _SelectorIdioma(),
  );
}

class _SelectorIdioma extends StatefulWidget {
  const _SelectorIdioma();

  @override
  State<_SelectorIdioma> createState() => _SelectorIdiomaState();
}

class _SelectorIdiomaState extends State<_SelectorIdioma> {
  List<IdiomaDisponible>? _idiomas;
  String? _cambiando;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final idiomas = await IdiomaService.instance.idiomasDisponibles();
      if (mounted) setState(() => _idiomas = idiomas);
    } catch (_) {
      if (mounted) setState(() => _error = tr('comun.sin_conexion'));
    }
  }

  Future<void> _elegir(IdiomaDisponible idioma) async {
    setState(() => _cambiando = idioma.code);
    try {
      await IdiomaService.instance.cambiar(idioma.code);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _cambiando = null;
          _error = tr('comun.sin_conexion');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actual = IdiomaService.instance.codigo;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('comun.idioma'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Paleta.texto,
              ),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            if (_idiomas == null && _error == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...?_idiomas?.map(
                (idioma) => ListTile(
                  leading: Text(
                    idioma.flag,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(
                    idioma.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Paleta.texto,
                    ),
                  ),
                  trailing: _cambiando == idioma.code
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : idioma.code == actual
                          ? const Icon(Icons.check_circle,
                              color: Paleta.primario)
                          : null,
                  onTap: _cambiando == null ? () => _elegir(idioma) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
