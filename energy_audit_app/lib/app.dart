import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/router_refresh.dart';
import 'state/user_provider.dart';
import 'ui/auth/login_page.dart';
import 'ui/auth/register_page.dart';
import 'ui/intro/intro_page.dart';
import 'ui/home/home_page.dart';
import 'ui/assistant/assistant_page.dart';
import 'ui/modules/leakage/history_page.dart';
import 'ui/modules/leakage/task_page.dart';
import 'ui/modules/leakage/report_page.dart';
import 'config/themes.dart';

class EnergyAuditApp extends ConsumerWidget {
  const EnergyAuditApp({Key? key}) : super(key: key);

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
            redirect: (_, state) {
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

          // Leakage 模块
          GoRoute(
            path: '/leakage/history',
            builder: (_, __) => const LeakageHistoryPage(),
          ),
          GoRoute(
            path: '/leakage/task/:id',
            builder: (context, state) {
              // 从 pathParameters 读取 id
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
          if (!user.isLoggedIn && loc != '/login' && loc != '/register') {
            return '/login';
          }
          if (user.isLoggedIn &&
              !user.completedIntro &&
              loc != '/intro' &&
              loc != '/register') {
            return '/intro';
          }
          if (user.isLoggedIn &&
              user.completedIntro &&
              (loc == '/login' || loc == '/intro' || loc == '/register')) {
            return '/home';
          }
          return null;
        },
      ),
    );
  }
}
