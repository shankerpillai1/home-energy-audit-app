import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedMoney = 100;
    final savedElectric = 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(userProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$$savedMoney Saved\n$savedElectric kWh Saved',
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          theme.colorScheme.onPrimary.withOpacity(0.3),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildSection(
                    context,
                    title: 'Projects I want to do',
                    items: const [
                      'Switch to LED Bulbs',
                    ],
                  ),
                  _buildSection(
                    context,
                    title: 'Periodic Reminders',
                    items: const [
                      'Annual heating maintenance (Due Now)',
                      'Annual AC maintenance',
                    ],
                    redItems: {0},
                  ),
                  _buildSection(
                    context,
                    title: 'Done List',
                    items: const [
                      'Completed Task A',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/assistant'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      bottomNavigationBar: const _BottomTabBar(),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<String> items,
    Set<int> redItems = const {},
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const Divider(),
            ...items.asMap().entries.map((e) {
              final idx = e.key;
              final text = e.value;
              return ListTile(
                leading: Icon(
                  idx == 0 && title == 'Projects I want to do'
                      ? Icons.check_circle
                      : Icons.circle,
                  color: redItems.contains(idx)
                      ? Colors.red
                      : theme.colorScheme.onSurface,
                ),
                title: Text(text),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BottomTabBar extends StatefulWidget {
  const _BottomTabBar({Key? key}) : super(key: key);

  @override
  State<_BottomTabBar> createState() => _BottomTabBarState();
}

class _BottomTabBarState extends State<_BottomTabBar> {
  int? _expandedIndex;

  final List<String> mainButtons = [
    'Carbon',
    'Appliance',
    'Comfort',
    'Browse All',
  ];

  final Map<int, List<String>> subMenus = {
    0: ['LED', 'Air Leakage', 'Thermostat', 'Other'],
    1: ['Fridge', 'Washer', 'Dryer'],
    2: ['Humidity', 'Temperature', 'Noise'],
    3: ['All Projects', 'Tips', 'FAQ'],
  };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth / mainButtons.length;
    final buttonHeight = 48.0;

    return SizedBox(
      height: _expandedIndex != null
          ? buttonHeight * (subMenus[_expandedIndex!]!.length + 1)
          : buttonHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Submenu (only if expanded)
          if (_expandedIndex != null)
            Positioned(
              bottom: buttonHeight,
              left: buttonWidth * _expandedIndex!,
              width: buttonWidth,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: subMenus[_expandedIndex]!
                      .map(
                        (item) => GestureDetector(
                          onTap: () {
                            if (_expandedIndex == 0 &&
                                item == 'Air Leakage') {
                              GoRouter.of(context)
                                  .go('/leakage/dashboard');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Clicked $item')),
                              );
                            }
                            setState(() {
                              _expandedIndex = null;
                            });
                          },
                          child: Container(
                            height: buttonHeight,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey),
                              ),
                            ),
                            child: Text(item),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              children: List.generate(mainButtons.length, (index) {
                final isSelected = _expandedIndex == index;
                return SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedIndex = isSelected ? null : index;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        mainButtons[index],
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
