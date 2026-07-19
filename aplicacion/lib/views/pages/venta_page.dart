import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/cliente.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/cliente_service.dart';
import '../../services/idioma_service.dart';
import '../../services/venta_service.dart';
import '../../services/voucher_service.dart';
import '../widgets/campo_texto.dart';
import 'escanear_codigo_page.dart';

/// Venta rápida (POS del mockup): buscador, chips por categoría, grilla de
/// productos del catálogo y resumen de la orden. Cobrar registra la venta
/// en el backend y descuenta el stock.
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
  bool _cobrando = false;

  List<Cliente> _clientes = [];
  Cliente? _cliente; // cliente de la venta; por defecto el S/N

  Cliente? get _clienteDefault =>
      _clientes.where((c) => c.esDefault).firstOrNull ?? _clientes.firstOrNull;

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final catalogo = await CatalogoService.instance.listar(
        widget.session.token,
      );
      final clientes = await ClienteService.instance.listar(
        widget.session.token,
      );
      if (mounted) {
        setState(() {
          _catalogo = catalogo;
          _clientes = clientes;
          _cliente ??= _clienteDefault;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  List<Producto> get _productosFiltrados {
    final filtro = _filtro.trim().toLowerCase();
    return (_catalogo?.productos ?? [])
        .where(
          (p) =>
              (_categoriaSeleccionada == null ||
                  p.categoriaId == _categoriaSeleccionada) &&
              (filtro.isEmpty ||
                  '${p.nombre} ${p.codigo} ${p.codigoBarras ?? ''}'
                      .toLowerCase()
                      .contains(filtro)),
        )
        .toList();
  }

  int get _cantidadTotal => _orden.values.fold(0, (a, b) => a + b);

  double get _total {
    var suma = 0.0;
    for (final entry in _orden.entries) {
      final producto = _catalogo!.productos.firstWhere(
        (p) => p.id == entry.key,
      );
      suma += producto.precio * entry.value;
    }
    return suma;
  }

  void _agregar(Producto producto) {
    setState(() => _orden[producto.id] = (_orden[producto.id] ?? 0) + 1);
  }

  /// Abre el escáner; si el código corresponde a un producto (código de
  /// barras/QR o código interno) lo agrega a la orden.
  Future<void> _escanearProducto() async {
    final codigo = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const EscanearCodigoPage()),
    );
    if (codigo == null || !mounted) return;

    final buscado = codigo.trim().toLowerCase();
    final producto = _catalogo!.productos
        .where(
          (p) =>
              (p.codigoBarras ?? '').toLowerCase() == buscado ||
              p.codigo.toLowerCase() == buscado,
        )
        .firstOrNull;

    final messenger = ScaffoldMessenger.of(context);
    if (producto == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(trp('venta.codigo_no_encontrado', {'codigo': codigo}))),
      );
      return;
    }

    _agregar(producto);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(trp('venta.agregado', {
          'nombre': producto.nombre,
          'cantidad': '${_orden[producto.id]}',
        })),
      ),
    );
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

  /// Registra la venta en el backend, descuenta el stock y limpia la orden.
  Future<void> _cobrar() async {
    if (_orden.isEmpty || _cobrando) return;
    setState(() => _cobrando = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final venta = await VentaService.instance.crear(
        token: widget.session.token,
        orden: Map.of(_orden),
        clienteId: _cliente?.id,
      );

      // El stock cambió: se refresca el catálogo.
      final catalogo = await CatalogoService.instance.listar(
        widget.session.token,
        refrescar: true,
      );

      if (!mounted) return;
      setState(() {
        _orden.clear();
        _catalogo = catalogo;
        _cliente = _clienteDefault; // la próxima venta vuelve al S/N
      });

      _mostrarConfirmacion(venta);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _cobrando = false);
    }
  }

  /// Hoja de venta registrada, con la opción de imprimir el voucher.
  void _mostrarConfirmacion(Venta venta) {
    final empresa = widget.session.user.empresa;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 30,
                    color: Color(0xFF1D7A3E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  trp('venta.registrada', {'codigo': venta.codigo}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Paleta.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatoMoneda(venta.total, simbolo: _simbolo)} · ${tr('venta.stock_actualizado')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Paleta.textoSuave,
                  ),
                ),
                const SizedBox(height: 18),
                if (empresa != null) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Paleta.primario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => VoucherService.instance.imprimir(
                      empresa: empresa,
                      venta: venta,
                    ),
                    icon: const Icon(Icons.print, color: Paleta.blanco),
                    label: Text(
                      tr('venta.imprimir'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.blanco,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Paleta.primario),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => VoucherService.instance.compartir(
                      empresa: empresa,
                      venta: venta,
                    ),
                    icon: const Icon(Icons.share, color: Paleta.primario),
                    label: Text(
                      tr('venta.compartir_whatsapp'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Paleta.primario,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Paleta.borde),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(
                    tr('venta.nueva'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Paleta.textoMedio,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _filtro = v),
                  style: const TextStyle(fontSize: 14, color: Paleta.texto),
                  decoration: decoracionCampo(tr('venta.buscador')),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Paleta.primario,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _cobrando ? null : _escanearProducto,
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 24,
                      color: Paleta.blanco,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 62,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            children: [
              _chip(tr('venta.todos'), null),
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
            itemBuilder: (context, i) =>
                _tarjetaProducto(_productosFiltrados[i]),
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
            child: Text(
              tr('comun.reintentar'),
              style: const TextStyle(color: Paleta.primario),
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
        onSelected: (_) => setState(() => _categoriaSeleccionada = categoriaId),
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
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
          onTap: _cobrando ? null : _abrirResumen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_cobrando) ...[
                  Text(
                    tr('venta.registrando'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Paleta.blanco,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Paleta.blanco,
                    ),
                  ),
                ] else ...[
                  Text(
                    '${tr('venta.resumen')} ($_cantidadTotal)',
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
              final producto = _catalogo!.productos.firstWhere(
                (p) => p.id == e.key,
              );
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
                    Text(
                      tr('venta.resumen'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Paleta.texto,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          tr('venta.toca_productos'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                                padding: const EdgeInsets.only(bottom: 12),
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
                                            '${formatoMoneda(producto.precio, simbolo: _simbolo)} ${tr('venta.cu')}',
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
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final elegido = await _elegirCliente(sheetContext);
                          if (elegido != null) {
                            _cliente = elegido;
                            refrescar();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 19,
                                color: Paleta.textoMedio,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('venta.cliente'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Paleta.textoSuave,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _cliente?.etiqueta ?? tr('venta.sin_nombre'),
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
                              const Icon(
                                Icons.expand_more,
                                size: 19,
                                color: Paleta.grisClaro,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: Paleta.bordeSuave),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('venta.total_cobrar'),
                              style: const TextStyle(
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
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _cobrar();
                        },
                        child: Text(
                          '${tr('venta.cobrar')} ${formatoMoneda(_total, simbolo: _simbolo)}',
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

  /// Hoja para elegir el cliente de la venta (S/N primero, con buscador).
  /// Devuelve el elegido, o null si se cierra sin elegir.
  Future<Cliente?> _elegirCliente(BuildContext desde) async {
    // Por si la lista cambió desde Gestión de clientes.
    try {
      _clientes = await ClienteService.instance.listar(widget.session.token);
    } catch (_) {
      // Se usa la lista que ya se tenía.
    }
    if (!desde.mounted) return null;

    return showModalBottomSheet<Cliente>(
      context: desde,
      isScrollControlled: true,
      backgroundColor: Paleta.blanco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        var filtro = '';

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final visibles = _clientes
                .where(
                  (c) =>
                      filtro.isEmpty ||
                      '${c.nombre} ${c.nit ?? ''} ${c.telefono ?? ''}'
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
                      Text(
                        tr('venta.cliente_titulo'),
                        style: const TextStyle(
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
                                tr('venta.buscar_cliente'),
                                denso: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Alta rápida: crea el cliente sin salir de la
                          // venta y lo deja elegido.
                          Material(
                            color: Paleta.primario,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final nuevo = await _crearClienteRapido(
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
                                  Icons.person_add_alt_1,
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
                            final cliente = visibles[i];
                            final activo = cliente.id == _cliente?.id;

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              onTap: () => Navigator.pop(sheetContext, cliente),
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
                                cliente.etiqueta,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: activo
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: Paleta.texto,
                                ),
                              ),
                              subtitle: (cliente.telefono?.isNotEmpty ?? false)
                                  ? Text(
                                      '${tr('comun.cel')} ${cliente.telefono}',
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
  }

  /// Alta rápida de cliente durante la venta: solo nombre, NIT/CI y
  /// teléfono. Devuelve el cliente creado (que queda en la lista), o null.
  Future<Cliente?> _crearClienteRapido(BuildContext desde) {
    final nombre = TextEditingController();
    final nit = TextEditingController();
    final telefono = TextEditingController();

    return showModalBottomSheet<Cliente>(
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
                setSheetState(
                    () => errorSheet = tr('clientes.nombre_obligatorio'));
                return;
              }
              setSheetState(() {
                guardando = true;
                errorSheet = null;
              });

              try {
                final nuevo = await ClienteService.instance.crear(
                  token: widget.session.token,
                  datos: {
                    'nombre': nombre.text.trim(),
                    'nit': nit.text.trim(),
                    'telefono': telefono.text.trim(),
                  },
                );
                _clientes = [..._clientes, nuevo];
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
                      Text(
                        tr('clientes.nuevo'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                      const SizedBox(height: 14),
                      CampoTexto(
                        label: tr('clientes.nombre'),
                        controller: nombre,
                        denso: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CampoTexto(
                              label: tr('clientes.nit_ci'),
                              controller: nit,
                              keyboardType: TextInputType.number,
                              denso: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CampoTexto(
                              label: tr('registro.telefono'),
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
                          guardando
                              ? tr('config.guardando')
                              : tr('venta.registrar_usar'),
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
