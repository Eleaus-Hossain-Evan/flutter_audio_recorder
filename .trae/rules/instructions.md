# DHKS Flutter App — Copot / AI Agent Instructions

A concise guide for AI coding agents to be productive in this repository. For deep, task-specific rules see `.github/instructions/*.instructions.md` (loaded on demand).

## Quick context (what this app is)

- Flutter app using **Riverpod** (state), with **flutter_hooks** for UI level state management.

## High‑value patterns (read these files)

- Feature structure: `lib/features/<feature>/{application,domain,infrastructure,presentation}` — interfaces in `domain/` (I\*), impls in `infrastructure/`, providers in `application/`.
- State: `@riverpod` providers (sometimes `@Riverpod(keepAlive: true)`); provider codegen requires build_runner.
- Routing: `lib/core/router/router.dart` uses GoRouter with Riverpod; see `routing-navigation.instructions.md` for StatefulShellRoute and auth redirect patterns.
- Models: project uses the **Dart Data Class Generator** (VSCode) for model boilerplate — do NOT assume `json_serializable` for models; Riverpod/provider generation still uses `build_runner`.

## Essential commands (run from repo root)

- Install deps: `flutter pub get` ✅
- Generate Riverpod artifacts: `dart run build_runner build --delete-conflicting-outputs` (or `watch` while developing)
- Generate models: use **Dart Data Class Generator** (VSCode command palette) — do not run `build_runner` for models
- Analyze & format: `flutter analyze` and `dart format .`
- Tests: `flutter test` (unit/widget). Use `ProviderScope(overrides: [...])` to inject fakes in widget tests (see `testing.instructions.md`).
- Run app (dev flavor): `flutter run --flavor dev` (or specify device with `-d`).

## Project conventions & gotchas

- Files: `lower_snake_case.dart` · Classes: `PascalCase` · Interfaces: `I*` prefix.
- Never edit generated files (`*.g.dart`, `*.freezed.dart`).
- UI pages use `HookConsumerWidget` and `flutter_screenutil` for responsive sizes (`.w`, `.h`, `.sp`).
- Theme/style helpers are exposed as `BuildContext` extensions (`context.textTheme`, `context.color`, chainable text modifiers like `.semiBold.colorPrimary()`).

## Integration points & debugging tips

- API config and flavors: `lib/core/flavor/` (`F.config` contains base URLs and app names).
- Persistent storage: `lib/core/storage/` exposes `ILocalStorageService` / `PrefStorage` patterns.
- Logs: use `dart:developer` for structured logs; use DevTools / Flutter Inspector for UI debugging.

## Where to look (jump-to files)

- Router & auth redirects: `lib/core/router/router.dart`
- Network client: `lib/core/network/dio_client.dart` and `lib/core/network/dio_service.dart`
- App entry: `lib/main.dart`
- Theming & extensions: `lib/core/theme/`

---

If anything above is unclear or you'd like additional examples (e.g., auth flows, sample test), tell me which area to expand. ✅
