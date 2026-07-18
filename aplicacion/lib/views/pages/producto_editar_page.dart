import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/categoria.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/producto_service.dart';
import '../widgets/campo_texto.dart';
import '../widgets/selector_imagen.dart';
import 'escanear_codigo_page.dart';

/// Pantalla "Editar producto": nombre, precio, stock, stock mínimo,
/// categoría y foto. Devuelve el producto actualizado al hacer pop.
class ProductoEditarPage extends StatefulWidget {
  final Session session;
  final Producto producto;
  final List<Categoria> categorias;

  const ProductoEditarPage({
    super.key,
    required this.session,
    required this.producto,
    required this.categorias,
  });

  @override
  State<ProductoEditarPage> createState() => _ProductoEditarPageState();
}

class _ProductoEditarPageState extends State<ProductoEditarPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _precio;
  late final TextEditingController _stock;
  late final TextEditingController _stockMinimo;
  late final TextEditingController _codigoBarras;
  int? _categoriaId;
  File? _imagen;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p.nombre);
    _precio = TextEditingController(text: p.precio.toStringAsFixed(2));
    _stock = TextEditingController(text: '${p.stock}');
    _stockMinimo = TextEditingController(text: '${p.stockMinimo}');
    _codigoBarras = TextEditingController(text: p.codigoBarras ?? '');
    _categoriaId = p.categoriaId;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _stock.dispose();
    _stockMinimo.dispose();
    _codigoBarras.dispose();
    super.dispose();
  }

  /// Pregunta de dónde sacar la foto (cámara o galería) y la carga.
  Future<void> _elegirImagen() async {
    try {
      final foto = await seleccionarImagen(context);
      if (foto == null || !mounted) return;
      setState(() => _imagen = foto);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  /// Abre el escáner y coloca el código leído en el campo.
  Future<void> _escanearCodigo() async {
    final codigo = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const EscanearCodigoPage()),
    );
    if (codigo == null || !mounted) return;
    setState(() => _codigoBarras.text = codigo);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final actualizado = await ProductoService.instance.actualizar(
        token: widget.session.token,
        producto: widget.producto,
        datos: {
          'nombre': _nombre.text.trim(),
          'precio': _precio.text.trim().replaceFirst(',', '.'),
          'stock': _stock.text.trim(),
          'stock_minimo': _stockMinimo.text.trim(),
          'codigo_barras': _codigoBarras.text.trim(),
          if (_categoriaId != null) 'categoria_id': '$_categoriaId',
        },
        imagen: _imagen,
      );

      if (!mounted) return;
      Navigator.of(context).pop(actualizado);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  double? _numero(String? v) =>
      double.tryParse((v ?? '').trim().replaceFirst(',', '.'));

  @override
  Widget build(BuildContext context) {
    final simbolo = simboloMoneda(widget.session.user.empresa?.moneda);

    return Scaffold(
      backgroundColor: Paleta.fondo,
      appBar: AppBar(
        title: Text(
          'Editar ${widget.producto.codigo}',
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
                _etiqueta('Nombre'),
                TextFormField(
                  controller: _nombre,
                  style: const TextStyle(fontSize: 15, color: Paleta.texto),
                  decoration: decoracionCampo('Nombre del producto'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _etiqueta('Precio ($simbolo)'),
                          TextFormField(
                            controller: _precio,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Paleta.texto,
                            ),
                            decoration: decoracionCampo('0.00'),
                            validator: (v) {
                              final n = _numero(v);
                              return (n == null || n < 0)
                                  ? 'Precio inválido'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _etiqueta('Stock'),
                          TextFormField(
                            controller: _stock,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Paleta.texto,
                            ),
                            decoration: decoracionCampo('0'),
                            validator: (v) {
                              final n = int.tryParse((v ?? '').trim());
                              return (n == null || n < 0)
                                  ? 'Stock inválido'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _etiqueta('Stock mínimo (alerta de stock bajo)'),
                TextFormField(
                  controller: _stockMinimo,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 15, color: Paleta.texto),
                  decoration: decoracionCampo('5'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return (n == null || n < 0) ? 'Valor inválido' : null;
                  },
                ),
                const SizedBox(height: 14),
                _etiqueta('Código QR / de barras'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codigoBarras,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Paleta.texto,
                        ),
                        decoration: decoracionCampo(
                          'Escanea o escribe el código',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Paleta.primario,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _guardando ? null : _escanearCodigo,
                        child: const Padding(
                          padding: EdgeInsets.all(13),
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _etiqueta('Categoría'),
                DropdownButtonFormField<int?>(
                  initialValue: _categoriaId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sin categoría'),
                    ),
                    ...widget.categorias.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.nombre),
                      ),
                    ),
                  ],
                  onChanged: _guardando
                      ? null
                      : (v) => setState(() => _categoriaId = v),
                  style: const TextStyle(fontSize: 15, color: Paleta.texto),
                  decoration: decoracionCampo(null),
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
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
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
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
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

  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Paleta.textoMedio,
        ),
      ),
    );
  }

  /// Foto actual (o la elegida) con el botón de cambiarla.
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
    } else if (widget.producto.imagenUrl != null) {
      imagen = Image.network(
        widget.producto.imagenUrl!,
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
      child: const Icon(Icons.fastfood, size: 44, color: Color(0xFFC2410C)),
    );
  }
}
