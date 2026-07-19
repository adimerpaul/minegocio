import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../models/producto.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
import '../widgets/campo_texto.dart';
import 'producto_editar_page.dart';

/// Estado del inventario: muestra los productos con stock crítico
/// (stock <= stock mínimo) para que el usuario reponga antes de que se acaben.
class InventarioPage extends StatefulWidget {
  final Session session;

  const InventarioPage({super.key, required this.session});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  Catalogo? _catalogo;
  String? _error;
  String _filtro = '';

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
      if (mounted) setState(() => _catalogo = catalogo);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    }
  }

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

  /// Devuelve los productos con stock crítico, ordenados del más crítico al menos.
  List<Producto> get _criticos {
    final filtro = _filtro.trim().toLowerCase();
    return _catalogo!.productos
        .where(
          (p) =>
              p.stockBajo &&
              (filtro.isEmpty ||
                  '${p.nombre} ${p.codigo} ${p.codigoBarras ?? ''} '
                          '${_nombreCategoria(p.categoriaId)}'
                      .toLowerCase()
                      .contains(filtro)),
        )
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
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

    final criticos = _criticos;
    final unidadesCriticas = criticos.fold<int>(0, (a, p) => a + p.stock);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _stat(
                  'Stock crítico',
                  '${criticos.length}',
                  alerta: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _stat(
                  'Unidades restantes',
                  '$unidadesCriticas',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: TextField(
            onChanged: (v) => setState(() => _filtro = v),
            style: const TextStyle(fontSize: 14, color: Paleta.texto),
            decoration: decoracionCampo('Buscar producto crítico…'),
          ),
        ),
        Expanded(
          child: criticos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'No hay productos con stock crítico. '
                      'Todo el inventario está bien abastecido.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Paleta.textoSuave,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  itemCount: criticos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _tarjeta(criticos[i]),
                ),
        ),
      ],
    );
  }

  Widget _stat(String label, String valor, {bool alerta = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: alerta ? Paleta.alertaFondo : Paleta.blanco,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alerta ? const Color(0xFFF5C2C2) : Paleta.bordeSuave,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: alerta ? Paleta.alertaTexto : Paleta.textoSuave,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: alerta ? Paleta.alertaTexto : Paleta.texto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Producto producto) {
    final maximo = producto.stockMinimo <= 0 ? 1 : producto.stockMinimo;
    final proporcion = (producto.stock / maximo).clamp(0.0, 1.0);

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
                      '${producto.codigo} · ${_nombreCategoria(producto.categoriaId)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Paleta.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: proporcion,
                        minHeight: 6,
                        backgroundColor: Paleta.bordeSuave,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          proporcion <= 0.25
                              ? Paleta.alertaTexto
                              : Paleta.primario,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${producto.stock} unidad${producto.stock == 1 ? '' : 'es'} · mín ${producto.stockMinimo}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Paleta.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Paleta.alertaFondo,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  producto.stock == 0 ? 'Agotado' : 'Crítico',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Paleta.alertaTexto,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
