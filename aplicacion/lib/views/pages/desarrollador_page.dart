import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/paleta.dart';
import '../../models/github_perfil.dart';
import '../../services/github_service.dart';
import '../../services/idioma_service.dart';

/// Pantalla "Desarrollador": contacto del creador de la app para negocios
/// que quieran un sistema a su medida. La foto y la bio se traen en vivo
/// del perfil público de GitHub; si falla (sin conexión, límite de la API)
/// se muestran los datos de respaldo, sin bloquear la pantalla.
class DesarrolladorPage extends StatefulWidget {
  const DesarrolladorPage({super.key});

  @override
  State<DesarrolladorPage> createState() => _DesarrolladorPageState();
}

class _DesarrolladorPageState extends State<DesarrolladorPage> {
  static const _usuarioGithub = 'adimerpaul';
  static const _whatsapp = '59169603027';
  static const _nombreRespaldo = 'Adimer Paul Chambi Ajata';
  static const _avatarRespaldo = 'https://github.com/$_usuarioGithub.png';

  GithubPerfil? _perfil;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await GithubService.instance.perfil(_usuarioGithub);
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Sin conexión o límite de la API de GitHub: se queda con el respaldo.
    }
  }

  Future<void> _abrirEnlace(String url) async {
    final abierto = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('desarrollador.enlace_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = (_perfil?.nombre?.isNotEmpty ?? false)
        ? _perfil!.nombre!
        : _nombreRespaldo;
    final avatarUrl = _perfil?.avatarUrl ?? _avatarRespaldo;
    final bio = _perfil?.bio;

    final iniciales = nombre
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: Paleta.fondo,
      appBar: AppBar(
        backgroundColor: Paleta.fondo,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Paleta.texto,
        title: Text(
          tr('menu.desarrollador'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Paleta.texto,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Center(
              child: CircleAvatar(
                radius: 56,
                backgroundColor: Paleta.primario,
                foregroundImage: NetworkImage(avatarUrl),
                onForegroundImageError: (_, _) {},
                child: Text(
                  iniciales,
                  style: const TextStyle(
                    color: Paleta.blanco,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Paleta.texto,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@$_usuarioGithub',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Paleta.textoSuave),
            ),
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Paleta.textoMedio,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Paleta.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Paleta.bordeSuave),
              ),
              child: Text(
                tr('desarrollador.tagline'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Paleta.texto,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _abrirEnlace('https://wa.me/$_whatsapp'),
              icon: const Icon(Icons.chat, color: Paleta.blanco),
              label: Text(
                tr('desarrollador.whatsapp'),
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
              onPressed: () =>
                  _abrirEnlace('https://github.com/$_usuarioGithub'),
              icon: const Icon(Icons.code_rounded, color: Paleta.primario),
              label: Text(
                tr('desarrollador.github'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Paleta.primario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
