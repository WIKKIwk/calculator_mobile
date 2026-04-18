# Hisoblagich: Multi-Platform Inventory & Calculation Clients

**Project type:** Software application — cross-platform client apps for tracking product quantities and prices in production or retail workflows.

**Problem addressed:** per-worker calculation sessions, product catalog management, persistent activity records (Data); synchronization with a backend when online; fully local operation when offline.

---

## Abstract

This repository contains two complementary Flutter applications: an **online** client (`mobile_app`) that communicates with a server via GraphQL, and an **offline** client (`mobile_offline`) that requires no server and persists data on-device. A **Go** backend is provided under `mobile_server`. **GitHub Actions** builds unsigned iOS artifacts (Payload packaged as `.ipa`) and a single downloadable Windows SFX executable (`hisoblagich-offline.exe`).

**Keywords:** Flutter, GraphQL, Hive, local-first storage, Excel export, CI/CD.

---

## 1. Objectives and Functional Scope

| Area | Description |
|------|-------------|
| Calculation | Select a worker, enter products and quantities, generate line items |
| Products | Product name and price; create / update |
| Workers | User directory |
| Data | Records grouped by worker; Excel export; (offline) backup and security |

---

## 2. Architecture Overview

```
┌─────────────────┐     GraphQL      ┌─────────────────┐
│   mobile_app    │ ◄──────────────► │  mobile_server  │
│  (Flutter)      │                  │     (Go)        │
└────────┬────────┘                  └─────────────────┘
         │
         │ offline / local-only
         ▼
┌─────────────────┐
│ mobile_offline  │  Hive + on-device storage
│   (Flutter)     │
└─────────────────┘
```

The **offline** app does not require a server or external database. The **online** app uses a GraphQL client; pending operations may be queued locally when the network is unavailable.

---

## 3. Repository Layout

| Path | Contents |
|------|----------|
| `mobile_app/` | Online Flutter app (`calculator_app`) |
| `mobile_offline/` | Offline Flutter app (`calculator_offline`) |
| `mobile_server/` | GraphQL backend (Go) |
| `.github/workflows/` | CI workflows for iOS and Windows |
| `Makefile` | Convenience targets (e.g. `make run`) |

---

## 4. Technology Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter (Dart SDK ^3.11) |
| Local persistence | Hive CE, `flutter_secure_storage`, cryptography helpers |
| Networking (online) | `graphql_flutter` |
| Tabular export | `excel` (.xlsx) |
| Files & sharing | `file_picker`, `share_plus` |
| Backend | Go (`mobile_server`) |

---

## 5. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel recommended)
- Online mode + server: [Go](https://go.dev/dl/) (1.18+ recommended)
- iOS targets: Xcode / Apple toolchain
- Android: Android Studio or a device connected via `adb`

---

## 6. Local Development

### 6.1. Offline app

```bash
cd mobile_offline
flutter pub get
flutter run
```

### 6.2. Online app and server

Server (separate terminal):

```bash
cd mobile_server
go mod tidy
go run .
```

Application:

```bash
cd mobile_app
flutter pub get
flutter run
```

Configure the GraphQL endpoint and related settings in `mobile_app` (see `lib/graphql/`).

### 6.3. Makefile (optional)

```bash
make get        # refresh packages
make run        # per current Makefile (e.g. Chrome)
make run-server # Go server
```

---

## 7. Platforms and Release Builds

| Platform | Example command |
|----------|-----------------|
| Android | `flutter build apk --release` |
| iOS | `flutter build ios --release` (signing policy: local/CI) |
| Windows | `flutter build windows --release` |
| Linux | `flutter build linux --release` |
| Web | `flutter build web` |

Wide layouts use a **NavigationRail**; narrow layouts use a **NavigationBar** (breakpoint ~720 px).

---

## 8. Continuous Integration (GitHub Actions)

Workflows for the **offline** mobile project include:

- **iOS:** `flutter build ios --release --no-codesign` — Payload folder zipped as `.ipa` (no signing certificate in CI; device installation may require signing separately).
- **Windows:** `flutter build windows` — output packaged with 7-Zip SFX into a **single** `hisoblagich-offline.exe` artifact.

Workflow files: `.github/workflows/build-mobile-offline-ios.yml`, `.github/workflows/build-mobile-offline-windows.yml`.

---

## 9. Data and Privacy

On-device data is managed through Hive and secure storage modules. Choose the offline app for operation without network connectivity. End-to-end handling of user data depends on deployment policy and server configuration.

---

## 10. Documentation and Structure

- Each app subdirectory includes a short `README.md`.
- Application code is organized under `lib/` by feature.

---

## 11. Authorship and License

Source ownership rests with the repository maintainers and contributors. See the root `LICENSE` file if present.

---

*Last updated to reflect the current project layout and CI configuration.*
