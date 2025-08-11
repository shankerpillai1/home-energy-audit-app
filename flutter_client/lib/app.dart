import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/router_refresh.dart';
import 'providers/user_provider.dart';
import 'ui/auth/login_page.dart';
import 'ui/auth/register_page.dart';
import 'ui/intro/intro_page.dart';
import 'ui/home/home_page.dart';
import 'ui/assistant/assistant_page.dart';
import 'ui/modules/leakage/task_page.dart';
import 'ui/modules/leakage/report_page.dart';
import 'ui/modules/leakage/dashboard_page.dart';
import 'config/themes.dart';

class EnergyAuditApp extends ConsumerWidget {
  const EnergyAuditApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return MaterialApp.router(
      title: 'Energy Audit',
      theme: AppThemes.light,
      routerConfig: GoRouter(
        refreshListenable:
            RouterRefreshStream(ref.read(userProvider.notifier).stream),
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) {
              if (!user.isLoggedIn) return '/login';
              if (!user.completedIntro) return '/intro';
              return '/home';
            },
          ),
          GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
          GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
          GoRoute(path: '/intro', builder: (_, __) => const IntroPage()),
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/assistant', builder: (_, __) => const AssistantPage()),

          // Leakage
          GoRoute(
            path: '/leakage/dashboard',
            builder: (_, __) => const LeakageDashboardPage(),
          ),
          GoRoute(
            path: '/leakage/task/:id',
            builder: (context, state) {
              final taskId = state.pathParameters['id']!;
              return LeakageTaskPage(taskId: taskId);
            },
          ),
          GoRoute(
            path: '/leakage/report/:id',
            builder: (context, state) {
              final taskId = state.pathParameters['id']!;
              return LeakageReportPage(taskId: taskId);
            },
          ),
        ],
        redirect: (context, state) {
          final loc = state.location;

          // 1) If not logged in: everything goes to /login except /register.
          if (!user.isLoggedIn && loc != '/login' && loc != '/register') {
            return '/login';
          }

          // 2) If logged in but NOT completed intro: force to /intro, except when already on /intro.
          if (user.isLoggedIn && !user.completedIntro && loc != '/intro') {
            return '/intro';
          }

          // 3) If logged in and tries to go to /login or /register, send to /home.
          //    NOTE: We intentionally DO NOT block /intro here so users can edit it later.
          if (user.isLoggedIn && (loc == '/login' || loc == '/register')) {
            return '/home';
          }

          return null;
        },
      ),
    );
  }
}
