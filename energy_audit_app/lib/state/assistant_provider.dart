import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 单条聊天消息
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {this.isUser = false});
}

/// 对话节点：显示文本 + 下方选项
class FlowNode {
  final String text;
  final List<String> options;
  FlowNode(this.text, this.options);
}

/// Assistant 状态：消息 + 当前选项 + 当前节点 + 已完成模块集合
class AssistantState {
  final List<ChatMessage> messages;
  final List<String> options;
  final String currentNodeId;
  final Set<String> doneModules;

  AssistantState({
    required this.messages,
    required this.options,
    required this.currentNodeId,
    required this.doneModules,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    List<String>? options,
    String? currentNodeId,
    Set<String>? doneModules,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      options: options ?? this.options,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      doneModules: doneModules ?? this.doneModules,
    );
  }
}

class AssistantNotifier extends StateNotifier<AssistantState> {
  AssistantNotifier() : super(_initialState);

  static const _carbonEntry = 'Save money and carbon footprint';
  static final List<String> _carbonOptions = [
    'Replace light bulbs with LED bulbs',
    'Seal Air Leaks',
    'Thermostat Settings',
    'Find other ways to save energy and money',
  ];

  static final Map<String, FlowNode> _flow = {
    'INIT': FlowNode(
      'How can I help you?',
      [
        _carbonEntry,
        'Replace appliance and get tips',
        'Increase the comfort of my home',
        'Browse all retrofits',
      ],
    ),
    _carbonEntry: FlowNode(
      '''
There are many potential ways to save money and reduce your carbon footprint...
...Before getting into the details, there are three retrofits that are relatively cheap and easy.
''',
      _carbonOptions,
    ),
    // Seal Air Leaks 分支 —— 与 LED 分支并列
    'Seal Air Leaks': FlowNode(
      'Seal Air Leaks allows conditioned air to escape through cracks in your home envelope...',
      [
        'I’ve already done this',
        'Keep this on my to-do list',
        'Learn more and get help',
      ],
    ),
    // LED 分支
    'Replace light bulbs with LED bulbs': FlowNode(
      'Replace light bulbs with LED bulbs:',
      [
        'I’ve already replaced all my bulbs—don’t remind me again',
        'Keep this on my to-do list',
        'Learn more and get help',
      ],
    ),
    // Thermostat 分支
    'Thermostat Settings': FlowNode(
      'Thermostat Settings:',
      [
        'My thermostat changes the temperature when I am out of the house',
        'Keep this on my to-do list',
        'Learn more and get help',
      ],
    ),
    // Other 分支
    'Find other ways to save energy and money': FlowNode(
      'Do you have:\n• Central AC\n• Window AC\n• More than one fridge...\n• Electric vehicle',
      [],
    ),
  };

  static final AssistantState _initialState = AssistantState(
    messages: [ChatMessage(_flow['INIT']!.text)],
    options: _flow['INIT']!.options,
    currentNodeId: 'INIT',
    doneModules: <String>{},
  );

  /// 用户点击某个选项
  void onTap(String label) {
    // **移除** 对 'Seal Air Leaks' 的早期 return，
    // 让它像 LED 一样被 FlowNode 捕获并在对话框内展示

    // 处理“已完成”选项
    if (state.currentNodeId == 'Seal Air Leaks' &&
        label == 'I’ve already done this') {
      final newDone = {...state.doneModules, 'Seal Air Leaks'};
      _goBackToCarbon(
        userLabel: label,
        ackText: 'Great, I have noted you’ve done seal air leaks.',
        doneModules: newDone,
      );
      return;
    }
    // LED 的“已完成”选项
    if (state.currentNodeId == 'Replace light bulbs with LED bulbs' &&
        label == 'I’ve already replaced all my bulbs—don’t remind me again') {
      final newDone = {...state.doneModules, 'Replace light bulbs with LED bulbs'};
      _goBackToCarbon(
        userLabel: label,
        ackText: 'Understood. I won’t remind you about LED bulbs again.',
        doneModules: newDone,
      );
      return;
    }
    // “加入待办”都回到 Carbon
    if ((state.currentNodeId == 'Seal Air Leaks' ||
         state.currentNodeId == 'Replace light bulbs with LED bulbs' ||
         state.currentNodeId == 'Thermostat Settings') &&
        label == 'Keep this on my to-do list') {
      _goBackToCarbon(
        userLabel: label,
        ackText: 'Done! Added to your to‑do list.',
        doneModules: state.doneModules,
      );
      return;
    }

    // **常规对话推进**，包括 Seal Air Leaks
    final node = _flow[label];
    if (node != null) {
      final msgs1 = [
        ...state.messages,
        ChatMessage(label, isUser: true),
      ];
      final msgs2 = [
        ...msgs1,
        ChatMessage(node.text, isUser: false),
      ];
      state = state.copyWith(
        messages: msgs2,
        options: node.options,
        currentNodeId: label,
      );
    }
  }

  /// 回到 Carbon 分支，并过滤掉 doneModules
  void _goBackToCarbon({
    required String userLabel,
    required String ackText,
    required Set<String> doneModules,
  }) {
    final msgs1 = [...state.messages, ChatMessage(userLabel, isUser: true)];
    final msgs2 = [...msgs1, ChatMessage(ackText, isUser: false)];
    final filtered = _carbonOptions
        .where((opt) => !doneModules.contains(opt))
        .toList();
    state = AssistantState(
      messages: msgs2,
      options: filtered,
      currentNodeId: _carbonEntry,
      doneModules: doneModules,
    );
  }

  /// 重置对话
  void reset() => state = _initialState;
}

final assistantProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>(
  (_) => AssistantNotifier(),
);
