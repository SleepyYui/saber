# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Saber is a cross-platform open-source handwriting notes app built with **Flutter/Dart**. It targets Android, iOS, macOS, Windows, and Linux. Notes sync via Nextcloud WebDAV with client-side AES encryption.

## Common Commands

### Setup
```bash
flutter pub get
```

### Run
```bash
flutter run
```

### Test
```bash
# Standard test run:
flutter test --coverage --no-pub

# Docker-based (recommended for golden tests on macOS):
./test.sh
./test.sh --update-goldens   # regenerate golden images

# Run a single test file:
flutter test test/<name>_test.dart
```

### Lint & Format
```bash
flutter analyze --no-pub
dart format lib scripts test --output none --set-exit-if-changed
```

### i18n (regenerate translations)
```bash
dart run slang
```

Translation sources are YAML files in `lib/i18n/*.i18n.yaml`. Generated Dart code (`strings.g.dart`) is checked in. Access translations via the global `t` accessor (e.g., `t.home.tabs.browse`).

## Architecture

### State Management
Uses **`ValueNotifier`/`ChangeNotifier` with `ListenableBuilder`** — no heavy framework. The global singleton `stows` (in `lib/data/prefs.dart`) holds all app preferences as typed `Stow<T>` fields that are `ValueNotifier<T>` instances persisting to `SharedPreferences` or `FlutterSecureStorage`.

### Routing
`go_router`. Routes defined in `App._router` in `lib/main.dart`, path constants in `lib/data/routes.dart`. Key routes: `/home/:subpage`, `/edit`, `/login`, `/logs`.

### File Format
- `.sbn2` — current format (BSON-encoded binary)
- `.sbn` — legacy format (JSON, read-only support)
- `.sba` — asset bundles for images
- Format types live in local package `packages/sbn/`

### Key Directory Layout
- `lib/components/` — reusable UI widgets (canvas/, toolbar/, navbar/, theming/, etc.)
- `lib/data/` — business logic, data models, tools, file management, sync
- `lib/data/tools/` — drawing tools extending abstract `Tool` class (`Pen`, `Eraser`, `Select`, `LaserPointer`)
- `lib/data/editor/` — core editor models (`EditorCoreInfo`, `EditorPage`, `History`, `Exporter`)
- `lib/data/file_manager/` — virtual filesystem abstraction
- `lib/data/nextcloud/` — Nextcloud sync via `SaberSyncer`/WebDAV
- `lib/pages/` — full-screen page widgets (editor, home, login, logs)
- `lib/i18n/` — translation YAML sources and generated Dart
- `packages/sbn/` — local package for `.sbn`/`.sbn2` format data types
- `packages/onyxsdk_pen/` — local package for Onyx e-ink pen SDK bridge

### Drawing/Canvas
`Stroke` stores `PointVector` objects with pressure. Rendering uses `perfect_freehand` for smooth curves and a custom GLSL shader (`shaders/pencil.frag`) for the pencil tool. `EditorPage` holds strokes, images, and typed text (via `flutter_quill`).

### Theming
`DynamicMaterialApp` (a `HookWidget`) uses `dynamic_color` for system colors, adapts to Cupertino on iOS/macOS, and Yaru on Linux. User preferences for accent color, theme mode, and platform override are in `stows`.

### Sync
`FileManager` manages the local virtual filesystem. `SaberSyncer` (from `abstract_sync` package) handles upload/download to Nextcloud WebDAV. Notes are AES-encrypted client-side before upload. Background sync on mobile uses `workmanager`.

## Code Style

Enforced via `analysis_options.yaml` (extends `package:flutter_lints/flutter.yaml`):
- **Single quotes** (`prefer_single_quotes`)
- **Package imports only** — no relative imports within `lib/` (`always_use_package_imports`)
- **`final` everywhere** — `prefer_final_fields`, `prefer_final_locals`, `prefer_final_in_for_each`
- **`const` everywhere** — `prefer_const_constructors`, `prefer_const_declarations`, `prefer_const_literals_to_create_immutables`
- **Omit obvious types** (`omit_obvious_property_types`)
- **No curly braces required** for single-statement flow control (`curly_braces_in_flow_control_structures: false`)
- **Avoid final parameters** (`avoid_final_parameters`)
- **Guard clauses over nesting** — prefer early returns
- **Flutter-style TODOs** (`flutter_style_todos`)
- **Dartdoc comments** on all public widgets, classes, and methods; avoid inline/body comments

## Commit Conventions

Follow **Conventional Commits** format with emojis plus ✨. Credit your AI model name. Keep commits small and atomic. Example:
```
fix: error with empty files 🪹✨

Fixes a bug in FileManager.readFile where ...
```

If adding translatable strings, put only English in the first commit, then a separate `i18n: auto translations 🗺️✨` commit for other languages.

## Testing

- Tests are flat in `test/` — one file per concern, named `<subject>_test.dart`
- Golden images in `test/goldens/` (use Docker via `./test.sh` for consistent rendering)
- Test utilities in `test/utils/` — mock channel handlers, mock user state, seeded random
- Demo notes in `test/demo_notes/`, SBN samples in `test/sbn_examples/` and `test/samples/`
- Setup pattern: `SharedPreferences.setMockInitialValues({})` + `FlavorConfig.setup()` at test start
- Write tests before implementation (TDD preferred per AGENTS.md)
- Never delete existing tests — failing tests indicate issues with your code

## Build Variants

Flavor/store variants via `--dart-define`:
```bash
flutter run --dart-define=FLAVOR="Google Play" --dart-define=APP_STORE="Google Play" --dart-define=UPDATE_CHECK="false"
```

Pre-build patches exist in `patches/pre/` and `patches/post/` for CI builds (F-Droid, Linux, Windows).
