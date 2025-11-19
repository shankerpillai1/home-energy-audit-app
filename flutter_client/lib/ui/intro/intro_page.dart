import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/settings_service.dart';
import 'package:http/http.dart' as http;

class IntroPage extends ConsumerStatefulWidget {
  const IntroPage({super.key});

  @override
  ConsumerState<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends ConsumerState<IntroPage> {
  final _zipCtrl = TextEditingController();
  final _electricCtrl = TextEditingController();
  int _step = 0;
  String _ownership = 'Own';
  String _budget = 'up to \$200';
  final List<String> _budgets = const [
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
  void initState() {
    super.initState();
    _loadExistingProfileIfAny();
  }

  @override
  void dispose() {
    _zipCtrl.dispose();
    _electricCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfileIfAny() async {
    final user = ref.read(userProvider);
    final uid = (user.uid?.isNotEmpty == true) ? user.uid! : 'local';
    final fs = ref.read(fileStorageServiceProvider);
    final file = await fs.profileFile(uid);
    try {
      final text = await file.readAsString();
      if (text.trim().isEmpty) return;
      final j = jsonDecode(text) as Map<String, dynamic>;

      setState(() {
        _zipCtrl.text = (j['zip'] as String?) ?? '';
        _electricCtrl.text = (j['electricCompany'] as String?) ?? '';
        _ownership = (j['ownership'] as String?) ?? _ownership;
        _budget = (j['budget'] as String?) ?? _budget;

        final apps = (j['appliances'] as List<dynamic>?)?.cast<String>() ?? [];
        for (final k in _appliances.keys.toList()) {
          _appliances[k] = apps.contains(k);
        }
      });
    } catch (_) {
      // ignore parse errors
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(userProvider);
    final uid = (user.uid?.isNotEmpty == true) ? user.uid! : 'local';
    final fs = ref.read(fileStorageServiceProvider);
    final file = await fs.profileFile(uid);

    final selectedApps = _appliances.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final payload = <String, dynamic>{
      'zip': _zipCtrl.text.trim(),
      'ownership': _ownership,
      'electricCompany': _electricCtrl.text.trim(),
      'budget': _budget,
      'appliances': selectedApps,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<void> _sendToBackend() async {
    final user = ref.read(userProvider);
    final uid = user.uid;
    if (uid == null || uid.isEmpty) return;

    final selectedApps = _appliances.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final payload = {
      "userID": uid,
      "zip": _zipCtrl.text.trim(),
      "ownership": _ownership,
      "electricCompany": _electricCtrl.text.trim(),
      "budget": _budget,
      "appliances": selectedApps,
    };

    final url = Uri.parse("http://10.0.2.2:8000/auth/update_profile");

    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      print("Profile updated: ${resp.body}");
    } catch (e) {
      print("Failed to update profile: $e");
    }
  }

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

      // Body scrolls; bottom button is fixed.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // leave space for bottom bar
          child: _step == 0 ? _buildStep1(theme) : _buildStep2(theme),
        ),
      ),

      // Fixed bottom action bar (Next / Finish)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_step == 0) {
                      setState(() => _step = 1);
                    } else {
                      // Save
                      await _saveProfile();
                      await _sendToBackend();

                      // Mark intro completed if not yet
                      final user = ref.read(userProvider);
                      final username = user.uid ?? 'Unknown';
                      if (username.isNotEmpty) {
                        await SettingsService().saveBool('introCompleted_$username', true);
                      }
                      await ref.read(userProvider.notifier).completeIntro();

                      if (mounted) context.go('/home');
                    }
                  },
                  child: Text(_step == 0 ? 'Next' : 'Finish'),
                ),
              ),
            ],
          ),
        ),
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
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Zip Code',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Text('Own or Rent?', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Row(
          children: ['Own', 'Rent'].map((o) {
            final selected = _ownership == o;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor:
                        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    backgroundColor:
                        selected ? theme.colorScheme.primary : theme.colorScheme.surface,
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
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Electric Company',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text('Budget for retrofits?', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        ..._budgets.map((b) => RadioListTile<String>(
              value: b,
              groupValue: _budget,
              title: Text(b),
              onChanged: (v) => setState(() => _budget = v!),
              activeColor: theme.colorScheme.primary,
            )),
      ],
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Which appliances do you have?', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        // Just list tiles; scroll is handled by outer SingleChildScrollView
        ..._appliances.keys.map((key) {
          return CheckboxListTile(
            value: _appliances[key],
            //onChanged: (v) => setState(() => _appliances[key] = v!)
            onChanged: (v) {
              _appliances[key] = v!;
              setState(() {}); // one rebuild instead of rebuilding every key
            },
            title: Text(key),
            activeColor: theme.colorScheme.primary,
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
