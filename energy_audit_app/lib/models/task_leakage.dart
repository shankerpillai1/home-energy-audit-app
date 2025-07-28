class LeakageTask {
  final String taskId;
  final String title;
  final String type;            // e.g. "Window" or "Door"
  final List<String> photoPaths;
  final DateTime createdAt;
  String status;                // e.g. "saved", "submitted"
  
  LeakageTask({
    required this.taskId,
    required this.title,
    required this.type,
    required this.photoPaths,
    required this.createdAt,
    this.status = 'saved',
  });
  // JSON serialization methods generated via json_serializable
}