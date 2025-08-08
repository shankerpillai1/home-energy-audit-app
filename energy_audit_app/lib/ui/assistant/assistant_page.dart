import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/assistant_provider.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({Key? key}) : super(key: key);
  @override
  _AssistantPageState createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(assistantProvider);
    final notifier = ref.read(assistantProvider.notifier);
    final theme    = Theme.of(context);

    final lastAI = state.messages.lastIndexWhere((m) => !m.isUser);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        leading: BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              notifier.reset();
              _scrollCtrl.jumpTo(_scrollCtrl.position.minScrollExtent);
            },
          )
        ],
      ),
      body: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(12),
        itemCount: state.messages.length,
        itemBuilder: (_, idx) {
          final msg      = state.messages[idx];
          final isLastAI = !msg.isUser && idx == lastAI;
          final align    = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
          final bg       = msg.isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surface;
          final fg       = msg.isUser
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface;

          return Align(
            alignment: align,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: msg.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(msg.text, style: TextStyle(color: fg)),
                  if (isLastAI && state.options.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final label in state.options)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: GestureDetector(
                          onTap: () {
                            // 仅在 Seal Air Leaks 或 LED 分支下点击 Learn more 时跳转
                            if ((state.currentNodeId == 'Seal Air Leaks') &&
                                label == 'Learn more and get help') {
                              context.push('/leakage/dashboard');
                              return;
                            }
                            notifier.onTap(label);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                            });
                          },
                          child: Text(
                            label,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
