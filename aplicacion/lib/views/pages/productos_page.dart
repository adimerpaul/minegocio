import 'package:flutter/material.dart';

import '../../config/formato.dart';
import '../../config/paleta.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../widgets/campo_texto.dart';
import 'producto_editar_page.dart';

/// Gestión de productos: stats, buscador, filtro por categoría y la lista real del catálogo.
///
/// Si se abre desde [CategoriasPage], [categoriaInicial] precarga el filtro y
/// [mostrarAppBar] presenta una app bar con botón de retroceso.
class ProductosPage extends StatefulWidget {
  final Session session;
  final int? categoriaInicial;
  final bool mostrarAppBar;

  const ProductosPage({
    super.key,
    required this.session,
    this.categoriaInicial,
    this.mostrarAppBar = false,
  });

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  Catalogo? _catalogo;
  String? _error;
  String _filtro = '';
  int? _categoriaId;

  String get _simbolo => simboloMoneda(widget.session.user.empresa?.moneda);

  @override
  void initState() {
    super.initState();
    _categoriaId = widget.categoriaInicial;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final catalogo = await CatalogoService.instance.listar(
        widget.session.token,
      );
      if (mounted) setState(() => _catalogo = catalogo);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

  /// Abre "Editar producto"; al volver con cambios recarga la lista
  /// (la caché del catálogo ya viene refrescada por ProductoService).
  Future<void> _editar(Producto producto) async {
    final actualizado = await Navigator.of(context).push<Producto>(
      MaterialPageRoute(
        builder: (_) => ProductoEditarPage(
          session: widget.session,
          producto: producto,
          categorias: _catalogo!.categorias,
        ),
      ),
    );

    if (actualizado != null && mounted) _cargar();
  }

  String _nombreCategoria(int? id) {
    for (final c in _catalogo!.categorias) {
      if (c.id == id) return c.nombre;
    }
    return 'Sin categoría';
  }

  @override
  Widget build(BuildContext context) {
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

    final filtro = _filtro.trim().toLowerCase();
    final productos = _catalogo!.productos
        .where(
          (p) =>
              (_categoriaId == null || p.categoriaId == _categoriaId) &&
              (filtro.isEmpty ||
                  '${p.nombre} ${p.codigo} ${p.codigoBarras ?? ''} '
                          '${_nombreCategoria(p.categoriaId)}'
                      .toLowerCase()
                      .contains(filtro)),
        )
        .toList();
    final stockBajo = _catalogo!.productos.where((p) => p.stockBajo).length;

    final contenido = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _stat(
                  'Productos activos',
                  '${_catalogo!.productos.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _stat('Con stock bajo', '$stockBajo')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: TextField(
            onChanged: (v) => setState(() => _filtro = v),
            style: const TextStyle(fontSize: 14, color: Paleta.texto),
            decoration: decoracionCampo(
              'Buscar por nombre, código o categoría…',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
          child: InputDecorator(
            decoration: decoracionCampo('Filtrar por categoría', denso: true),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _categoriaId,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Paleta.texto,
                  size: 20,
                ),
                style: const TextStyle(fontSize: 13.5, color: Paleta.texto),
                hint: const Text(
                  'Todas las categorías',
                  style: TextStyle(fontSize: 13.5, color: Paleta.texto),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todas las categorías'),
                  ),
                  for (final c in _catalogo!.categorias)
                    DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.nombre),
                    ),
                ],
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
            ),
          ),
        ),
        Expanded(
          child: productos.isEmpty
              ? const Center(
                  child: Text(
                    'Sin resultados para tu búsqueda.',
                    style: TextStyle(fontSize: 14, color: Paleta.textoSuave),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  itemCount: productos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _tarjeta(productos[i]),
                ),
        ),
      ],
    );

    if (!widget.mostrarAppBar) return contenido;

    return Scaffold(
      backgroundColor: Paleta.fondo,
      appBar: AppBar(
        backgroundColor: Paleta.fondo,
        elevation: 0,
        iconTheme: const IconThemeData(color: Paleta.texto),
        title: const Text(
          'Productos por categoría',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Paleta.texto,
          ),
        ),
      ),
      body: SafeArea(child: contenido),
    );
  }

  Widget _stat(String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Paleta.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Paleta.bordeSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Paleta.textoSuave,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Paleta.texto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Producto producto) {
    return Material(
      color: Paleta.blanco,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editar(producto),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Paleta.bordeSuave),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: producto.imagenUrl == null
                      ? Container(
                          color: Paleta.tinte,
                          alignment: Alignment.center,
                          child: Text(
                            producto.nombre.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        )
                      : Image.network(
                          producto.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Paleta.tinte,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.fastfood,
                              size: 18,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Paleta.texto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${producto.codigo} · ${_nombreCategoria(producto.categoriaId)} · stock ${producto.stock} · mín ${producto.stockMinimo}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Paleta.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatoMoneda(producto.precio, simbolo: _simbolo),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Paleta.texto,
                    ),
                  ),
                  if (producto.stockBajo)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Paleta.alertaFondo,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Stock bajo',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Paleta.alertaTexto,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
