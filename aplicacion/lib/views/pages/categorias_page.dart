import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../models/categoria.dart';
import '../../services/auth_service.dart';
import '../../services/categoria_service.dart';
import '../../services/catalogo_service.dart';
import '../../services/idioma_service.dart';
import 'categoria_editar_page.dart';
import 'productos_page.dart';

/// Categorías del catálogo, con la cantidad de productos de cada una.
/// Tocar una categoría abre los productos filtrados por ella.
class CategoriasPage extends StatefulWidget {
  final Session session;

  const CategoriasPage({super.key, required this.session});

  @override
  State<CategoriasPage> createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  Catalogo? _catalogo;
  String? _error;

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

  void _verProductos(Categoria categoria) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductosPage(
          session: widget.session,
          categoriaInicial: categoria.id,
          mostrarAppBar: true,
        ),
      ),
    );
  }

  Future<void> _crear() async {
    final creada = await Navigator.of(context).push<Categoria>(
      MaterialPageRoute(
        builder: (_) => CategoriaEditarPage(session: widget.session),
      ),
    );
    if (creada != null && mounted) _cargar();
  }

  Future<void> _editar(Categoria categoria) async {
    final actualizada = await Navigator.of(context).push<Categoria>(
      MaterialPageRoute(
        builder: (_) => CategoriaEditarPage(
          session: widget.session,
          categoria: categoria,
        ),
      ),
    );
    if (actualizada != null && mounted) _cargar();
  }

  Future<void> _eliminar(Categoria categoria) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('categorias.eliminar_titulo')),
        content: Text(
            trp('categorias.eliminar_confirmar', {'nombre': categoria.nombre})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('comun.cancelar')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Paleta.primario),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('comun.eliminar')),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() => _error = null);
    try {
      await CategoriaService.instance.eliminar(
        token: widget.session.token,
        categoriaId: categoria.id,
      );
      if (mounted) _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    }
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

    return Scaffold(
      backgroundColor: Paleta.fondo,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        backgroundColor: Paleta.primario,
        icon: const Icon(Icons.add, color: Paleta.blanco),
        label: Text(
          tr('categorias.una'),
          style: const TextStyle(
            color: Paleta.blanco,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        itemCount: _catalogo!.categorias.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final categoria = _catalogo!.categorias[i];
          final cuantos = _catalogo!.productos
              .where((p) => p.categoriaId == categoria.id)
              .length;

          return Material(
            color: Paleta.blanco,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _verProductos(categoria),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Paleta.bordeSuave),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (categoria.imagenUrl != null)
                      AspectRatio(
                        aspectRatio: 640 / 341,
                        child: Image.network(
                          categoria.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Paleta.tinte,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.category_outlined,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoria.nombre,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Paleta.texto,
                                  ),
                                ),
                                if (categoria.descripcion != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    categoria.descripcion!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Paleta.textoSuave,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$cuantos ${tr('categorias.prod')}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Paleta.texto,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Paleta.textoSuave,
                            ),
                            onSelected: (value) {
                              if (value == 'editar') _editar(categoria);
                              if (value == 'eliminar') _eliminar(categoria);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, size: 18),
                                    const SizedBox(width: 8),
                                    Text(tr('comun.editar')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline, size: 18),
                                    const SizedBox(width: 8),
                                    Text(tr('comun.eliminar')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
