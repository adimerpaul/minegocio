# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este proyecto

Sistema de gestión de negocios (compra y venta) con tienda en línea, en etapa inicial. Consta de dos partes independientes:

- `back/` — API backend en **Laravel 13** (PHP 8.3). Usa SQLite (`database/database.sqlite`) y Sanctum para tokens de API. Por ahora solo tiene el login con Google (`POST /api/auth/google`).
- `aplicacion/` — App móvil en **Flutter** (Dart SDK ^3.12), paquete `minegocio`, con estructura **MVVM** (`models/`, `views/`, `viewmodels/`, `services/`, `config/`). Por ahora solo tiene la pantalla de login.

## Objetivo de diseño: `ejemplo.html`

`ejemplo.html` (en la raíz, junto con su runtime `support.js`) es el **mockup de referencia de a dónde se quiere llegar** con la app. Es un prototipo móvil (430px de ancho) llamado "GestiónPro" con estas pantallas:

- **Login** — inicio de sesión con Gmail, o entrar como visitante a la tienda
- **Registro de empresa** — si la cuenta no está vinculada a una empresa (nombre comercial, NIT, etc.)
- **Inicio** — dashboard del negocio
- **Venta rápida** — punto de venta
- **Módulo de gestión** — administración (productos, compras, etc.)
- **Tienda en línea** — catálogo público para clientes
- **Configuración**

Paleta del mockup: fondo `#faf8f6`/`#eceae7`, texto `#221a15`, color primario naranja `#f4632c`, fuente Instrument Sans. Al implementar pantallas en Flutter, usar este mockup como guía de UI/UX.

## Comandos

### Backend (`back/`)

```bash
composer setup        # primera vez: install, .env, key, migraciones, npm
composer dev          # servidor + queue + vite en paralelo
composer test         # tests (Pest)
php artisan test --filter=NombreDelTest   # un solo test
vendor/bin/pint       # formatear código PHP (Laravel Pint)
php artisan migrate   # migraciones
```

Los tests usan **Pest** (no PHPUnit clásico): sintaxis `it('...', function () {...})` en `tests/Feature` y `tests/Unit`.

### Aplicación Flutter (`aplicacion/`)

```bash
flutter pub get       # dependencias
flutter run           # ejecutar en dispositivo/emulador
flutter test          # tests
flutter analyze       # linter (flutter_lints)
```

## Arquitectura

### Flujo de autenticación (Google → Laravel)

1. La app hace login con Google usando solo `google_sign_in` v7 (**sin** Firebase Auth ni `firebase_options.dart`; el proyecto de Firebase `mi-negocio-4e604` solo aporta los OAuth clients). El `serverClientId` (client ID web) está en `AuthService`.
2. `AuthService.signIn()` envía el ID token de Google a `POST /api/auth/google`.
3. `GoogleAuthController` verifica el token con `App\Services\GoogleTokenVerifier` (firma RS256 contra los certificados públicos de Google; emisor `accounts.google.com` y audiencia = `GOOGLE_CLIENT_ID` del `.env` — debe coincidir con el `serverClientId` de la app). **La primera vez** crea el usuario (`google_id` = claim `sub`, nombre, correo) y descarga su foto de Google convirtiéndola a **WebP** en `storage/app/public/avatars/` (requiere `php artisan storage:link`; en `photo_url` se guarda la ruta relativa `/storage/avatars/...`). En logins posteriores solo devuelve el usuario sin sobrescribir. Siempre responde `{user, token, is_new}` con un token Sanctum.
4. La app guarda el token de API y el usuario en `shared_preferences`. Si el backend falla, se revierte la sesión de Google (no quedan sesiones a medias).
5. La URL del backend se lee de `aplicacion/.env` (`API_URL=...`, cargado con `flutter_dotenv`; en release se usa `.env.production`). Emulador Android: `http://10.0.2.2:8000`; teléfono físico: IP LAN del PC con `php artisan serve --host=0.0.0.0`. El manifest de Android tiene `usesCleartextTraffic=true` solo para desarrollo.

En los tests del backend, `GoogleTokenVerifier` se mockea (`$this->mock(GoogleTokenVerifier::class)`) y la descarga de la foto se simula con `Http::fake()` + `Storage::fake('public')`; ver `tests/Feature/GoogleAuthTest.php`.

### App Flutter (`aplicacion/lib/`) — MVVM

- `config/env.dart` — lee `API_URL` del `.env` (asset de `flutter_dotenv`; `.env.example` documenta las variables).
- `models/app_user.dart` — usuario devuelto por el backend; convierte `photo_url` relativa en URL absoluta con `Env.apiUrl`.
- `services/auth_service.dart` — servicio único (`AuthService.instance`): Google (`authenticate()`, API v7) → backend → `shared_preferences`.
- `viewmodels/login_viewmodel.dart` — `ChangeNotifier`; imprime por consola nombre, correo, foto y token al iniciar sesión.
- `views/login_view.dart` — pantalla de login con la paleta del mockup.

- La autenticación es con cuenta de Google/Gmail, y una cuenta se vinculará a una empresa (ver pantallas de Login y Registro de empresa del mockup).
- `support.js` es un runtime generado para renderizar `ejemplo.html`; no editarlo.
