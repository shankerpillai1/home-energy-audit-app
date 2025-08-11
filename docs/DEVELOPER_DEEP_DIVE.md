# Developer Deep Dive (Addendum)

> This addendum complements the main README. It focuses on concrete code, JSON schemas, and extension points. Cross‑references point back to sections in the main doc where relevant.

---

## Directory Tree (lib/)

```text
lib/
├─ app.dart
├─ main.dart
├─ config/
│  └─ themes.dart
├─ models/
│  └─ leakage_task.dart
├─ providers/
│  ├─ repository_providers.dart
│  ├─ leakage_task_provider.dart
│  └─ user_provider.dart
├─ repositories/
│  ├─ task_repository.dart
│  └─ file_backed_task_repository.dart
├─ services/
│  ├─ auth_service.dart
│  ├─ backend_api_service.dart
│  ├─ file_storage_service.dart
│  └─ settings_service.dart
├─ ui/
│  ├─ assistant/
│  │  └─ assistant_page.dart
│  ├─ auth/
│  │  ├─ login_page.dart
│  │  └─ register_page.dart
│  ├─ intro/
│  │  └─ intro_page.dart
│  ├─ home/
│  │  ├─ home_page.dart
│  │  └─ tabs/
│  │     ├─ dashboard_tab.dart
│  │     ├─ retrofits_tab.dart
│  │     ├─ account_tab.dart
│  │     └─ placeholder_tab.dart
│  └─ modules/
│     └─ leakage/
│        ├─ dashboard_page.dart
│        ├─ task_page.dart
│        └─ report_page.dart
└─ utils/
   └─ router_refresh.dart
```

---

## JSON Schemas & Examples

### Single Task File (users/<uid>/leakage/tasks/<taskId>.json)

```json
{
  "id": "824389a5-03f5-4e43-99fb-520472718d8e",
  "title": "North window sweep",
  "type": "window",
  "photoPaths": [
    "media/824389a5/obs0_rgb.jpg",
    "media/824389a5/obs0_thermal.jpg"
  ],
  "createdAt": "2025-08-08T17:12:15.011967",
  "state": "open",
  "decision": "planned",
  "closedResult": null,
  "report": {
    "energyLossCost": "$142/year",
    "energyLossValue": "15.8 kWh/mo",
    "leakSeverity": "Moderate",
    "savingsCost": "$31/year",
    "savingsPercent": "19% reduction",
    "points": [
      {
        "title": "Detected Leak #1",
        "subtitle": "Location: N/A\nGap size: N/A\nHeat loss: N/A",
        "imagePath": "media/824389a5/obs0_thermal.jpg",
        "thumbPath": "media/824389a5/obs0_thermal.jpg",
        "markerX": 0.22,
        "markerY": 0.30,
        "markerW": 0.18,
        "markerH": 0.20,
        "suggestions": [
          {
            "title": "General Weatherstripping",
            "costRange": "$10–20",
            "difficulty": "Easy",
            "lifetime": "3–5 years",
            "estimatedReduction": "50–70%"
          }
        ]
      }
    ]
  }
}
```

### Module Index (users/<uid>/leakage/index.json)

> Maintained by the file‑backed repository for quick inspection (source of truth is per‑task JSON files).

```json
[
  { "id": "...", "title": "...", "state": "draft", "createdAt": "..." },
  { "id": "...", "title": "...", "state": "open",  "createdAt": "..." }
]
```

---

## Provider Wiring (Riverpod)

```dart
// providers/repository_providers.dart
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService(enableWorkspaceMirror: true); // dev helper
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';
  return FileBackedTaskRepository(fs, uid: uid, module: 'leakage');
});

final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';
  return BackendApiService(fs: fs, uid: uid, module: 'leakage');
});
```

```dart
// providers/leakage_task_provider.dart (excerpt)
class LeakageTaskListNotifier extends StateNotifier<List<LeakageTask>> {
  final Ref ref;
  late TaskRepository _repo;

  LeakageTaskListNotifier(this.ref) : super(const []) {
    _repo = ref.read(taskRepositoryProvider);
    _load();
    ref.listen(userProvider, (prev, next) {
      if (prev?.uid != next.uid) {
        _repo = ref.read(taskRepositoryProvider);
        _load();
      }
    });
  }

  Future<void> _load() async {
    final list = await _repo.fetchAll();
    state = List.unmodifiable(list);
  }

  Future<void> upsertTask(LeakageTask task) async {
    await _repo.upsert(task);
    final list = [...state];
    final i = list.indexWhere((t) => t.id == task.id);
    (i >= 0) ? list[i] = task : list.add(task);
    state = List.unmodifiable(list);
  }
}
```

---

## GoRouter Snippets

```dart
GoRoute(path: '/leakage/dashboard', builder: (_, __) => const LeakageDashboardPage()),
GoRoute(path: '/leakage/task/:id', builder: (ctx, st) => LeakageTaskPage(taskId: st.pathParameters['id']!)),
GoRoute(path: '/leakage/report/:id', builder: (ctx, st) => LeakageReportPage(taskId: st.pathParameters['id']!)),
```

---

## File Storage Service (key API)

```dart
// services/file_storage_service.dart (API surface)
Future<Directory> moduleDir(String uid, String module);
Future<File> moduleIndexFile(String uid, String module);
Future<File> taskFile(String uid, String module, String taskId);
Future<File> moduleAssetFile(String uid, String module, String relative);
Future<String> saveMediaFromFilePath({required String uid, required String module, required String taskId, required String sourcePath, required String preferredFileName});
Future<String?> resolveModuleAbsolute(String uid, String module, String? relative);
Future<void> deleteTaskMedia(String uid, String module, String taskId);
```

> Media paths saved in `LeakageTask.photoPaths` are module‑relative. UI resolves with `resolveModuleAbsolute()`.

---

## Mock Backend → Real HTTP Swap

* Keep the `LeakReport` return type stable.
* Replace the body of `BackendApiService.analyzeLeakageTask()` with:

  1. Upload media referenced by `task.photoPaths`.
  2. POST a job request; poll for results or receive a webhook.
  3. Map the backend payload into `LeakReport`/`LeakReportPoint`/`LeakSuggestion`.
* Handle partial failures with retries; store a job status field on the task if needed (e.g., `analysisStatus: queued|running|done|error`).

---

## Bottom Sheets UX (Patterns)

* Use `showModalBottomSheet` with `isScrollControlled: true` for long lists.
* Provide visual separators between items (ListTile + Divider) and square thumbnails.
* Support swipe‑to‑delete via `flutter_slidable` using `DrawerMotion` so actions remain until swiped back.

---

## Troubleshooting

* **Images not showing**: Ensure `photoPaths` store **relative** module paths and that `resolveModuleAbsolute` returns an existing file.
* **Cannot use camera in emulator**: switch to gallery or physical device.
* **Stale JSON** after schema changes: Account → *Clear Leakage Data*; or delete `users/<uid>/leakage/` in workspace mirror.
* **Intro not prompting**: confirm `completedIntro` flag; you can toggle via Account actions.

---

## TODO Backlog (Dev)

* Persist full Intro answers (JSON) and surface in Account → Profile.
* To‑Do list model + provider + UI; hook from Report suggestions.
* iOS entitlements and storage/camera path parity.
* Module template generator (Mason or script) for new retrofits.
