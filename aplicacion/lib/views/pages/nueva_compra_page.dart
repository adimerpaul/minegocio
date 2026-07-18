import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/compra.dart';
import '../../models/producto.dart';
import '../../models/proveedor.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/compra_service.dart';
import '../../services/proveedor_service.dart';
import '../widgets/campo_texto.dart';

/// Registro de una compra: proveedor (S/N por defecto, con alta rápida),
/// productos con cantidad y costo unitario, y total. Al registrar aumenta
/// el stock del inventario.
class NuevaCompraPage extends StatefulWidget {
  final Session session;

  const NuevaCompraPage({super.key, required this.session});

  @override
  State<NuevaCompraPage> createState() => _NuevaCompraPageState();
}

class _NuevaCompraPageState extends State<NuevaCompraPage> {
  Catalogo? _catalogo;
  String? _error;
  bool _guardando = false;

  List<Proveedor> _proveedores = [];
  Proveedor? _proveedor; // por defecto el S/N

  // productoId → cantidad; el costo unitario va en su controller.
  final Map<int, int> _cantidades = {};
  final Map<int, TextEditingController> _costos = {};

  // Gastos libres (aceite, gas, bolsas…): no tocan el stock.
  final List<_ItemLibre> _libres = [];

  Proveedor? get _proveedorDefault =>
      _proveedores.where((p) => p.esDefault).firstOrNull ??
      _proveedores.firstOrNull;

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    for (final c in _costos.values) {
      c.dispose();
    }
    for (final libre in _libres) {
      libre.costo.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final catalogo =
          await CatalogoService.instance.listar(widget.session.token);
      final proveedores =
          await ProveedorService.instance.listar(widget.session.token);
      if (mounted) {
        setState(() {
          _catalogo = catalogo;
          _proveedores = proveedores;
          _proveedor ??= _proveedorDefault;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  double? _costoDe(int productoId) {
    final texto = _costos[productoId]?.text.trim().replaceAll(',', '.') ?? '';
    return double.tryParse(texto);
  }

  double? _costoLibre(_ItemLibre libre) {
    return double.tryParse(libre.costo.text.trim().replaceAll(',', '.'));
  }

  double get _total {
    var suma = 0.0;
    for (final entry in _cantidades.entries) {
      suma += (_costoDe(entry.key) ?? 0) * entry.value;
    }
    for (final libre in _libres) {
      suma += (_costoLibre(libre) ?? 0) * libre.cantidad;
    }
    return suma;
  }

  bool get _sinItems => _cantidades.isEmpty && _libres.isEmpty;

  void _agregar(Producto producto) {
    setState(() {
      _cantidades[producto.id] = (_cantidades[producto.id] ?? 0) + 1;
      _costos.putIfAbsent(
        producto.id,
        // Costo inicial de referencia: el precio de venta actual.
        () => TextEditingController(text: producto.precio.toStringAsFixed(2)),
      );
    });
  }

  void _quitar(Producto producto) {
    setState(() {
      final qty = _cantidades[producto.id] ?? 0;
      if (qty <= 1) {
        _cantidades.remove(producto.id);
        _costos.remove(producto.id)?.dispose();
      } else {
        _cantidades[producto.id] = qty - 1;
      }
    });
  }

  Future<void> _registrar() async {
    if (_sinItems || _guardando) return;

    final messenger = ScaffoldMessenger.of(context);

    for (final productoId in _cantidades.keys) {
      if (_costoDe(productoId) == null) {
        final producto =
            _catalogo!.productos.firstWhere((p) => p.id == productoId);
        messenger.showSnackBar(
          SnackBar(content: Text('Costo inválido en ${producto.nombre}.')),
        );
        return;
      }
    }
    for (final libre in _libres) {
      if (_costoLibre(libre) == null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Costo inválido en ${libre.nombre}.')),
        );
        return;
      }
    }

    setState(() => _guardando = true);

    try {
      final compra = await CompraService.instance.crear(
        token: widget.session.token,
        proveedorId: _proveedor?.id,
        items: [
          for (final e in _cantidades.entries)
            CompraItemNuevo(
              productoId: e.key,
              cantidad: e.value,
              costo: _costoDe(e.key)!,
            ),
          for (final libre in _libres)
            CompraItemNuevo(
              nombre: libre.nombre,
              cantidad: libre.cantidad,
              costo: _costoLibre(libre)!,
            ),
        ],
      );

      // El stock cambió: se refresca el catálogo.
      await CatalogoService.instance
          .listar(widget.session.token, refrescar: true);

      if (!mounted) return;
      Navigator.of(context).pop<Compra>(compra);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.fondo,
      appBar: AppBar(
        backgroundColor: Paleta.fondo,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Paleta.texto,
        title: const Text(
          'Nueva compra',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Paleta.texto,
          ),
        ),
      ),
      body: SafeArea(child: _cuerpo()),
    );
  }

  Widget _cuerpo() {
    if (_error != null) {
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
    if (_catalogo == null) {
      return const Center(
        child: CircularProgressIndicator(color: Paleta.primario),
      );
    }

    final items = _cantidades.entries.map((e) {
      final producto = _catalogo!.productos.firstWhere((p) => p.id == e.key);
      return (producto, e.value);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            children: [
              _filaProveedor(),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Paleta.borde),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _abrirBuscadorProductos,
                icon: const Icon(Icons.add, size: 19, color: Paleta.primario),
                label: const Text(
                  'Agregar producto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Paleta.primario,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _sinItems
              ? const Center(
                  child: Text(
                    'Agrega productos del catálogo (aumentan el stock)\n'
                    'o gastos libres como aceite, gas o bolsas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: Paleta.textoSuave),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  itemCount: items.length + _libres.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => i < items.length
                      ? _tarjetaItem(items[i].$1, items[i].$2)
                      : _tarjetaLibre(_libres[i - items.length]),
                ),
        ),
        if (!_sinItems) _barraRegistrar(),
      ],
    );
  }

  Widget _filaProveedor() {
    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _elegirProveedor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Paleta.borde),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 19,
                color: Paleta.textoMedio,
              ),
              const SizedBox(width: 8),
              const Text(
                'Proveedor',
                style: TextStyle(fontSize: 14, color: Paleta.textoSuave),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _proveedor?.etiqueta ?? 'S/N (sin proveedor)',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Paleta.texto,
                  ),
                ),
              ),
              const Icon(Icons.expand_more, size: 19, color: Paleta.grisClaro),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaItem(Producto producto, int cantidad) {
    final costo = _costoDe(producto.id);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Paleta.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Paleta.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  producto.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Paleta.texto,
                  ),
                ),
              ),
              Text(
                costo == null
                    ? '—'
                    : formatoMoneda(costo * cantidad, simbolo: _simbolo),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Costo unitario de compra.
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _costos[producto.id],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: Paleta.texto),
                  decoration: decoracionCampo(null, denso: true).copyWith(
                    prefixText: '$_simbolo ',
                    prefixStyle: const TextStyle(
                      fontSize: 13,
                      color: Paleta.textoSuave,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _quitar(producto),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Paleta.textoMedio,
                ),
              ),
              Text(
                '$cantidad',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              IconButton(
                onPressed: () => _agregar(producto),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle, color: Paleta.primario),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaLibre(_ItemLibre libre) {
    final costo = _costoLibre(libre);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Paleta.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Paleta.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        libre.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Paleta.texto,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Paleta.tinte,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Gasto',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Paleta.primarioOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                costo == null
                    ? '—'
                    : formatoMoneda(costo * libre.cantidad, simbolo: _simbolo),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Costo unitario del gasto.
              SizedBox(
                width: 120,
                child: TextField(
                  controller: libre.costo,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 14, color: Paleta.texto),
                  decoration: decoracionCampo(null, denso: true).copyWith(
                    prefixText: '$_simbolo ',
                    prefixStyle: const TextStyle(
                      fontSize: 13,
                      color: Paleta.textoSuave,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() {
                  if (libre.cantidad <= 1) {
                    _libres.remove(libre);
                    libre.costo.dispose();
                  } else {
                    libre.cantidad--;
                  }
                }),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Paleta.textoMedio,
                ),
              ),
              Text(
                '${libre.cantidad}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => libre.cantidad++),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle, color: Paleta.primario),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barraRegistrar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: Paleta.fondoOscuro,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _guardando ? null : _registrar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _guardando ? 'Registrando compra...' : 'Registrar compra',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Paleta.blanco,
                  ),
                ),
                if (_guardando)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Paleta.blanco,
                    ),
                  )
                else
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

  /// Hoja con buscador para agregar un producto a la compra.
  void _abrirBuscadorProductos() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        var filtro = '';

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final visibles = _catalogo!.productos
                .where(
                  (p) =>
                      filtro.isEmpty ||
                      '${p.nombre} ${p.codigo}'.toLowerCase().contains(filtro),
                )
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Agregar producto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (v) => setSheetState(
                          () => filtro = v.trim().toLowerCase(),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Paleta.texto,
                        ),
                        decoration: decoracionCampo(
                          'Nombre del producto o código',
                          denso: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Compra de cosas fuera del catálogo: no tocan stock.
                      ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _agregarGastoLibre();
                        },
                        leading: const Icon(
                          Icons.receipt_long_outlined,
                          size: 20,
                          color: Paleta.primario,
                        ),
                        title: const Text(
                          'Gasto libre (aceite, gas, bolsas…)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Paleta.primario,
                          ),
                        ),
                        subtitle: const Text(
                          'No está en el catálogo; no cambia el stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: Paleta.textoSuave,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Paleta.bordeSuave),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: visibles.length,
                          itemBuilder: (context, i) {
                            final producto = visibles[i];

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              onTap: () {
                                _agregar(producto);
                                Navigator.pop(sheetContext);
                              },
                              leading: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: Paleta.primario,
                              ),
                              title: Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Paleta.texto,
                                ),
                              ),
                              subtitle: Text(
                                'Stock: ${producto.stock} · vende a '
                                '${formatoMoneda(producto.precio, simbolo: _simbolo)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Paleta.textoSuave,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Hoja para elegir el proveedor (S/N primero, buscador y alta rápida).
  Future<void> _elegirProveedor() async {
    try {
      _proveedores =
          await ProveedorService.instance.listar(widget.session.token);
    } catch (_) {
      // Se usa la lista que ya se tenía.
    }
    if (!mounted) return;

    final elegido = await showModalBottomSheet<Proveedor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        var filtro = '';

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final visibles = _proveedores
                .where(
                  (p) =>
                      filtro.isEmpty ||
                      '${p.nombre} ${p.nit ?? ''} ${p.telefono ?? ''}'
                          .toLowerCase()
                          .contains(filtro),
                )
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Proveedor de la compra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setSheetState(
                                () => filtro = v.trim().toLowerCase(),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Paleta.texto,
                              ),
                              decoration: decoracionCampo(
                                'Buscar por nombre, NIT o teléfono',
                                denso: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Alta rápida sin salir de la compra.
                          Material(
                            color: Paleta.primario,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final nuevo = await _crearProveedorRapido(
                                  sheetContext,
                                );
                                if (nuevo != null && sheetContext.mounted) {
                                  Navigator.pop(sheetContext, nuevo);
                                }
                              },
                              child: const SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(
                                  Icons.add_business_outlined,
                                  size: 20,
                                  color: Paleta.blanco,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: visibles.length,
                          itemBuilder: (context, i) {
                            final proveedor = visibles[i];
                            final activo = proveedor.id == _proveedor?.id;

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              onTap: () =>
                                  Navigator.pop(sheetContext, proveedor),
                              leading: Icon(
                                activo
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: activo
                                    ? Paleta.primario
                                    : Paleta.grisClaro,
                              ),
                              title: Text(
                                proveedor.etiqueta,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: activo
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: Paleta.texto,
                                ),
                              ),
                              subtitle: (proveedor.telefono?.isNotEmpty ??
                                      false)
                                  ? Text(
                                      'Cel. ${proveedor.telefono}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Paleta.textoSuave,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (elegido != null && mounted) {
      setState(() => _proveedor = elegido);
    }
  }

  /// Alta rápida de proveedor durante la compra: nombre, NIT y teléfono.
  Future<Proveedor?> _crearProveedorRapido(BuildContext desde) {
    final nombre = TextEditingController();
    final nit = TextEditingController();
    final telefono = TextEditingController();

    return showModalBottomSheet<Proveedor>(
      context: desde,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        var guardando = false;
        String? errorSheet;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> guardar() async {
              if (nombre.text.trim().isEmpty) {
                setSheetState(() => errorSheet = 'El nombre es obligatorio.');
                return;
              }
              setSheetState(() {
                guardando = true;
                errorSheet = null;
              });

              try {
                final nuevo = await ProveedorService.instance.crear(
                  token: widget.session.token,
                  datos: {
                    'nombre': nombre.text.trim(),
                    'nit': nit.text.trim(),
                    'telefono': telefono.text.trim(),
                  },
                );
                _proveedores = [..._proveedores, nuevo];
                if (sheetContext.mounted) Navigator.pop(sheetContext, nuevo);
              } catch (e) {
                setSheetState(() {
                  guardando = false;
                  errorSheet = '$e'.replaceFirst('Exception: ', '');
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nuevo proveedor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CampoTexto(
                        label: 'Nombre o razón social',
                        controller: nombre,
                        denso: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CampoTexto(
                              label: 'NIT',
                              controller: nit,
                              keyboardType: TextInputType.number,
                              denso: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CampoTexto(
                              label: 'Teléfono',
                              controller: telefono,
                              keyboardType: TextInputType.phone,
                              denso: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Paleta.primario,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: guardando ? null : guardar,
                        child: Text(
                          guardando ? 'Guardando...' : 'Registrar y usar',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Paleta.blanco,
                          ),
                        ),
                      ),
                      if (errorSheet != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorSheet!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Paleta.alertaTexto,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
