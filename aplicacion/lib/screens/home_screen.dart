import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

/// Pantalla provisional tras el login: muestra los datos recuperados de la
/// cuenta de Google (foto, nombre, correo). Aquí irá el dashboard "Inicio"
/// o la pantalla "Registro de empresa" cuando exista el backend.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Mi cuenta',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: AppColors.textLabel),
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.backgroundAlt,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 44, color: AppColors.textMuted)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              user.displayName ?? 'Sin nombre',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 28),
            _DataCard(
              rows: {
                'UID': user.uid,
                'Proveedor': user.providerData.isNotEmpty
                    ? user.providerData.first.providerId
                    : '-',
                'Correo verificado': user.emailVerified ? 'Sí' : 'No',
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.rows});

  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (i, entry) in rows.entries.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLabel,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      entry.value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.dark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
