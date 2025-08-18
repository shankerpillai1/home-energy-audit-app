/// Represents the type of a to-do item.
enum TodoItemType {
  project,  // A one-time project or task.
  reminder, // A recurring or periodic reminder.
}

/// Represents a single to-do item in the user's list.
class TodoItem {
  final String id;
  final String title;
  final TodoItemType type;
  final bool isDone;
  final DateTime? dueDate; // Optional due date for reminders.
  final int priority;      // For sorting, e.g., 0=normal, 1=high.

  TodoItem({
    required this.id,
    required this.title,
    required this.type,
    this.isDone = false,
    this.dueDate,
    this.priority = 0,
  });

  /// Creates a copy of the instance with optional new values.
  TodoItem copyWith({
    String? id,
    String? title,
    TodoItemType? type,
    bool? isDone,
    DateTime? dueDate,
    int? priority,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
    );
  }

  /// Converts the instance to a JSON map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name, // Enum to string
      'isDone': isDone,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
    };
  }

  /// Creates an instance from a JSON map.
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: TodoItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TodoItemType.project, // Fallback
      ),
      isDone: json['isDone'] as bool,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: json['priority'] as int? ?? 0,
    );
  }
}