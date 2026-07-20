import 'dart:io';

import 'package:flutter/material.dart';

import '../config/paleta.dart';
import '../services/auth_service.dart';
import '../services/idioma_service.dart';
import '../services/tienda_launcher.dart';
import 'login_view.dart';
import 'pages/categorias_page.dart';
import 'pages/clientes_page.dart';
import 'pages/compras_page.dart';
import 'pages/config_page.dart';
import 'pages/desarrollador_page.dart';
import 'pages/inicio_page.dart';
import 'pages/inventario_page.dart';
import 'pages/lista_page.dart';
import 'pages/pedidos_page.dart';
import 'pages/productos_page.dart';
import 'pages/proveedores_page.dart';
import 'pages/venta_page.dart';
import 'pages/ventas_page.dart';

/// Shell principal del negocio (mockup ejemplo.html): header con menú,
/// contenido por módulo, barra inferior y menú lateral con secciones.
class HomeView extends StatefulWidget {
  final Session session;

  const HomeView({super.key, required this.session});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Session _session = widget.session;
  String _modulo = 'inicio';

  @override
  void initState() {
    super.initState();
    // El selector de idioma se abre desde Configuración (dentro de este
    // shell): hay que redibujar todo el shell al instante cuando cambia
    // (la reconstrucción de MaterialApp no llega hasta aquí porque los
    // widgets const y las rutas no se reconstruyen).
    IdiomaService.instance.addListener(_idiomaCambiado);
  }

  void _idiomaCambiado() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    IdiomaService.instance.removeListener(_idiomaCambiado);
    super.dispose();
  }

  Map<String, (String, IconData)> get _modulos => {
        'venta': (tr('menu.venta'), Icons.bolt),
        'ventas': (tr('menu.ventas'), Icons.north_east),
        'pedidos': (tr('menu.pedidos'), Icons.schedule),
        'inventario': (tr('menu.inventario'), Icons.swap_vert),
        'productos': (tr('menu.productos'), Icons.grid_view),
        'categorias': (tr('menu.categorias'), Icons.category_outlined),
        'compras': (tr('menu.compras'), Icons.south_west),
        'clientes': (tr('menu.clientes'), Icons.person_outline),
        'proveedores': (tr('menu.proveedores'), Icons.local_shipping_outlined),
        'config': (tr('menu.config'), Icons.settings_outlined),
      };

  static const List<(String, List<String>)> _secciones = [
    ('menu.seccion_caja', ['venta', 'ventas', 'pedidos', 'inventario']),
    (
      'menu.seccion_admin',
      [
        'productos',
        'categorias',
        'compras',
        'clientes',
        'proveedores',
        'config',
      ],
    ),
  ];

  String get _titulo {
    if (_modulo == 'inicio') {
      return trp('inicio.hola', {'nombre': _session.user.name.split(' ').first});
    }
    if (_modulo == 'venta') return tr('menu.venta');
    if (_modulo == 'config') return tr('menu.config_corto');
    if (_modulo == 'pedidos') return tr('pedidos.titulo');
    return _modulos[_modulo]?.$1 ?? tr('app.nombre');
  }

  void _irModulo(String modulo) {
    setState(() => _modulo = modulo);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('sesion.cerrar')),
        content: Text(tr('sesion.confirmar')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('comun.cancelar')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Paleta.primario),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('sesion.cerrar')),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    // Diálogo de carga mientras se cierra la sesión; lo quita el
    // pushAndRemoveUntil de abajo junto con el resto de las rutas.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Paleta.blanco,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Paleta.primario,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  tr('sesion.cerrando'),
                  style: const TextStyle(fontSize: 14.5, color: Paleta.texto),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await AuthService.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  void _abrirTienda() => abrirTienda(context, _session.user.empresa);

  void _abrirDesarrollador() {
    _scaffoldKey.currentState?.closeDrawer();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesarrolladorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Paleta.fondo,
      drawer: _menuLateral(),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _contenido()),
          ],
        ),
      ),
      // Con el teclado abierto (p. ej. formulario de Configuración) la barra
      // subía junto con el teclado y se sobreponía al contenido; se oculta.
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : _barraInferior(),
    );
  }

  Widget _contenido() {
    switch (_modulo) {
      case 'inicio':
        return InicioPage(session: _session, onIrModulo: _irModulo);
      case 'venta':
        return VentaPage(session: _session);
      case 'ventas':
        return VentasPage(session: _session);
      case 'productos':
        return ProductosPage(session: _session);
      case 'categorias':
        return CategoriasPage(session: _session);
      case 'clientes':
        return ClientesPage(session: _session);
      case 'proveedores':
        return ProveedoresPage(session: _session);
      case 'compras':
        return ComprasPage(session: _session);
      case 'inventario':
        return InventarioPage(session: _session);
      case 'pedidos':
        return PedidosPage(session: _session);
      case 'config':
        return ConfigPage(
          session: _session,
          onSessionActualizada: (s) => setState(() => _session = s),
        );
      default:
        return ListaPage(key: ValueKey(_modulo), modulo: _modulo);
    }
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          _botonCuadrado(
            icono: Icons.menu,
            fondo: Paleta.blanco,
            color: Paleta.texto,
            borde: true,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Paleta.texto,
              ),
            ),
          ),
          _botonCuadrado(
            icono: Icons.storefront_outlined,
            fondo: Paleta.primario,
            color: Paleta.blanco,
            onTap: _abrirTienda,
          ),
        ],
      ),
    );
  }

  Widget _botonCuadrado({
    required IconData icono,
    required Color fondo,
    required Color color,
    required VoidCallback onTap,
    bool borde = false,
  }) {
    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: borde ? Border.all(color: Paleta.borde) : null,
          ),
          child: Icon(icono, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _barraInferior() {
    final items = [
      ('inicio', Icons.home_outlined, tr('menu.inicio')),
      ('venta', Icons.bolt, tr('menu.venta')),
      ('pedidos', Icons.schedule, tr('menu.pedidos_corto')),
      ('menu', Icons.menu, tr('menu.menu')),
    ];

    // SafeArea: en Android con barra de gestos/botones el sistema tapaba
    // la barra; el inset inferior lo aporta el propio sistema.
    return Container(
      decoration: const BoxDecoration(
        color: Paleta.blanco,
        border: Border(top: BorderSide(color: Paleta.bordeSuave)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              for (final (id, icono, label) in items)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (id == 'menu') {
                        _scaffoldKey.currentState?.openDrawer();
                      } else {
                        _irModulo(id);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _modulo == id
                                ? Paleta.tinte
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icono,
                            size: 19,
                            color: _modulo == id
                                ? Paleta.primario
                                : Paleta.grisClaro,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _modulo == id
                                ? Paleta.primario
                                : Paleta.grisClaro,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuLateral() {
    final user = _session.user;
    final empresa = user.empresa;

    return Drawer(
      backgroundColor: Paleta.blanco,
      width: 320,
      child: Column(
        children: [
          Container(
            color: Paleta.tinte,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 10,
              8,
              12,
            ),
            child: Row(
              children: [
                _avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Paleta.texto,
                        ),
                      ),
                      Text(
                        '${tr('menu.administrador')} · ${empresa?.nombre ?? user.email}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Paleta.primarioOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              children: [
                for (final (seccion, ids) in _secciones) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
                    child: Text(
                      tr(seccion).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFFB3A89F),
                      ),
                    ),
                  ),
                  for (final id in ids) _itemMenu(id),
                ],
                const Divider(height: 24, color: Paleta.bordeSuave),
                _itemAccion(
                  icono: Icons.code_rounded,
                  titulo: tr('menu.desarrollador'),
                  onTap: _abrirDesarrollador,
                ),
                const SizedBox(height: 2),
                _itemAccion(
                  icono: Icons.logout,
                  titulo: tr('sesion.cerrar'),
                  color: Paleta.alertaTexto,
                  onTap: _cerrarSesion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final user = _session.user;

    ImageProvider? imagen;
    if (user.photoLocal != null && File(user.photoLocal!).existsSync()) {
      imagen = FileImage(File(user.photoLocal!));
    } else if (user.photoUrl != null) {
      imagen = NetworkImage(user.photoUrl!);
    }

    final iniciales = user.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: 24,
      backgroundColor: Paleta.primario,
      foregroundImage: imagen,
      child: Text(
        iniciales,
        style: const TextStyle(
          color: Paleta.blanco,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Item del menú lateral para una acción que no es un módulo del negocio
  /// (Desarrollador, Cerrar sesión): mismo estilo que `_itemMenu` pero sin
  /// estado "activo" y con color opcional (rojo para Cerrar sesión).
  Widget _itemAccion({
    required IconData icono,
    required String titulo,
    required VoidCallback onTap,
    Color? color,
  }) {
    final col = color ?? Paleta.texto;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, size: 17, color: col),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: col,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemMenu(String id) {
    final (titulo, icono) = _modulos[id]!;
    final activo = _modulo == id;

    return Material(
      color: activo ? Paleta.tinte : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _irModulo(id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: activo ? Paleta.primario : const Color(0xFFF4F0EC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icono,
                  size: 17,
                  color: activo ? Paleta.blanco : Paleta.textoSuave,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                    color: activo ? Paleta.primarioOscuro : Paleta.texto,
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
