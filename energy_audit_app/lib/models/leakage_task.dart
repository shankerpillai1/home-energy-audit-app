import 'package:uuid/uuid.dart';

class LeakageTask {
  final String id;
  String title;
  String type; // e.g. 'window', 'door', ...
  List<String> photoPaths;
  DateTime createdAt;
  String? analysisSummary;
  List<String>? recommendations;

  LeakageTask({
    String? id,
    required this.title,
    required this.type,
    this.photoPaths = const [],
    DateTime? createdAt,
    this.analysisSummary,
    this.recommendations,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'photoPaths': photoPaths,
        'createdAt': createdAt.toIso8601String(),
        'analysisSummary': analysisSummary,
        'recommendations': recommendations,
      };

  factory LeakageTask.fromJson(Map<String, dynamic> j) => LeakageTask(
        id: j['id'] as String?,
        title: j['title'] as String,
        type: j['type'] as String,
        photoPaths: (j['photoPaths'] as List<dynamic>).cast(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        analysisSummary: j['analysisSummary'] as String?,
        recommendations:
            (j['recommendations'] as List<dynamic>?)?.cast<String>(),
      );
}
