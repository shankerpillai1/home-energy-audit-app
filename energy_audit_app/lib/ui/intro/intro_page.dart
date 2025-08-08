import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({Key? key}) : super(key: key);

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> {
  final _zipCtrl = TextEditingController();
  final _electricCtrl = TextEditingController();
  int _step = 0;
  String _ownership = 'Own';
  String _budget = 'up to \$200';
  final List<String> _budgets = [
    'up to \$200',
    'up to \$1000',
    'up to \$5000',
    'show me all retrofits',
  ];
  final Map<String, bool> _appliances = {
    'Central Air Conditioning': false,
    'Window AC': false,
    'Fridge/Freezer': false,
    'Dish Washer': false,
    'Clothes Washing Machine/Dryer': false,
    'Pool/Hot Tub': false,
    'Electric Vehicle': false,
    'Built-in Heating System': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'User Profiling' : 'Select Appliances'),
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step = 0),
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _step == 0 ? _buildStep1(theme) : _buildStep2(theme),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us a bit about yourself so we can tailor recommendations.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _zipCtrl,
          decoration: const InputDecoration(
            labelText: 'Zip Code',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Text('Own or Rent?', style: theme.textTheme.bodyLarge),
        Row(
          children: ['Own', 'Rent'].map((o) {
            final selected = _ownership == o;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface, backgroundColor: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                  ),
                  onPressed: () => setState(() => _ownership = o),
                  child: Text(o),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _electricCtrl,
          decoration: const InputDecoration(
            labelText: 'Electric Company',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Budget for retrofits?',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        ..._budgets.map((b) {
          return RadioListTile<String>(
            value: b,
            groupValue: _budget,
            title: Text(b),
            onChanged: (v) => setState(() => _budget = v!),
            activeColor: theme.colorScheme.primary,
          );
        }),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which appliances do you have?',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: _appliances.keys.map((key) {
              return CheckboxListTile(
                value: _appliances[key],
                onChanged: (v) => setState(() => _appliances[key] = v!),
                title: Text(key),
                activeColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).completeIntro();
              context.go('/home');
            },
            child: const Text('Finish'),
          ),
        ),
      ],
    );
  }
}
