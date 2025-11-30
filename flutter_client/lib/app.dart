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
import 'ui/retrofits/leakage/task_page.dart';
import 'ui/retrofits/leakage/report_page.dart';
import 'ui/retrofits/leakage/dashboard_page.dart';
import 'ui/retrofits/led/led_page.dart'; // New import for the LED page
import 'ui/retrofits/thermostat/thermostat_page.dart'; // New import for the Thermostat page
import 'config/themes.dart';

/// The root widget of the Energy Audit application.
///
/// It sets up the [MaterialApp.router] and configures the [GoRouter]
/// for navigation, including authentication and onboarding guards.
class EnergyAuditApp extends ConsumerWidget {
  const EnergyAuditApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the userProvider to rebuild the router when auth state changes.
    final user = ref.watch(userProvider);

    return MaterialApp.router(
      title: 'Energy Audit',
      theme: AppThemes.light,
      // Configure the GoRouter with routes and redirect logic.
      routerConfig: GoRouter(
        // The refreshListenable ensures the router re-evaluates redirects on auth changes.
        refreshListenable:
            RouterRefreshStream(ref.read(userProvider.notifier).stream),
        routes: [
          // The root route redirects based on the user's authentication
          // and onboarding status.
          GoRoute(
            path: '/',
            redirect: (_, __) {
              if (!user.isLoggedIn) return '/login';
              if (!user.completedIntro) return '/intro';
              return '/home';
            },
          ),
          // Auth routes
          GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
          //GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
          // Onboarding route
          GoRoute(path: '/intro', builder: (_, __) => const IntroPage()),
          // Main app routes
          GoRoute(path: '/home', builder: (_, __) => const HomePage()),
          GoRoute(path: '/assistant', builder: (_, __) => const AssistantPage()),

          // Leakage module routes
          GoRoute(
            path: '/leakage/dashboard',
            builder: (_, __) => const LeakageDashboardPage(),
          ),
          GoRoute(
            path: '/leakage',
            redirect: (_, __) => '/leakage/list',
          ),
          GoRoute(
            path: '/leakage/list',
            builder: (context, state) => const LeakageTaskListPage(),
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

          // New Retrofit Module Routes
          GoRoute(
            path: '/retrofits/led',
            builder: (_, __) => const LedPage(),
          ),
          GoRoute(
            path: '/retrofits/thermostat',
            builder: (_, __) => const ThermostatPage(),
          ),
        ],
        // Global redirect logic to handle authentication and onboarding flows.
        redirect: (context, state) {
          final loc = state.location;

          // 1) If not logged in, redirect all paths to /login except /register.
          if (!user.isLoggedIn && loc != '/login' && loc != '/register') {
            return '/login';
          }

          // 2) If logged in but intro is not complete, force redirect to /intro.
          if (user.isLoggedIn && !user.completedIntro && loc != '/intro') {
            return '/intro';
          }

          // 3) If logged in and on an auth page, redirect to /home.
          //    We don't block /intro so users can re-take the survey.
          if (user.isLoggedIn && (loc == '/login' || loc == '/register')) {
            return '/home';
          }

          // No redirect needed.
          return null;
        },
      ),
    );
  }
}