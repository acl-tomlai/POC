# Pos.Till.App

Flutter Android tablet app for the POS POC — see [PLAN.md](PLAN.md) for the full design.

The same Dart codebase ships **two flavors** from two `main` entry points:

| Flavor | Entry point | Purpose |
|---|---|---|
| `pos_till` | `lib/main.dart` | Cashier till (landscape tablet) |
| `pos_customer_display` | `lib/main_customer.dart` | Customer-facing display (mirror) |

## Current status

**Phase 1 — Scaffold + theming + routing — complete.**
**Phase 2 — API + auth + device setup + user picker + PIN flow — complete.**
**Phase 3 — Till home + cart + send-to-kitchen + ESC/POS printing — complete.**

Real Dio client (JWT injection + 401 handler + transient retry), freezed DTO mirrors of [Pos.Api/DTOs/](../Pos.Api/DTOs/), per-cashier PBKDF2 + AES-GCM JWT encryption via [`SecureCredentialsService`](lib/services/secure_credentials.dart), 5-minute idle-logout, working device-pair → user-picker → PIN-unlock → till-home flow with live product grid + category rail + cart + line-edit sheet. Send-to-kitchen does `POST /api/orders` → `PUT status=Sent` → fans the kitchen ticket out to every active kitchen-type printer for the store over raw TCP ESC/POS. Settings owns the printer pickers, drawer-kick test, and per-surface language toggles (`receipt` / `kitchen` / `display` × `en` / `vi` / `both`). Payment screen is still a Phase 4 stub.

## Prerequisites

- Flutter SDK ≥ 3.22 (stable channel)
- Android SDK + emulator / tablet
- The [Pos.Api](../Pos.Api/) running on the LAN (default `http://localhost:5202`)

## First-time setup

This repo only contains the Dart sources (`lib/`, `pubspec.yaml`). Run `flutter create` once to fill in the Android platform scaffolding:

```powershell
cd c:\Repo\POC\Pos.Till.App
flutter create . --platforms=android --org com.adaptable --project-name pos_till_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The `flutter create .` command only generates `android/` and platform glue — it will not overwrite anything in `lib/`. The `build_runner` step generates the `.freezed.dart` / `.g.dart` siblings for every model in [lib/models/](lib/models/).

## Running

```powershell
# Cashier till
flutter run -t lib/main.dart --dart-define=API_BASE_URL=http://<host-ip>:5202

# Customer display (run on a second device)
flutter run -t lib/main_customer.dart
```

## Building release APKs

```powershell
flutter build apk --target lib/main.dart
flutter build apk --target lib/main_customer.dart
```
