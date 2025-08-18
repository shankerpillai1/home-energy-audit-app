import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_item.dart';
import 'todo_provider.dart';

/// Represents a single message in the chat conversation.
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {this.isUser = false});
}

/// Represents a node in the conversational flow.
/// Contains the assistant's response text and the user's reply options.
class FlowNode {
  final String text;
  final List<String> options;
  FlowNode(this.text, this.options);
}

/// Represents the state of the Assistant feature.
class AssistantState {
  final List<ChatMessage> messages;
  final List<String> options;
  final String currentNodeId;
  final Set<String> doneModules; // Tracks modules the user has marked as complete.

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

/// Manages the state and logic of the conversational assistant.
class AssistantNotifier extends StateNotifier<AssistantState> {
  // A reference to the Riverpod Ref, allowing this notifier to read other providers.
  final Ref _ref;

  AssistantNotifier(this._ref) : super(_initialState);

  // Static definition of the conversation flow.
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
There are many potential ways to save money and reduce your carbon footprint. Many retrofits can do both, and some are better for one or the other.

Figuring out the retrofits that are right for you can be complicated because there are a large number of potential retrofits, and whether is possible for your home and whether it will have a positive impact for your home can depend on many factors.

Before getting into the details, there are three retrofits that are relatively cheap and easy, and are cost efficient for almost every home.
''',
      _carbonOptions,
    ),
    'Seal Air Leaks': FlowNode(
      'Seal Air Leaks allows conditioned air to escape through cracks in your home envelope...',
      [
        'I’ve already done this',
        'Keep this on my to-do list',
        'Learn more and get help',
      ],
    ),
    'Replace light bulbs with LED bulbs': FlowNode(
      'Replace light bulbs with LED bulbs:',
      [
        'I’ve already replaced all my bulbs—don’t remind me again',
        'Keep this on my to-do list',
        'Learn more and get help',
      ],
    ),
    'Thermostat Settings': FlowNode(
      'Thermostat Settings:',
      [
        'My thermostat changes the temperature when I am out of the house',
        'Keep this on my to-do list',
        'Learn more and get help',
      ],
    ),
    'Find other ways to save energy and money': FlowNode(
      'Do you have:\n• Central AC\n• Window AC\n• More than one fridge...\n• Electric vehicle',
      [],
    ),
  };

  // The initial state of the assistant when a new conversation starts.
  static final AssistantState _initialState = AssistantState(
    messages: [ChatMessage(_flow['INIT']!.text)],
    options: _flow['INIT']!.options,
    currentNodeId: 'INIT',
    doneModules: <String>{},
  );

  /// Handles user interaction when an option [label] is tapped.
  void onTap(String label) {
    // **INTEGRATION POINT**: Handle "I've already done this" options.
    // This now also removes the corresponding item from the to-do list.
    if ((state.currentNodeId == 'Seal Air Leaks' && label == 'I’ve already done this') ||
        (state.currentNodeId == 'Replace light bulbs with LED bulbs' &&
            label == 'I’ve already replaced all my bulbs—don’t remind me again')) {
      final moduleName = state.currentNodeId;
      final newDone = {...state.doneModules, moduleName};

      // Remove the corresponding item from the to-do list by its title.
      _ref.read(todoListProvider.notifier).removeItemByTitle(moduleName);

      _goBackToCarbon(
        userLabel: label,
        ackText: 'Great, I have noted you’ve done this and removed it from your projects.',
        doneModules: newDone,
      );
      return;
    }

    // **INTEGRATION POINT**: Handle "Keep this on my to-do list" options.
    if ((state.currentNodeId == 'Seal Air Leaks' ||
         state.currentNodeId == 'Replace light bulbs with LED bulbs' ||
         state.currentNodeId == 'Thermostat Settings') &&
        label == 'Keep this on my to-do list') {
      
      // Add the item to the to-do list via the provider.
      _ref.read(todoListProvider.notifier).addItem(
        title: state.currentNodeId, // Use the node title as the to-do title
        type: TodoItemType.project, // These are categorized as projects
      );

      _goBackToCarbon(
        userLabel: label,
        ackText: 'Done! I\'ve added "${state.currentNodeId}" to your to-do list.',
        doneModules: state.doneModules,
      );
      return;
    }

    // Handle normal conversation progression.
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

  /// Navigates the conversation back to the main carbon options menu.
  void _goBackToCarbon({
    required String userLabel,
    required String ackText,
    required Set<String> doneModules,
  }) {
    final msgs1 = [...state.messages, ChatMessage(userLabel, isUser: true)];
    final msgs2 = [...msgs1, ChatMessage(ackText, isUser: false)];
    // Filter out options that the user has marked as done.
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

  /// Resets the conversation to its initial state.
  void reset() => state = _initialState;
}

/// The provider for the [AssistantNotifier].
final assistantProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>(
  // Pass the ref to the notifier so it can read other providers.
  (ref) => AssistantNotifier(ref),
);