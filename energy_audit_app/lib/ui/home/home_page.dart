import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/retrofits_tab.dart';
import 'tabs/placeholder_tab.dart';
import 'tabs/account_tab.dart';

/// App shell that hosts bottom navigation and five tabs.
/// Each tab is its own page widget (separate file) to keep boundaries clean.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardTab(),
      const RetrofitsTab(),
      const PlaceholderTab(title: 'Coming Soon'),
      const PlaceholderTab(title: 'Coming Soon'),
      AccountTab(
        onLogout: () {
          ref.read(userProvider.notifier).logout();
          context.go('/login');
        },
      ),
    ];

    final titles = <String>['Home', 'Retrofits', 'Tab 3', 'Tab 4', 'Account'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: IndexedStack(index: _currentIndex, children: pages),

      // FAB only on Home tab
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/assistant'),
              child: const Icon(Icons.chat_bubble_outline),
            )
          : null,

      // Mainstream fixed bottom navigation (Android/iOS)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handyman_outlined),
            activeIcon: Icon(Icons.handyman),
            label: 'Retrofits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.widgets_outlined),
            activeIcon: Icon(Icons.widgets),
            label: 'Tab 3',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Tab 4',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
