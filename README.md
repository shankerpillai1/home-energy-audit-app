* [Home Energy Audit (Flutter)](#home-energy-audit-flutter)

  * [Project Overview](#project-overview)

    * [Goals](#goals)
    * [Non-Goals](#non-goals)
    * [Target Platforms](#target-platforms)
    * [Status / Milestones](#status--milestones)
  * [How to Run](#how-to-run)

    * [Prerequisites](#prerequisites)
    * [Setup](#setup)
    * [Build & Launch](#build--launch)
    * [Debug Tips](#debug-tips)
  * [What You Can Do (Features)](#what-you-can-do-features)

    * [Assistant](#assistant)
    * [Leakage (Seal Air Leaks)](#leakage-seal-air-leaks)
    * [Retrofits Catalog](#retrofits-catalog)
    * [Account & Settings](#account--settings)
  * [User Flows](#user-flows)

    * [Auth → Intro → Home](#auth--intro--home)
    * [Bottom Tabs](#bottom-tabs)
    * [Leakage Journey](#leakage-journey)
  * [Architecture & Engineering Details (for developers)](#architecture--engineering-details-for-developers)
    * [Layered Design](#layered-design)
    * [Directory Layout](#directory-layout)
    * [Data Model & Schemas](#data-model--schemas)
    * [State Management (Riverpod)](#state-management-riverpod)
    * [Navigation (GoRouter)](#navigation-gorouter)
    * [Repository Pattern](#repository-pattern)
    * [Services](#services)
    * [Storage Strategy (Hybrid Files + JSON)](#storage-strategy-hybrid-files--json)
    * [Media Handling](#media-handling)
    * [Error Handling & Logging](#error-handling--logging)
    * [Testing & Mocks](#testing--mocks)
  * [Leakage Module (Current Focus)](#leakage-module-current-focus)

    * [Task States & Transitions](#task-states--transitions)
    * [Dashboard (Buckets + Bottom Sheets)](#dashboard-buckets--bottom-sheets)
    * [Task Page (Observations, Camera/Upload)](#task-page-observations-cameraupload)
    * [Report Page (Points, Markers, Suggestions)](#report-page-points-markers-suggestions)
    * [Submit & Analyze (Mock Backend)](#submit--analyze-mock-backend)
  * [Extending the App (Adding a Retrofit)](#extending-the-app-adding-a-retrofit)

    * [Module Template](#module-template)
    * [Routing & Assistant Deep Links](#routing--assistant-deep-links)
    * [Choosing Data Shapes](#choosing-data-shapes)
  * [Debugging & Dev Utilities](#debugging--dev-utilities)

    * [Workspace Mirroring](#workspace-mirroring)
    * [In-App Debug Actions](#in-app-debug-actions)
    * [Common Warnings](#common-warnings)
  * [Roadmap](#roadmap)

    * [Near-Term](#near-term)
    * [Mid-Term](#mid-term)
    * [Long-Term](#long-term)
  * [Security & Privacy](#security--privacy)

    * [Data Residency](#data-residency)
    * [PII Handling](#pii-handling)
  * [Glossary](#glossary)
  * [Changelog](#changelog)

---

# Home Energy Audit (Flutter)

> Outline only — detailed content for each section will be filled in follow-up responses.

---

## Project Overview

The **Home Energy Audit** app helps households find and act on energy‑saving opportunities with a clean, guided experience. It ships as a Flutter app (Android first) and uses a modular design so new retrofit domains (e.g., thermostat, appliances) can be added without touching core flows.

### Goals

* **Self‑service audits** on a phone: capture media, get guidance, and receive prioritized actions.
* **Modular retrofits**: each domain (e.g., *Seal Air Leaks*) is a pluggable module with its own screens, data shapes, and repository.
* **Assistant‑guided UX**: a lightweight scripted assistant surfaces the next best step and deep‑links into modules.
* **Offline‑first storage**: tasks and media are persisted on device with a **hybrid file layout** (per‑task JSON + indexed listing; media stored as files).
* **Maintainable architecture**: unidirectional data flow (UI ↔ providers ↔ repositories ↔ services), clear contracts, and testable boundaries.

### Non-Goals

* Running production ML models on‑device or operating a real cloud backend (currently **mocked** analysis service).
* Multi‑tenant user management or cross‑device sync (future work).
* Full task orchestration for *all* retrofit domains (only **Leakage** is functional now; others are placeholders).

### Target Platforms

* **Android**: primary target and fully supported for development/testing.
* **iOS / Web**: planned; most code is portable by design, but platform integration (camera/storage) needs work before release.

### Status / Milestones

**Done**

* Auth (register/login), Intro survey scaffold, Home with bottom tabs.
* Assistant flow with deep link into **Leakage**.
* Leakage module v1:

  * Dashboard with buckets and bottom‑sheet lists.
  * Task page with **Observations** (RGB/Thermal) and image picker/camera.
  * File‑backed repository (**per‑task JSON** + module index.json) and workspace mirroring for desktop debug.
  * Mock backend that generates a **LeakReport** with points/markers/suggestions.
  * Report page with markers overlay and add‑to‑todo placeholder.
  * Task lifecycle states (**draft → open → closed**) wired to dashboard buckets.
* Account tab with: clear leakage data, clear all preferences, edit intro (WIP).

**In Progress / Next**

* Persist real Intro answers and allow editing from Account.
* To‑Do list surface and plumbing from Report suggestions.
* Replace mock analysis with a real HTTP backend.
* iOS build fixes (camera/storage permissions) and responsive/web polish.

---

## How to Run

### Prerequisites

* **Flutter 3.x** (stable channel recommended)
* **Android SDK** with a device or emulator; iOS build requires Xcode (optional for now)
* Dart/Flutter extensions for your IDE (VS Code or Android Studio)

### Setup

1. Clone the repo and open it in your IDE.
2. Run `flutter pub get`.
3. (Android only) Ensure an emulator or real device is connected: `flutter devices`.
4. Optional for desktop debugging of JSON: the app can mirror user data into your **workspace** (see *Debugging & Dev Utilities → Workspace Mirroring*).

### Build & Launch

* **Run**: `flutter run`
* **Hot reload**: press `r` in the terminal (or use IDE action)
* **Clean build**: `flutter clean && flutter pub get`

### Debug Tips

* If camera/gallery is unavailable in emulator, use a physical device.
* Use the **bug icon** on Leakage Dashboard to print paths and counts to console.
* If JSON layout changes during development, you can clear module data from **Account → Storage & Data**.

---

## What You Can Do (Features)

### Assistant

Guided entry point that suggests next steps and deep-links into modules (currently routes into **Seal Air Leaks**).

### Leakage (Seal Air Leaks)

* Create/edit **tasks** with one or more **observations** (RGB + Thermal pairs).
* Upload from gallery or capture via camera.
* Submit for analysis (mock backend) → generates a **LeakReport** with points, markers, and suggestions.
* Manage task lifecycle: **draft → open → closed**.
* Swipe-to-delete in lists with **Undo** snackbars.

### Retrofits Catalog

Grid of retrofit categories. Leakage is implemented; others are placeholders ready for future modules (LED, Thermostat, AC, Washer, etc.).

### Account & Settings

* Clear **Leakage** module data (per-user).
* Clear **all** app preferences (dev only helper).
* Edit Intro answers (WIP) and view account info.

---

## User Flows

### Auth → Intro → Home

1. **Register** or **Login** (local dev auth).
2. **Intro survey** (profile flags saved to preferences; full persistence WIP).
3. Land on **Home** (bottom tabs). The **Assistant** FAB is visible on the Home tab.

### Bottom Tabs

* **Home**: savings summary + lists (projects/reminders/done).
* **Retrofits**: browse modules; tap **Seal Air Leaks** to open Leakage Dashboard.
* **Tab 3/4**: placeholders.
* **Account**: profile & storage controls.

### Leakage Journey

* **Dashboard** shows three buckets: **Draft**, **Open**, **Closed**.
* Tapping a bucket opens a **bottom sheet** with tasks, each with a thumbnail and swipe actions.
* Tap a task:

  * If **Draft** → Task Page (edit + submit).
  * If **Open/Closed** → Report Page.
* In **Report**, expand individual **points** to see a marked image and suggestions; update task state via chips.

---

## Architecture & Engineering Details (for developers)

### Layered Design

* **UI**: pages & widgets → dumb as possible; react to provider state.
* **Providers (Riverpod)**: orchestrate use-cases and expose immutable state.
* **Repositories**: abstract persistence; current impl is file-backed.
* **Services**: low-level helpers (auth, settings, file I/O, mock backend).

### Directory Layout

[Developer Deep Dive (Addendum)](./docs/DEVELOPER_DEEP_DIVE.md)

See `lib/` tree in the repo. Key areas:

* `models/`: `leakage_task.dart` defines `LeakageTask`, `LeakReport`, `LeakReportPoint`, etc.
* `providers/`: `user_provider.dart`, `leakage_task_provider.dart`, `repository_providers.dart` (DI wiring).
* `repositories/`: `task_repository.dart` (contract), `file_backed_task_repository.dart` (file impl).
* `services/`: `file_storage_service.dart`, `backend_api_service.dart`, `auth_service.dart`, `settings_service.dart`.
* `ui/`: auth, intro, home tabs, and leakage pages.

### Data Model & Schemas

* **LeakageTask**: id, title, type, `photoPaths` (module-relative), `createdAt`, `state` = `draft|open|closed`, optional `decision` & `closedResult`, and optional `report`.
* **LeakReport**: energy/savings/severity summary plus `points[]`.
* **LeakReportPoint**: title, subtitle, (thumb|image) module-relative paths, optional marker rect (x,y,w,h in 0..1), and `suggestions[]`.

### State Management (Riverpod)

* `user_provider.dart`: tracks `uid`, `isLoggedIn`, `completedIntro`; exposes actions (login/logout, mark intro complete, clear caches).
* `leakage_task_provider.dart`: CRUD + lifecycle transitions, and `submitForAnalysis()` which calls the mock backend and persists a report.

### Navigation (GoRouter)

* Redirect guards for auth/intro.
* Key routes: `/home`, `/assistant`, `/leakage/dashboard`, `/leakage/task/:id`, `/leakage/report/:id`.

### Repository Pattern

* `TaskRepository` abstracts: `fetchAll`, `fetchById`, `upsert`, `delete`.
* `FileBackedTaskRepository` stores **one JSON per task** under `users/<uid>/<module>/tasks/` and maintains an `index.json` mirror for quick inspection.

### Services

* **AuthService**: simple local user registry for development.
* **SettingsService**: wraps SharedPreferences for flags and simple values.
* **FileStorageService**: all paths, file ops, and optional **workspace mirroring** for debug.
* **BackendApiService (mock)**: synthesizes a `LeakReport` from the task’s uploaded media.

### Storage Strategy (Hybrid Files + JSON)

* Each task is isolated in its own JSON; media saved as real files under `media/<taskId>/`.
* This avoids huge monolithic JSON and plays nicely with file choosers and image widgets.

### Media Handling

* `image_picker` for camera/gallery.
* Paths saved in tasks are **module-relative** (e.g., `media/<taskId>/obs0_thermal.jpg`); UI resolves to absolute using `FileStorageService`.

### Error Handling & Logging

* SnackBars for user feedback; `try/catch` around I/O; `debugPrint` for dev traces.
* Swipe delete offers **Undo**.

### Testing & Mocks

* The analysis pipeline is mocked via `BackendApiService`; swap with a real HTTP client by keeping the return shape (`LeakReport`).
* For unit tests, prefer injecting repositories/services via providers to substitute fakes.

---

## Leakage Module (Current Focus)

### Task States & Transitions

* **draft**: editable, not analyzed. Submitting moves it to **open**.
* **open**: report available (or pending refresh). User can: mark **planned**, **fixed**, or **won’t fix** (stored as `decision`), or close with `closedResult` (e.g., `no_leak`).
* **closed**: frozen for history; can be reopened to **open** if needed.

### Dashboard (Buckets + Bottom Sheets)

* Three cards (Draft/Open/Closed). Tap → bottom sheet with that bucket’s tasks.
* Each row: square thumbnail (first available image), title, trailing state control; left-swipe to delete (Undo).

### Task Page (Observations, Camera/Upload)

* Title + Type selector.
* **Observations** list, each with **RGB** and **Thermal** image blocks.
* Four buttons per block: **Camera** / **Upload** (for RGB and Thermal respectively).
* “Add Observation” and **Remove** per observation. **Save Locally** and **Submit & Analyze** fixed at bottom.

### Report Page (Points, Markers, Suggestions)

* Header: task title + **Modify Submission** button, then three compact summary cards (Loss / Severity / Savings).
* For each **point**: list tile with square thumbnail; tap to expand a full image with overlay rectangle (marker) and suggested fixes. Button placeholder for “Add to To‑Do”.
* State chips to toggle **Draft / Open / Closed**.

### Submit & Analyze (Mock Backend)

* `BackendApiService.analyzeLeakageTask(task, detectedCount)` generates a synthetic report using user-uploaded images (prefers thermal when present).
* The provider writes `report` back to the task and persists it via repository.

---

## Extending the App (Adding a Retrofit)

### Module Template

1. Create `ui/modules/<module>/` with `dashboard_page.dart`, `task_page.dart`, `report_page.dart` (as needed).
2. Define models under `models/` or reuse `LeakageTask` if the shape fits.
3. Add a provider similar to `leakage_task_provider.dart`.
4. Implement a repository (reuse `TaskRepository` + file-backed impl if applicable).

### Routing & Assistant Deep Links

* Add a tile in **Retrofits** tab that routes to your module dashboard.
* Optionally add an Assistant node that deep-links to your module’s route.

### Choosing Data Shapes

* Prefer **per-task JSON** + `index.json` mirror; store media as files.
* Keep fields additive; avoid breaking changes to existing keys.

---

## Debugging & Dev Utilities

### Workspace Mirroring

* During development you can mirror `users/<uid>/<module>/` into the project workspace for quick inspection.
* Toggle via `FileStorageService(enableWorkspaceMirror: true)` in `repository_providers.dart`.

### In-App Debug Actions

* Leakage Dashboard → bug icon: prints `index.json` path and repository task count.
* Account tab → **Clear Leakage Data** and **Clear All Preferences** actions.

### Common Warnings

* Java 8 deprecation warnings from some transitive Android libs are benign for debug builds.
* Emulators may lack full camera support; prefer a physical device when testing media capture.

---

## Roadmap

### Near-Term

* Persist Intro answers as a first-class profile and allow editing in Account.
* To‑Do list surface + hook suggestions from Report.
* Polished bottom sheets (search/sort) for large task lists.

### Mid-Term

* Real backend integration for Leakage analysis (HTTP + upload queue, retries).
* iOS build parity (camera/storage permissions, testing).
* Additional modules: **LED**, **Thermostat**, **AC**, **Washer**.

### Long-Term

* Cloud sync, multi-device user profiles.
* In-app education content and richer Assistant flows.
* Telemetry (opt‑in) to improve recommendations.

---

## Security & Privacy

### Data Residency

* All data is stored locally on the device under the app documents directory; optional workspace mirroring is **dev-only**.

### PII Handling

* Auth is local-only in development; no external identity provider is used.
* When a real backend is added, ensure TLS, scoped tokens, and minimal PII.

---

## Glossary

* **Task**: a user submission container (title/type/media/state/report).
* **Observation**: a pair of images (RGB, Thermal) within a task.
* **Bucket**: UI grouping by task state (Draft/Open/Closed).
* **Module**: a retrofit domain (Leakage, LED, Thermostat, ...).
* **Report / Point**: analysis output; each point references an image region and suggestions.

---

## Changelog

* **2025-08**: Leakage v1 with draft/open/closed lifecycle, mock backend, per-task JSON, bottom-sheet lists, and report UI.
* **2025-07**: Bottom tabs, Assistant integration, initial auth + intro scaffold.
* **2025-06**: Project bootstrapped; theme + routing skeleton.

## Author

**Bairun Chen**  
Email: bac128@pitt.edu
