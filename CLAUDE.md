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

**Dependency Injection:** GetIt service locator. All dependencies registered in [lib/core/di/injection_container.dart](lib/core/di/injection_container.dart) via `initDependencies()`, called at startup. BLoCs are factories; repositories are lazy singletons. Access via global `sl<T>()`.

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

**12 feature modules:** `auth`, `tour`, `settings`, `catalogue`, `dashboard`, `faq`, `service`, `politica_reserva`, `info_empresa`, `pagos_realizados`, `cotizaciones`, `whatsapp`.

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
