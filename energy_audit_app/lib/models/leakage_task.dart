import 'package:uuid/uuid.dart';

/// Suggestion for a specific leak point.
class LeakSuggestion {
  final String title;            // e.g., "Magnetic Gasket"
  final String? costRange;       // e.g., "$40–60"
  final String? difficulty;      // e.g., "Hard"
  final String? lifetime;        // e.g., "10+ years"
  final String? estimatedReduction; // e.g., "85% leakage"

  LeakSuggestion({
    required this.title,
    this.costRange,
    this.difficulty,
    this.lifetime,
    this.estimatedReduction,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'costRange': costRange,
        'difficulty': difficulty,
        'lifetime': lifetime,
        'estimatedReduction': estimatedReduction,
      };

  factory LeakSuggestion.fromJson(Map<String, dynamic> j) => LeakSuggestion(
        title: j['title'] as String,
        costRange: j['costRange'] as String?,
        difficulty: j['difficulty'] as String?,
        lifetime: j['lifetime'] as String?,
        estimatedReduction: j['estimatedReduction'] as String?,
      );
}

/// One leak point inside the report.
class LeakReportPoint {
  final String title;               // e.g., "Frame–Seal Gap"
  final String subtitle;            // e.g., "Location: Top frame..."
  final String? imagePath;          // expanded image (thermal)
  final String? thumbPath;          // small thumbnail (optional, fallback to imagePath)

  /// Optional normalized marker rectangle on the image [0..1]
  final double? markerX;
  final double? markerY;
  final double? markerW;
  final double? markerH;

  final List<LeakSuggestion> suggestions;

  LeakReportPoint({
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.thumbPath,
    this.markerX,
    this.markerY,
    this.markerW,
    this.markerH,
    this.suggestions = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'imagePath': imagePath,
        'thumbPath': thumbPath,
        'markerX': markerX,
        'markerY': markerY,
        'markerW': markerW,
        'markerH': markerH,
        'suggestions': suggestions.map((e) => e.toJson()).toList(),
      };

  factory LeakReportPoint.fromJson(Map<String, dynamic> j) => LeakReportPoint(
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        imagePath: j['imagePath'] as String?,
        thumbPath: j['thumbPath'] as String?,
        markerX: (j['markerX'] as num?)?.toDouble(),
        markerY: (j['markerY'] as num?)?.toDouble(),
        markerW: (j['markerW'] as num?)?.toDouble(),
        markerH: (j['markerH'] as num?)?.toDouble(),
        suggestions: (j['suggestions'] as List<dynamic>? ?? [])
            .map((e) => LeakSuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Report payload embedded in a task (can be null when not analyzed yet).
class LeakReport {
  final String? energyLossCost;   // e.g., "$142/year"
  final String? energyLossValue;  // e.g., "15.8 kWh/mo"
  final String? leakSeverity;     // e.g., "Moderate"
  final String? savingsCost;      // e.g., "$31/year"
  final String? savingsPercent;   // e.g., "19% reduction"
  final List<LeakReportPoint> points;

  const LeakReport({
    this.energyLossCost,
    this.energyLossValue,
    this.leakSeverity,
    this.savingsCost,
    this.savingsPercent,
    this.points = const [],
  });

  Map<String, dynamic> toJson() => {
        'energyLossCost': energyLossCost,
        'energyLossValue': energyLossValue,
        'leakSeverity': leakSeverity,
        'savingsCost': savingsCost,
        'savingsPercent': savingsPercent,
        'points': points.map((e) => e.toJson()).toList(),
      };

  factory LeakReport.fromJson(Map<String, dynamic> j) => LeakReport(
        energyLossCost: j['energyLossCost'] as String?,
        energyLossValue: j['energyLossValue'] as String?,
        leakSeverity: j['leakSeverity'] as String?,
        savingsCost: j['savingsCost'] as String?,
        savingsPercent: j['savingsPercent'] as String?,
        points: (j['points'] as List<dynamic>? ?? [])
            .map((e) => LeakReportPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LeakageTask {
  final String id;
  String title;
  String type; // 'window', 'door', 'wall', ...
  List<String> photoPaths;  // user uploaded paths (RGB/Thermal)
  DateTime createdAt;

  // Optional legacy fields
  String? analysisSummary;
  List<String>? recommendations;

  // Embedded report (null until analysis is available)
  LeakReport? report;

  LeakageTask({
    String? id,
    required this.title,
    required this.type,
    this.photoPaths = const [],
    DateTime? createdAt,
    this.analysisSummary,
    this.recommendations,
    this.report,
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
        'report': report?.toJson(),
      };

  factory LeakageTask.fromJson(Map<String, dynamic> j) => LeakageTask(
        id: j['id'] as String?,
        title: j['title'] as String,
        type: j['type'] as String,
        photoPaths: (j['photoPaths'] as List<dynamic>).cast<String>(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        analysisSummary: j['analysisSummary'] as String?,
        recommendations:
            (j['recommendations'] as List<dynamic>?)?.cast<String>(),
        report: (j['report'] is Map<String, dynamic>)
            ? LeakReport.fromJson(j['report'] as Map<String, dynamic>)
            : null,
      );
}
