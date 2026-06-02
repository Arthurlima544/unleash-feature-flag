# Learn Feature Flags

A hands-on project for exploring and comparing **Feature Flag** strategies across three platforms — Spring Boot, Angular and Flutter — using [Unleash](https://www.getunleash.io/) as the self-hosted provider.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Feature Flags](#feature-flags)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [1. Start Unleash](#1-start-unleash)
  - [2. Seed the flags](#2-seed-the-flags)
  - [3. Run the backend](#3-run-the-backend)
  - [4. Run the Angular app](#4-run-the-angular-app)
  - [5. Run the Flutter app](#5-run-the-flutter-app)
- [Switching Providers](#switching-providers)
- [Backend API Reference](#backend-api-reference)
- [How Each Platform Integrates](#how-each-platform-integrates)
  - [Spring Boot (Java)](#spring-boot-java)
  - [Angular](#angular)
  - [Flutter](#flutter)
- [Adding a New Feature Flag](#adding-a-new-feature-flag)
- [Roadmap](#roadmap)

---

## Overview

The goal of this project is to understand **how feature flags work in practice** across a realistic full-stack setup — and to evaluate self-hosted tooling before adopting it in production.

Each platform demonstrates:

- Checking if a flag is enabled before rendering a feature
- Toggling flags at runtime without restarting or redeploying
- Falling back gracefully when the flag provider is unreachable
- Scoping flags to specific platforms (backend-only, web-only, mobile-only) or sharing them across all clients (general)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Java 21, Spring Boot 3.5, Maven |
| Web frontend | Angular 20, TypeScript, Signals |
| Mobile / Web app | Flutter 3.x, Dart |
| Feature flag server | Unleash 6 (self-hosted, Docker) |
| Database | PostgreSQL 16 (Unleash storage) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Unleash Server                       │
│                    http://localhost:4242                    │
│                                                             │
│  ┌─────────────────┐        ┌──────────────────────────┐    │
│  │   Admin Panel   │        │        PostgreSQL        │    │
│  │  (browser UI)   │        │    (flag state storage)  │    │
│  └────────┬────────┘        └──────────────────────────┘    │
│           │ Admin API (/api/admin/...)                      │
└───────────┼─────────────────────────────────────────────────┘
            │
            │  ┌─────── CLIENT token ────────────────────────┐
            │  │  SDK polls every 15s (SSE + HTTP fallback)  │
            ▼  ▼
  ┌──────────────────────┐
  │   Spring Boot API    │  :8080
  │  (unleash profile)   │──── /api/flags  ────────────────────┐
  │                      │──── /api/demo   ────────────────────┤
  │  UnleashFeatureFlag  │                                     │
  │  Service (Java SDK)  │◄── Admin API calls on toggle ───────┤
  └──────────────────────┘                                     │
                                                               │
  ┌──────────────────────┐   FRONTEND token                    │
  │     Angular App      │◄── /api/frontend (SSE) ─────────────┤
  │       :4200          │──── toggle → /api/flags (backend) ──┤
  │  unleash-proxy-client│                                     │
  └──────────────────────┘                                     │
                                                               │
  ┌──────────────────────┐   FRONTEND token                    │
  │     Flutter App      │◄── /api/frontend (polls 15s) ───────┘
  │   (Chrome / Android) │──── toggle → /api/flags (backend)
  └──────────────────────┘
```

### Token types

| Token | Used by | Purpose |
|---|---|---|
| `*:*.unleash-admin-token` | Spring Boot backend | Toggle flags via Admin API |
| `default:development.unleash-client-token` | Java SDK | Read flag state server-side |
| `default:development.unleash-frontend-token` | Angular, Flutter | Read flag state client-side |

Tokens are **pre-seeded** via Docker environment variables — no manual UI setup needed on first run.

---

## Feature Flags

Eight flags are defined, organized by scope:

| Flag | Scope | Default | Description |
|---|---|:---:|---|
| `GENERAL_DARK_MODE` | All platforms | ✅ ON | Dark/light theme toggle |
| `GENERAL_NOTIFICATION_CENTER` | All platforms | ❌ OFF | Notification bell and panel |
| `BACKEND_ADVANCED_SEARCH` | Java only | ✅ ON | Advanced search endpoint with filters |
| `BACKEND_AI_RECOMMENDATIONS` | Java only | ❌ OFF | AI-powered recommendations endpoint |
| `WEB_NEW_DASHBOARD` | Angular only | ✅ ON | Redesigned dashboard layout |
| `WEB_EXPERIMENTAL_CHARTS` | Angular only | ❌ OFF | Interactive chart components |
| `MOBILE_BIOMETRIC_AUTH` | Flutter only | ✅ ON | Biometric authentication UI |
| `MOBILE_OFFLINE_MODE` | Flutter only | ❌ OFF | Offline mode banner and sync indicator |

> Changes made in the Unleash UI propagate to all clients within ~15 seconds — no deploy or restart required.

---

## Project Structure

```
learn-feature-flags/
│
├── backend/                        Spring Boot API
│   ├── src/main/java/com/learnff/
│   │   ├── config/
│   │   │   ├── FeatureFlagProperties.java   YAML flag definitions
│   │   │   ├── UnleashConfiguration.java    Unleash SDK bean (unleash profile)
│   │   │   └── WebConfig.java               CORS config
│   │   ├── controller/
│   │   │   ├── FeatureFlagController.java   /api/flags CRUD + toggle
│   │   │   └── DemoController.java          /api/demo feature-gated endpoints
│   │   ├── service/
│   │   │   ├── FeatureFlagService.java      Default: YAML-backed in-memory
│   │   │   └── UnleashFeatureFlagService.java  Unleash-backed (@Primary when profile active)
│   │   └── model/
│   │       └── FeatureFlag.java             Record (key, enabled, description, scope)
│   ├── src/main/resources/
│   │   ├── application.yml                  Flag defaults + server config
│   │   └── application-unleash.yml          Unleash connection config
│   └── pom.xml
│
├── frontend-web/                   Angular 20 app
│   └── src/app/
│       ├── core/
│       │   ├── feature-flag.model.ts        FeatureFlag type + FLAG_KEYS constants
│       │   └── feature-flag.service.ts      Unleash or backend provider (env-driven)
│       ├── shared/directives/
│       │   └── feature-flag.directive.ts    *appFeatureFlag structural directive
│       └── features/
│           ├── dashboard/                   WEB_NEW_DASHBOARD + WEB_EXPERIMENTAL_CHARTS
│           ├── notifications/               GENERAL_NOTIFICATION_CENTER
│           └── flag-manager/               Toggle UI with active provider indicator
│
├── frontend-mobile/                Flutter app
│   └── lib/
│       ├── core/
│       │   ├── feature_flag_model.dart      FeatureFlag model + FlagKeys constants
│       │   ├── feature_flag_service.dart    Base service (backend HTTP)
│       │   └── unleash_feature_flag_service.dart  Unleash Frontend API + polling
│       ├── shared/widgets/
│       │   └── feature_flag_builder.dart    Conditional widget builder
│       └── features/
│           ├── home/home_screen.dart        MOBILE_BIOMETRIC_AUTH + MOBILE_OFFLINE_MODE
│           └── settings/flag_manager_screen.dart  Toggle UI per scope
│
├── scripts/
│   └── unleash-init.sh             Seeds all 8 flags via Unleash Admin API
│
└── docker-compose.yml              Unleash server + PostgreSQL
```

---

## Getting Started

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| Java | 21+ | [sdkman.io](https://sdkman.io) or mise |
| Node.js | 20+ | [nodejs.org](https://nodejs.org) or mise |
| Angular CLI | 20+ | `npm install -g @angular/cli` |
| Flutter | 3.22+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Docker + Compose | any recent | [docker.com](https://docs.docker.com/get-docker/) |

---

### 1. Start Unleash

```bash
# From the project root
docker compose up unleash-db unleash -d
```

Wait ~30 seconds for Unleash to initialize, then open **http://localhost:4242**
Login: `admin` / `unleash4all`

---

### 2. Seed the flags

Run once after Unleash is healthy. This creates all 8 flags with their default enabled/disabled state:

```bash
./scripts/unleash-init.sh
```

Expected output:

```
Waiting for Unleash at http://localhost:4242 ...
Unleash is ready.

Creating feature flags in project 'default', environment 'development':

  Creating GENERAL_DARK_MODE ...
    ✓ GENERAL_DARK_MODE → ENABLED
  Creating GENERAL_NOTIFICATION_CENTER ...
    ○ GENERAL_NOTIFICATION_CENTER → DISABLED
  ...
Done. Open http://localhost:4242 to manage flags in the UI.
```

---

### 3. Run the backend

```bash
cd backend

# With Unleash (recommended)
./mvnw spring-boot:run -Dspring-boot.run.profiles=unleash

# Without Unleash (YAML-only, no Docker needed)
./mvnw spring-boot:run
```

API available at **http://localhost:8080**

> On first run, `./mvnw` will download Maven 3.9.9 into `~/.m2/wrapper/dists/` automatically.

---

### 4. Run the Angular app

```bash
cd frontend-web
npm install        # first time only
ng serve --port 4200
```

App available at **http://localhost:4200**

To switch between Unleash and the backend YAML provider, edit `src/environments/environment.ts`:

```typescript
useUnleash: true   // ← true = Unleash, false = Spring Boot backend
```

---

### 5. Run the Flutter app

```bash
cd frontend-mobile
flutter pub get    # first time only

flutter run -d chrome          # web browser
flutter run -d emulator-...    # Android emulator (list with: flutter devices)
```

To switch providers, edit `lib/main.dart`:

```dart
const bool _useUnleash = true;  // ← true = Unleash, false = Spring Boot backend
```

---

## Switching Providers

All three clients can work independently — either talking to Unleash directly or falling back to the Spring Boot backend. The backend itself can also run without Unleash.

| Scenario | Backend profile | Angular `useUnleash` | Flutter `_useUnleash` |
|---|:---:|:---:|:---:|
| Full Unleash stack | `unleash` | `true` | `true` |
| Backend only (no Docker) | _(default)_ | `false` | `false` |
| Mixed (backend YAML, clients direct to Unleash) | _(default)_ | `true` | `true` |

All clients have a built-in **fallback chain**:
```
Unleash Frontend API → Spring Boot backend → hardcoded defaults
```
So the app never crashes if a service is unavailable.

---

## Backend API Reference

All endpoints under `http://localhost:8080`.

### Feature Flags

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/flags` | List all flags with current state |
| `GET` | `/api/flags/{key}` | Get a single flag |
| `GET` | `/api/flags/{key}/enabled` | Returns `{ "key": "...", "enabled": true }` |
| `GET` | `/api/flags/scope/{scope}` | Filter by scope: `GENERAL`, `BACKEND`, `WEB`, `MOBILE` |
| `POST` | `/api/flags/{key}/toggle` | Toggle a flag on/off |
| `PUT` | `/api/flags/{key}` | Set flag state: `{ "enabled": true }` |
| `POST` | `/api/flags/reset` | Reset all flags to YAML defaults (not available with Unleash profile) |

### Demo endpoints (feature-gated)

| Method | Endpoint | Flag required |
|---|---|---|
| `GET` | `/api/demo/status` | — (always available) |
| `GET` | `/api/demo/notifications` | `GENERAL_NOTIFICATION_CENTER` |
| `GET` | `/api/demo/search?q=term` | `BACKEND_ADVANCED_SEARCH` |
| `GET` | `/api/demo/recommendations` | `BACKEND_AI_RECOMMENDATIONS` |

---

## How Each Platform Integrates

### Spring Boot (Java)

Uses the official [Unleash Java SDK](https://github.com/Unleash/unleash-client-java).

**Without Unleash** (`default` profile): flags are read from `application.yml`, stored in a `ConcurrentHashMap` for runtime overrides.

**With Unleash** (`unleash` profile): `UnleashFeatureFlagService` is activated via `@Primary`. It:
- Uses the SDK's `isEnabled(key)` which polls Unleash every 15s
- Calls the Unleash Admin API (`/api/admin/projects/.../environments/.../on|off`) on toggle requests
- Still reads scope and description from `application.yml` for metadata

```java
// Check a flag anywhere in the service layer
if (flagService.isEnabled("BACKEND_AI_RECOMMENDATIONS")) {
    return aiService.getRecommendations();
}
```

### Angular

Uses [`unleash-proxy-client`](https://github.com/Unleash/unleash-proxy-client-js) connecting to the Unleash **Frontend API** (`/api/frontend`).

The `FeatureFlagService` exposes Angular **Signals** so components react automatically when flags change:

```typescript
// In any component
readonly flagService = inject(FeatureFlagService);

// In template — reacts to flag changes in real time
@if (flagService.isEnabled('WEB_NEW_DASHBOARD')) {
  <app-new-dashboard />
} @else {
  <app-legacy-dashboard />
}
```

A custom structural directive is also available for inline use:

```html
<div *appFeatureFlag="'WEB_EXPERIMENTAL_CHARTS'; else basicChart">
  <app-chart />
</div>
<ng-template #basicChart>
  <p>Charts coming soon</p>
</ng-template>
```

### Flutter

No official Flutter SDK exists. This project implements direct HTTP polling of the Unleash **Frontend API** every 15 seconds, wrapped in a `ChangeNotifier` for Provider-based reactivity.

```dart
// In any widget
FeatureFlagBuilder(
  flagKey: FlagKeys.mobileBiometricAuth,
  builder: (_) => const BiometricLoginButton(),
  fallback: const PasswordLoginButton(),
)
```

Or using `context.select` for fine-grained reactivity:

```dart
final isOffline = context.select<FeatureFlagService, bool>(
  (svc) => svc.isEnabled(FlagKeys.mobileOfflineMode),
);
```

---

## Adding a New Feature Flag

**1. Define it in `backend/src/main/resources/application.yml`:**

```yaml
feature-flags:
  flags:
    MY_NEW_FEATURE:
      enabled: false
      description: "My new feature description"
      scope: WEB   # GENERAL | BACKEND | WEB | MOBILE
```

**2. Create it in Unleash** (if using the Unleash profile):

```bash
# Via the UI at http://localhost:4242
# Or extend scripts/unleash-init.sh:
setup_flag MY_NEW_FEATURE release "My new feature description" false
```

**3. Add the key constant:**

- **Angular** — `frontend-web/src/app/core/feature-flag.model.ts`
- **Flutter** — `frontend-mobile/lib/core/feature_flag_model.dart` (`FlagKeys` class)

**4. Gate your feature:**

```java
// Java
if (flagService.isEnabled("MY_NEW_FEATURE")) { ... }
```
```typescript
// Angular template
@if (flagService.isEnabled('MY_NEW_FEATURE')) { ... }
```
```dart
// Flutter
FeatureFlagBuilder(flagKey: FlagKeys.myNewFeature, builder: ...)
```

---

## Roadmap

This project is structured to test multiple Feature Flag providers by swapping the service layer. Planned evaluations:

- [x] **Baseline** — YAML-backed in-memory flags (no external dependency)
- [x] **Unleash** — self-hosted, open source
- [ ] **Flagsmith** — self-hosted alternative, REST-first approach
- [ ] **GrowthBook** — feature flags + A/B testing combined
- [ ] **OpenFeature** — vendor-neutral SDK standard (wraps any provider)
- [ ] **LaunchDarkly** — commercial benchmark for comparison
