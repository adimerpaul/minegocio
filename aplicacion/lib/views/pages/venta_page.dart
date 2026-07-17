import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../widgets/campo_texto.dart';

/// Venta rápida (POS del mockup): buscador, chips por categoría, grilla de
/// productos del catálogo y resumen de la orden. El cobro se conectará al
/// backend en la siguiente etapa.
class VentaPage extends StatefulWidget {
  final Session session;

  const VentaPage({super.key, required this.session});

  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  Catalogo? _catalogo;
  String? _error;

  int? _categoriaSeleccionada; // null = Todos
  String _filtro = '';
  final Map<int, int> _orden = {}; // productoId → cantidad

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final catalogo =
          await CatalogoService.instance.listar(widget.session.token);
      if (mounted) setState(() => _catalogo = catalogo);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  List<Producto> get _productosFiltrados {
    final filtro = _filtro.trim().toLowerCase();
    return (_catalogo?.productos ?? [])
        .where((p) =>
            (_categoriaSeleccionada == null ||
                p.categoriaId == _categoriaSeleccionada) &&
            (filtro.isEmpty ||
                '${p.nombre} ${p.codigo}'.toLowerCase().contains(filtro)))
        .toList();
  }

  int get _cantidadTotal => _orden.values.fold(0, (a, b) => a + b);

  double get _total {
    var suma = 0.0;
    for (final entry in _orden.entries) {
      final producto =
          _catalogo!.productos.firstWhere((p) => p.id == entry.key);
      suma += producto.precio * entry.value;
    }
    return suma;
  }

  void _agregar(Producto producto) {
    setState(() => _orden[producto.id] = (_orden[producto.id] ?? 0) + 1);
  }

  void _quitar(Producto producto) {
    setState(() {
      final qty = _orden[producto.id] ?? 0;
      if (qty <= 1) {
        _orden.remove(producto.id);
      } else {
        _orden[producto.id] = qty - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _vistaError();
    if (_catalogo == null) {
      return const Center(
        child: CircularProgressIndicator(color: Paleta.primario),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _filtro = v),
            style: const TextStyle(fontSize: 14, color: Paleta.texto),
            decoration: decoracionCampo(
              'Nombre del producto o código',
            ),
          ),
        ),
        SizedBox(
          height: 62,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            children: [
              _chip('Todos', null),
              for (final c in _catalogo!.categorias) _chip(c.nombre, c.id),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: _productosFiltrados.length,
            itemBuilder: (context, i) => _tarjetaProducto(
              _productosFiltrados[i],
            ),
          ),
        ),
        if (_cantidadTotal > 0) _barraOrden(),
      ],
    );
  }

  Widget _vistaError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: Paleta.textoSuave),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _cargar,
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Paleta.primario),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int? categoriaId) {
    final activo = _categoriaSeleccionada == categoriaId;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: activo,
        onSelected: (_) =>
            setState(() => _categoriaSeleccionada = categoriaId),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: activo ? Paleta.blanco : Paleta.textoMedio,
        ),
        selectedColor: Paleta.primario,
        backgroundColor: Paleta.blanco,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: activo ? Paleta.primario : Paleta.borde),
        ),
      ),
    );
  }

  Widget _tarjetaProducto(Producto producto) {
    final qty = _orden[producto.id] ?? 0;

    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _agregar(producto),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: qty > 0 ? Paleta.primario : Paleta.bordeSuave,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: producto.imagenUrl == null
                          ? _imagenVacia()
                          : Image.network(
                              producto.imagenUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _imagenVacia(),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Paleta.texto,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatoMoneda(producto.precio, simbolo: _simbolo),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Paleta.primario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (qty > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Paleta.primario,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Paleta.blanco,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagenVacia() {
    return Container(
      color: Paleta.tinte,
      alignment: Alignment.center,
      child: const Icon(Icons.fastfood, size: 26, color: Paleta.grisClaro),
    );
  }

  Widget _barraOrden() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: Paleta.fondoOscuro,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _abrirResumen,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumen de la orden ($_cantidadTotal)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Paleta.blanco,
                  ),
                ),
                Text(
                  formatoMoneda(_total, simbolo: _simbolo),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Paleta.blanco,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirResumen() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final items = _orden.entries.map((e) {
              final producto =
                  _catalogo!.productos.firstWhere((p) => p.id == e.key);
              return (producto, e.value);
            }).toList();

            void refrescar() {
              setSheetState(() {});
              setState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                    const Text(
                      'Resumen de la orden',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Paleta.texto,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Toca los productos para agregarlos a la orden.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Paleta.textoSuave,
                          ),
                        ),
                      )
                    else ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final (producto, qty) in items)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            producto.nombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Paleta.texto,
                                            ),
                                          ),
                                          Text(
                                            '${formatoMoneda(producto.precio, simbolo: _simbolo)} c/u',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: Paleta.textoSuave,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _quitar(producto);
                                        refrescar();
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Paleta.textoMedio,
                                      ),
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Paleta.texto,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _agregar(producto);
                                        refrescar();
                                      },
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Paleta.primario,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(color: Paleta.bordeSuave),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total a cobrar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Paleta.textoSuave,
                              ),
                            ),
                            Text(
                              formatoMoneda(_total, simbolo: _simbolo),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Paleta.texto,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Paleta.primario,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final messenger =
                              ScaffoldMessenger.of(sheetContext);
                          Navigator.pop(sheetContext);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El cobro se conectará al servidor en la siguiente etapa.',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Cobrar ${formatoMoneda(_total, simbolo: _simbolo)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Paleta.blanco,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
