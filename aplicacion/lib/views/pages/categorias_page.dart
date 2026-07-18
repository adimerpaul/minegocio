import 'package:flutter/material.dart';

import '../../config/paleta.dart';
import '../../models/categoria.dart';
import '../../services/auth_service.dart';
import '../../services/catalogo_service.dart';
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

    return ListView.separated(
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
                    padding: const EdgeInsets.all(14),
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
                          '$cuantos prod.',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Paleta.texto,
                          ),
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
    );
  }
}
