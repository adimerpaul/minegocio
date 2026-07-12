# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este proyecto

Sistema de gestión de negocios (compra y venta) con tienda en línea, en etapa inicial. Consta de dos partes independientes:

- `back/` — API backend en **Laravel 13** (PHP 8.3). Recién inicializado desde el esqueleto de Laravel; solo tiene el modelo `User` y las migraciones por defecto. Usa SQLite (`database/database.sqlite`).
- `aplicacion/` — App móvil en **Flutter** (Dart SDK ^3.12), paquete `minegocio`. También recién inicializada: `lib/main.dart` es el contador de ejemplo por defecto.

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

### App Flutter (`aplicacion/lib/`)

- Login con Google vía Firebase Auth + `google_sign_in` v7 (API nueva: `authenticate()`, no `signIn()`).
- `main.dart` inicializa Firebase y usa `AuthGate` (StreamBuilder sobre `authStateChanges`) para decidir entre `LoginScreen` y `HomeScreen`.
- `services/auth_service.dart` — singleton `AuthService.instance` con `signInWithGoogle()` / `signOut()`.
- `theme.dart` — paleta `AppColors` tomada del mockup; usarla en toda pantalla nueva.
- `firebase_options.dart` es un placeholder: hay que ejecutar `flutterfire configure` para generar el real (y registrar SHA-1 + habilitar el proveedor Google en la consola de Firebase).

- El backend expondrá la API que consume la app Flutter. Aún no hay rutas de API definidas (`routes/web.php` solo tiene la ruta de bienvenida; no existe `routes/api.php` todavía — habrá que instalarlo con `php artisan install:api` cuando se empiece la API).
- La autenticación prevista es con cuenta de Google/Gmail, y una cuenta se vincula a una empresa (ver pantallas de Login y Registro de empresa del mockup).
- No es un repositorio git todavía.
- `support.js` es un runtime generado para renderizar `ejemplo.html`; no editarlo.
