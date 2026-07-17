import 'dart:io';

import 'package:flutter/material.dart';

import '../config/paleta.dart';
import '../services/auth_service.dart';
import 'login_view.dart';
import 'pages/config_page.dart';
import 'pages/inicio_page.dart';
import 'pages/lista_page.dart';
import 'pages/venta_page.dart';

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

  static const Map<String, (String, IconData)> _modulos = {
    'venta': ('Venta rápida', Icons.bolt),
    'ventas': ('Ventas', Icons.north_east),
    'pedidos': ('Mercado en línea', Icons.schedule),
    'inventario': ('Estado del inventario', Icons.swap_vert),
    'productos': ('Gestión de productos', Icons.grid_view),
    'categorias': ('Categorías', Icons.category_outlined),
    'compras': ('Compras', Icons.south_west),
    'clientes': ('Gestión de clientes', Icons.person_outline),
    'proveedores': ('Proveedores', Icons.local_shipping_outlined),
    'config': ('Configuración de empresa', Icons.settings_outlined),
  };

  static const List<(String, List<String>)> _secciones = [
    ('Menús de caja', ['venta', 'ventas', 'pedidos', 'inventario']),
    (
      'Menús de administración',
      ['productos', 'categorias', 'compras', 'clientes', 'proveedores', 'config'],
    ),
  ];

  String get _titulo {
    if (_modulo == 'inicio') {
      return 'Hola, ${_session.user.name.split(' ').first}';
    }
    if (_modulo == 'venta') return 'Venta rápida';
    if (_modulo == 'config') return 'Configuración';
    if (_modulo == 'pedidos') return 'Pedidos en línea';
    return _modulos[_modulo]?.$1 ?? 'Mi Negocio';
  }

  void _irModulo(String modulo) {
    setState(() => _modulo = modulo);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Tus datos locales se borrarán de este teléfono. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Paleta.primario),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    await AuthService.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  void _tiendaPendiente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La tienda en línea estará disponible pronto.'),
      ),
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
      bottomNavigationBar: _barraInferior(),
    );
  }

  Widget _contenido() {
    switch (_modulo) {
      case 'inicio':
        return InicioPage(session: _session, onIrModulo: _irModulo);
      case 'venta':
        return VentaPage(onIrModulo: _irModulo);
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
            onTap: _tiendaPendiente,
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
    const items = [
      ('inicio', Icons.home_outlined, 'Inicio'),
      ('venta', Icons.bolt, 'Venta rápida'),
      ('pedidos', Icons.schedule, 'Pedidos'),
      ('menu', Icons.menu, 'Menú'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Paleta.blanco,
        border: Border(top: BorderSide(color: Paleta.bordeSuave)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 18),
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
                      height: 34,
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
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
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
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
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
                        'Administrador · ${empresa?.nombre ?? user.email}',
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
                IconButton(
                  onPressed: _cerrarSesion,
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(
                    Icons.power_settings_new,
                    color: Paleta.primarioOscuro,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              children: [
                for (final (seccion, ids) in _secciones) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                    child: Text(
                      seccion.toUpperCase(),
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: activo ? Paleta.primario : const Color(0xFFF4F0EC),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icono,
                  size: 18,
                  color: activo ? Paleta.blanco : Paleta.textoSuave,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14.5,
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
