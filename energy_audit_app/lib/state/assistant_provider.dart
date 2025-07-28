import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssistantState {
  final bool isLoggedIn;
  // ... other Assistant info
  AssistantState({this.isLoggedIn = false});
}

final assistantProvider = StateNotifierProvider<AssistantNotifier, AssistantState>(
  (ref) => AssistantNotifier(),
);

class AssistantNotifier extends StateNotifier<AssistantState> {
  AssistantNotifier(): super(AssistantState());

  void login() { state = AssistantState(isLoggedIn: true); }
  void logout() { state = AssistantState(isLoggedIn: false); }
}
