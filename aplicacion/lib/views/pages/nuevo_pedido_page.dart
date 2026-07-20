import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/pedido.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/idioma_service.dart';
import '../../services/pedido_service.dart';
import '../widgets/campo_texto.dart';

/// Registro manual de un pedido (mismo endpoint que usa la tienda en línea):
/// productos con cantidad y datos de contacto opcionales.
class NuevoPedidoPage extends StatefulWidget {
  final Session session;

  const NuevoPedidoPage({super.key, required this.session});

  @override
  State<NuevoPedidoPage> createState() => _NuevoPedidoPageState();
}

class _NuevoPedidoPageState extends State<NuevoPedidoPage> {
  Catalogo? _catalogo;
  String? _error;
  bool _guardando = false;

  final Map<int, int> _cantidades = {};

  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _notas = TextEditingController();

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _notas.dispose();
    super.dispose();
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

  double get _total {
    if (_catalogo == null) return 0;
    var suma = 0.0;
    for (final entry in _cantidades.entries) {
      final producto =
          _catalogo!.productos.where((p) => p.id == entry.key).firstOrNull;
      if (producto != null) suma += producto.precio * entry.value;
    }
    return suma;
  }

  bool get _sinItems => _cantidades.isEmpty;

  void _agregar(Producto producto) {
    setState(() {
      _cantidades[producto.id] = (_cantidades[producto.id] ?? 0) + 1;
    });
  }

  void _quitar(Producto producto) {
    setState(() {
      final qty = _cantidades[producto.id] ?? 0;
      if (qty <= 1) {
        _cantidades.remove(producto.id);
      } else {
        _cantidades[producto.id] = qty - 1;
      }
    });
  }

  Future<void> _registrar() async {
    if (_sinItems || _guardando) return;

    final messenger = ScaffoldMessenger.of(context);
    final empresaId = widget.session.user.empresa?.id;
    if (empresaId == null) return;

    setState(() => _guardando = true);

    try {
      final pedido = await PedidoService.instance.crear(
        empresaId: empresaId,
        items: [
          for (final e in _cantidades.entries)
            PedidoItemNuevo(productoId: e.key, cantidad: e.value),
        ],
        clienteNombre: _nombre.text.trim(),
        clienteTelefono: _telefono.text.trim(),
        direccion: _direccion.text.trim(),
        notas: _notas.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop<Pedido>(pedido);
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
        title: Text(
          tr('pedidos.nuevo'),
          style: const TextStyle(
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
              child: Text(
                tr('comun.reintentar'),
                style: const TextStyle(color: Paleta.primario),
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
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: Paleta.borde),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _abrirBuscadorProductos,
            icon: const Icon(Icons.add, size: 19, color: Paleta.primario),
            label: Text(
              tr('compras.agregar_producto'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Paleta.primario,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              if (_sinItems)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    tr('pedidos.vacio_nuevo'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13.5, color: Paleta.textoSuave),
                  ),
                )
              else
                for (final (producto, cantidad) in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _tarjetaItem(producto, cantidad),
                  ),
              const SizedBox(height: 6),
              Text(
                tr('pedidos.datos_cliente'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Paleta.texto,
                ),
              ),
              const SizedBox(height: 10),
              CampoTexto(
                label: tr('clientes.nombre'),
                controller: _nombre,
                denso: true,
              ),
              const SizedBox(height: 10),
              CampoTexto(
                label: tr('registro.telefono'),
                controller: _telefono,
                keyboardType: TextInputType.phone,
                denso: true,
              ),
              const SizedBox(height: 10),
              CampoTexto(
                label: tr('pedidos.direccion'),
                controller: _direccion,
                hint: tr('pedidos.direccion_hint'),
                denso: true,
              ),
              const SizedBox(height: 10),
              CampoTexto(
                label: tr('pedidos.notas'),
                controller: _notas,
                denso: true,
              ),
            ],
          ),
        ),
        if (!_sinItems) _barraRegistrar(),
      ],
    );
  }

  Widget _tarjetaItem(Producto producto, int cantidad) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Paleta.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Paleta.bordeSuave),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 2),
                Text(
                  formatoMoneda(producto.precio, simbolo: _simbolo),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Paleta.textoSuave,
                  ),
                ),
              ],
            ),
          ),
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
                  _guardando
                      ? tr('pedidos.registrando')
                      : tr('pedidos.registrar'),
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

  /// Hoja con buscador para agregar un producto al pedido.
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
                      Text(
                        tr('compras.agregar_producto'),
                        style: const TextStyle(
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
                          tr('venta.buscador'),
                          denso: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 340),
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
                                '${tr('productos.stock_label')}: ${producto.stock} · '
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
}
