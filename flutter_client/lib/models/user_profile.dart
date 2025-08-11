class UserProfile {
  final String userId;
  final String name;
  final bool introCompleted;

  UserProfile({
    required this.userId,
    required this.name,
    this.introCompleted = false,
  });
}
