# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get        # Install dependencies
flutter run -d web     # Run on web (primary target)
flutter run            # Run on connected device
flutter analyze        # Static analysis (configured via analysis_options.yaml)
flutter test           # Run tests
flutter build web --release  # Production web build
```

## Architecture

This is a **Flutter admin panel** for "Travel Tours Florencia" travel agency, targeting web as primary platform.

**State Management:** BLoC (`flutter_bloc`) — events trigger logic, BLoC emits states, UI rebuilds on state changes.

**Dependency Injection:** GetIt service locator. All dependencies registered in [lib/core/di/injection_container.dart](lib/core/di/injection_container.dart) via `initDependencies()`, called at startup. Repositories are lazy singletons. **Todos los BLoCs se registran como `factory`** (única excepción: `ThemeCubit`, singleton). Nunca registres un BLoC como `lazySingleton`: un `BlocProvider` lo cerraría y GetIt seguiría devolviendo la instancia cerrada. Access via global `sl<T>()`.

**Scope de los BLoCs (Fase 2):** solo `ThemeCubit` y `AuthBloc` viven en el root ([lib/main.dart](lib/main.dart)) — son los únicos que usan Splash y Login, fuera del área autenticada. Los ~20 BLoCs de feature se proveen dentro de [lib/core/layout/admin_shell_wrapper.dart](lib/core/layout/admin_shell_wrapper.dart), que envuelve todo el navigator anidado: se crean al entrar a la app y se destruyen —cerrando su estado y el SSE— cuando el logout desmonta el shell. Providers puntuales por ruta (saldos, auditoría, historial de cliente) siguen en [lib/config/app_router.dart](lib/config/app_router.dart).

**Clean Architecture per feature:**
```
features/<name>/
├── domain/
│   ├── entities/       # Immutable business models
│   └── repositories/   # Abstract interfaces
├── data/
│   └── repositories/   # HTTP implementations (api_*.dart)
└── presentation/
    ├── bloc/           # *_bloc.dart, *_event.dart, *_state.dart
    └── screens/        # UI screens and widgets
```

**24 feature modules:** `agentes`, `auditoria`, `auth`, `bus_layouts`, `catalogue`, `clientes`, `cotizaciones`, `dashboard`, `faq`, `gallery`, `hoteles`, `info_empresa`, `notificaciones`, `pagos_realizados`, `politica_reserva`, `profile`, `proveedores`, `reservas`, `saldos_pendientes`, `service`, `settings`, `tour`, `uploads`, `whatsapp`.

## Convenciones (Fase 0 — mejora continua)

Ver [ANALISIS_Y_PLAN_MEJORAS.md](ANALISIS_Y_PLAN_MEJORAS.md) para el plan por fases.

- **`flutter analyze` debe quedar en 0 issues.** El CI corre `flutter analyze --fatal-infos`: cualquier info/warning rompe el build. Lints extra activos: `unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `avoid_print`, `prefer_const_*`.
- **Nunca `print()`** en código de producción — usar `debugPrint`.
- **Fire-and-forget:** todo `Future` no esperado debe envolverse en `unawaited(...)` (importar `dart:async`).
- **`BuildContext` tras `await`:** volver a verificar `context.mounted` (o `mounted` en State) antes de usarlo.
- **`withOpacity` está deprecado** — usar `.withValues(alpha: x)`.
- **`package:web` / `dart:html`** solo compilan en el target web/wasm, no en la VM de `flutter test`. Los tests de widget de pantallas que dependen de ellos (vía `app_router.dart`) requieren `--platform chrome` o abstraer la dependencia (planificado en Fase 5). Los unit tests de entidades/repos sí corren en la VM.
- Scripts one-off de mantenimiento viven en `tool/` (excluido del analyzer).

## Key Files

| File | Purpose |
|------|---------|
| [lib/main.dart](lib/main.dart) | Entry point; registers all BLoC providers at root |
| [lib/config/app_router.dart](lib/config/app_router.dart) | All named routes and navigation transitions |
| [lib/core/di/injection_container.dart](lib/core/di/injection_container.dart) | GetIt registrations |
| [lib/core/network/auth_client.dart](lib/core/network/auth_client.dart) | Custom `http.BaseClient` that injects JWT and auto-refreshes on 401 |
| [lib/core/layout/admin_shell.dart](lib/core/layout/admin_shell.dart) | Persistent sidebar (desktop ≥800px) / drawer (mobile) |
| [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) | Material 3 theme; colors in `app_colors.dart` |

## API

Backend: `https://api-travel-tours-5akz.vercel.app` (REST, HTTPS only).

Auth flow: login → receive `access_token` + `refresh_token` → stored via `flutter_secure_storage` → `AuthClient` injects `Authorization: Bearer {token}` on every request → on 401, auto-refresh and retry.

All repositories use `AuthClient` (injected via GetIt) rather than raw `http.Client`.

## UI & Theming

- Material 3, Google Fonts Inter, Spanish locale (`es_CO`), Colombian Peso formatting.
- Responsive breakpoint at 800px: persistent sidebar vs. drawer.
- Shimmer placeholders during async loads; staggered animations on dashboard.
