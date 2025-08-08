import 'package:uuid/uuid.dart';

/// Represents one detected leak point in the report
class LeakReportPoint {
  final String title;
  final String subtitle;
  final String imagePath;

  LeakReportPoint({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'imagePath': imagePath,
      };

  factory LeakReportPoint.fromJson(Map<String, dynamic> j) => LeakReportPoint(
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        imagePath: j['imagePath'] as String,
      );
}

class LeakageTask {
  final String id;
  String title;
  String type;
  List<String> photoPaths;
  DateTime createdAt;

  // existing analysis fields
  String? analysisSummary;
  List<String>? recommendations;

  // new report summary fields
  String? energyLossCost;        // e.g. '$142/year'
  String? energyLossValue;       // e.g. '15.8 kWh/mo'
  String? leakSeverity;          // e.g. 'Moderate'
  String? savingsCost;           // e.g. '$31/year'
  String? savingsPercent;        // e.g. '19% reduction'
  List<LeakReportPoint>? reportPoints;

  LeakageTask({
    String? id,
    required this.title,
    required this.type,
    this.photoPaths = const [],
    DateTime? createdAt,
    this.analysisSummary,
    this.recommendations,
    this.energyLossCost,
    this.energyLossValue,
    this.leakSeverity,
    this.savingsCost,
    this.savingsPercent,
    this.reportPoints,
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
        'energyLossCost': energyLossCost,
        'energyLossValue': energyLossValue,
        'leakSeverity': leakSeverity,
        'savingsCost': savingsCost,
        'savingsPercent': savingsPercent,
        'reportPoints':
            reportPoints?.map((p) => p.toJson()).toList(),
      };

  factory LeakageTask.fromJson(Map<String, dynamic> j) {
    return LeakageTask(
      id: j['id'] as String?,
      title: j['title'] as String,
      type: j['type'] as String,
      photoPaths: (j['photoPaths'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(j['createdAt'] as String),
      analysisSummary: j['analysisSummary'] as String?,
      recommendations:
          (j['recommendations'] as List<dynamic>?)?.cast<String>(),
      energyLossCost: j['energyLossCost'] as String?,
      energyLossValue: j['energyLossValue'] as String?,
      leakSeverity: j['leakSeverity'] as String?,
      savingsCost: j['savingsCost'] as String?,
      savingsPercent: j['savingsPercent'] as String?,
      reportPoints: (j['reportPoints'] as List<dynamic>?)
          ?.map((e) =>
              LeakReportPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
