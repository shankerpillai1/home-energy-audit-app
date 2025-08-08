构建出一个完整的、可继承的、模块化的软件设计方案总览，确保：

逻辑流畅 ✅

模块边界明确 ✅

用户交互合理 ✅

未来维护易于扩展 ✅

🧭 家庭能源审计 App 总体架构设计方案（高层流程+模块交互）
🌐 项目目标定位
平台：Flutter 构建，支持 移动端 + Web

主要功能：引导用户通过对话式 UI 完成节能评估任务，并记录任务进度、建议、报告等

特别模块：你负责 Air Leakage 检测

扩展性需求：其他节能模块如 Thermostat、AC、Washer 等将未来接入，因此系统设计需模块化

🗂️ 总体模块划分
vbnet
Copy
Edit
┌────────────────────────────────────┐
│         Authentication Module      │
└────────────────────────────────────┘
           ↓（首次登录判断）
┌────────────────────────────────────┐
│          User Intro Module         │（Zip code、Own/Rent、电力公司、预算、设备）
└────────────────────────────────────┘
           ↓（完成后进入）
┌────────────────────────────────────┐
│            Home Screen             │（Dashboard、To-Do、Reminders、Done、Assistant）
└────────────────────────────────────┘
           ↓
┌────────────────────┐    →  Assistant Module（模拟AI对话 + 引导导航）
│ Retrofit Modules     │    →  引导进入不同模块（Leakage, AC, Washer...）
│ ┌───────────────┐   │
│ │ Air Leakage   │   │  ← 当前我们负责的唯一“可操作”模块
│ └───────────────┘   │
│ ┌───────────────┐   │
│ │ Thermostat    │   │  ← 预留模块入口，未实现
│ └───────────────┘   │
│ ...                 │
└────────────────────┘
🔄 核心用户交互流程（基于用户旅程）
🧑‍💼 第一次使用用户
plaintext
Copy
Edit
[启动App]
     ↓
[是否已注册？] ——→ 否 ——→ [Register 页面]
     ↓ 是
[是否已完成 Intro?] ——→ 否 ——→ [User Intro 页面]
     ↓ 是
[进入 HomePage]
🏠 Home Page 模块结构
plaintext
Copy
Edit
╭────────────────────────────────────╮
│ Top Bar: 节能金额 + 节省电量展示      │ ← Dashboard 组件
├────────────────────────────────────┤
│ To-Do List (可点击跳转任务模块页)     │
├────────────────────────────────────┤
│ Periodic Reminders (年检等提醒)       │
├────────────────────────────────────┤
│ Done List (用户已完成任务)           │
├────────────────────────────────────┤
│ Assistant 引导按钮（打开模拟对话助手）│
╰────────────────────────────────────╯
💬 Assistant 模块流程
plaintext
Copy
Edit
用户进入 Assistant
     ↓
选择目标（节能 / 替换设备 / 提升舒适度 / 浏览所有改造）
     ↓
推荐优先模块（LED / Seal Air Leaks / Thermostat）
     ↓
点击某模块 → 跳转对应模块页
✅ 当前已实现跳转模块：Seal Air Leaks

🌪 Air Leakage 模块结构
plaintext
Copy
Edit
[Assistant 引导进入]
     ↓
[LeakageHistoryPage] ← 查看历史任务
     ├── 搜索/筛选
     └── 新建任务
            ↓
      [LeakageTaskPage]
        ├── 标题、类型、上传照片
        ├── 保存（仅本地保存）
        └── 提交（发送给后端 AI）
               ↓
         [LeakageResultPage]
           ├── 显示分析图像
           ├── 显示建议（可加入 To-Do）
           └── 下载报告
📦 数据结构 & 逻辑设计核心原则（略提）
所有模块都以「RetrofitModule」为单位，可被加入 To-Do / Reminder / Done List

所有用户任务（如 leakage 检测）记录为 Task，可以存储历史记录、分析结果

Assistant 与模块绑定为引导路径，但不存数据，只导航

数据本地存储优先（考虑后续接入云同步预留接口）

✅ 软件设计亮点（符合“可继承、可扩展、可维护”的成熟标准）
设计维度	实现方式说明
模块化分层清晰	每个模块职责分明，可独立开发和对接
用户旅程完整	包括首次使用、普通使用、历史查询、分析反馈全流程
未来可扩展性强	Assistant → 任意新 retrofit 模块插拔式引导
前后端解耦	AI模块仅通过 Submit 接口交互，结果标准格式返回
数据集中管理	所有数据结构围绕 Task 和 RetrofitAction，逻辑统一
引导人性化	Assistant 模块设计充分降低用户使用门槛
平台统一性好	通过 Flutter 结构设计兼容 Web & Mobile 同步逻辑
lib/
├─ config/
│  └─ themes.dart
│     → Global Material theme (ColorScheme, TextTheme, AppBar, buttons).
│
├─ models/
│  ├─ leakage_task.dart
│     → Core data model for Leakage:
│       - LeakageTask: id/title/type/photoPaths/createdAt + optional report.
│       - LeakReport: optional payload (energy loss, severity, savings, points).
│       - LeakReportPoint: a single leak point (title/subtitle/imagePath).
│  └─ user_profile.dart
│     → User profile / intro questionnaire model (future: stored to user.json).
│
├─ repositories/
│  ├─ file_task_repository.dart
│     → TaskRepository implementation backed by JSON files on disk.
│       - With per-user/per-module paths (users/<uid>/<module>/tasks.json).
│       - In debug on desktop, also mirrors JSON into your workspace folder
│         under .debug_data/… so you can open it directly from VS Code.
│  └─ task_repository.dart
│     → Repository interface: fetchAll/fetchById/upsert/delete.
│
├─ services/
│  ├─ assistant_service.dart
│     → Assistant flow logic (no persistence).
│  ├─ auth_service.dart
│     → Auth session/credentials. Use secure storage for sensitive tokens later.
│  ├─ backend_api_service.dart
│     → Placeholder for HTTP calls (submit analysis / fetch results).
│  ├─ file_storage_service.dart
│     → Low-level JSON file I/O.
│       - Resolves sandbox paths.
│       - Provides per-user/per-module files.
│       - (Debug desktop) optional workspace mirroring to ./.debug_data/.
│  └─ settings_service.dart
│     → Lightweight app settings (SharedPreferences). Flags only (e.g. hasSeenIntro).
│
├─ state/
│  ├─ assistant_provider.dart         → Riverpod state for Assistant.
│  ├─ leakage_task_provider.dart      → StateNotifier for leakage tasks (uses TaskRepository).
│  ├─ repository_providers.dart       → Wires FileStorageService + FileTaskRepository (+ user id).
│  └─ user_provider.dart              → Auth/intro state (exposes isLoggedIn, completedIntro, uid).
│
├─ ui/
│  ├─ assistant/                      → Assistant UI.
│  ├─ auth/                           → Login/Register screens.
│  ├─ home/                           → Home dashboard & entry cards.
│  ├─ intro/                          → Intro questionnaire UI.
│  └─ modules/leakage/
│     ├─ dashboard_page.dart          → Main “Leakage” hub (tutorial, new task, in-progress/completed).
│     ├─ report_page.dart             → Report UI (reads task.report; can generate mock for testing).
│     └─ task_page.dart               → Create/Edit Task (multi leak points, RGB/Thermal buttons).
│
├─ utils/
│  └─ …                               → Helpers/constants as needed.
│
├─ app.dart                           → Root app widget (MaterialApp.router + GoRouter guards).
└─ main.dart                          → Entry point (ProviderScope + EnergyAuditApp).
