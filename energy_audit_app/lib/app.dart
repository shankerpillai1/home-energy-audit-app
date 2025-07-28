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
        // 根路由必须放在最前面，统一重定向到 login/intro/home
        routes: [
          GoRoute(
            path: '/',
            redirect: (BuildContext context, GoRouterState state) {
              if (!user.isLoggedIn) return '/login';
              if (!user.completedIntro) return '/intro';
              return '/home';
            },
          ),
          GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
          GoRoute(
            path: '/register',
            builder: (_, __) => const RegisterPage(),
          ),
          GoRoute(path: '/intro', builder: (_, __) => const IntroPage()),
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(
            path: '/assistant',
            builder: (_, __) => const AssistantPage(),
          ),
        ],
        // 额外的 redirect 用于防止手动输入 URL 绕过逻辑
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
