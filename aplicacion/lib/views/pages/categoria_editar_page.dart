import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../models/categoria.dart';
import '../../services/auth_service.dart';
import '../../services/categoria_service.dart';
import '../../services/idioma_service.dart';
import '../widgets/campo_texto.dart';
import '../widgets/selector_imagen.dart';

/// Pantalla para crear o editar una categoría.
///
/// Si [categoria] es null se crea una nueva; de lo contrario se edita.
/// Devuelve la categoría guardada al hacer pop.
class CategoriaEditarPage extends StatefulWidget {
  final Session session;
  final Categoria? categoria;

  const CategoriaEditarPage({
    super.key,
    required this.session,
    this.categoria,
  });

  @override
  State<CategoriaEditarPage> createState() => _CategoriaEditarPageState();
}

class _CategoriaEditarPageState extends State<CategoriaEditarPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  File? _imagen;
  bool _guardando = false;
  String? _error;

  bool get _esNueva => widget.categoria == null;

  @override
  void initState() {
    super.initState();
    final c = widget.categoria;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _descripcion = TextEditingController(text: c?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen() async {
    try {
      final foto = await seleccionarImagen(context);
      if (foto == null || !mounted) return;
      setState(() => _imagen = foto);
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final datos = {
        'nombre': _nombre.text.trim(),
        'descripcion': _descripcion.text.trim(),
      };

      final guardada = _esNueva
          ? await CategoriaService.instance.crear(
              token: widget.session.token,
              datos: datos,
              imagen: _imagen,
            )
          : await CategoriaService.instance.actualizar(
              token: widget.session.token,
              categoria: widget.categoria!,
              datos: datos,
              imagen: _imagen,
            );

      if (!mounted) return;
      Navigator.of(context).pop(guardada);
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.fondo,
      appBar: AppBar(
        title: Text(
          _esNueva ? tr('categorias.nueva') : tr('categorias.editar'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Paleta.primario,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _foto()),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Paleta.alertaFondo,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Paleta.alertaTexto,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                CampoTexto(
                  label: tr('productos.nombre'),
                  controller: _nombre,
                  denso: true,
                ),
                const SizedBox(height: 14),
                CampoTexto(
                  label: tr('categorias.descripcion'),
                  controller: _descripcion,
                  denso: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Paleta.primario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _esNueva
                              ? tr('categorias.crear')
                              : tr('config.guardar'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Paleta.borde),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    tr('comun.cancelar'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Paleta.textoMedio,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _foto() {
    const lado = 132.0;

    Widget imagen;
    if (_imagen != null) {
      imagen = Image.file(
        _imagen!,
        width: lado,
        height: lado,
        fit: BoxFit.cover,
      );
    } else if (widget.categoria?.imagenUrl != null) {
      imagen = Image.network(
        widget.categoria!.imagenUrl!,
        width: lado,
        height: lado,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _sinFoto(lado),
      );
    } else {
      imagen = _sinFoto(lado);
    }

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: imagen),
        Positioned(
          right: 4,
          bottom: 4,
          child: Material(
            color: Paleta.primario,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _guardando ? null : _elegirImagen,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.photo_camera, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sinFoto(double lado) {
    return Container(
      width: lado,
      height: lado,
      color: Paleta.tinte,
      alignment: Alignment.center,
      child: const Icon(Icons.category_outlined, size: 44, color: Color(0xFFC2410C)),
    );
  }
}
