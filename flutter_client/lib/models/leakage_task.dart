import 'package:uuid/uuid.dart';

/// Task lifecycle state
enum LeakageTaskState { draft, open, closed }

LeakageTaskState _stateFromString(String? s) {
  switch (s) {
    case 'open':
      return LeakageTaskState.open;
    case 'closed':
      return LeakageTaskState.closed;
    case 'draft':
    default:
      return LeakageTaskState.draft;
  }
}

String _stateToString(LeakageTaskState s) {
  switch (s) {
    case LeakageTaskState.open:
      return 'open';
    case LeakageTaskState.closed:
      return 'closed';
    case LeakageTaskState.draft:
    default:
      return 'draft';
  }
}

/// Suggestion for a specific leak point.
class LeakSuggestion {
  final String title;            // e.g., "Weatherstripping"
  final String? costRange;       // e.g., "$10–20"
  final String? difficulty;      // e.g., "Easy"
  final String? lifetime;        // e.g., "3–5 years"
  final String? estimatedReduction; // e.g., "50–70%"

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
  final String? imagePath;          // module-relative path (thermal preferred)
  final String? thumbPath;          // optional thumbnail path

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
  List<String> photoPaths;  // module-relative image paths (RGB/Thermal)
  DateTime createdAt;

  /// Task lifecycle state (drives Dashboard grouping)
  LeakageTaskState state;

  /// Optional decision tag (e.g., 'fix_planned', 'fix_done', 'wont_fix')
  String? decision;

  /// Optional closed result (e.g., 'no_leak')
  String? closedResult;

  // Legacy optional fields (kept for compatibility)
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
    this.state = LeakageTaskState.draft,
    this.decision,
    this.closedResult,
    this.analysisSummary,
    this.recommendations,
    this.report,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  LeakageTask copyWith({
    String? id,
    String? title,
    String? type,
    List<String>? photoPaths,
    DateTime? createdAt,
    LeakageTaskState? state,
    String? decision,
    String? closedResult,
    String? analysisSummary,
    List<String>? recommendations,
    LeakReport? report,
  }) {
    return LeakageTask(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      photoPaths: photoPaths ?? this.photoPaths,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
      decision: decision ?? this.decision,
      closedResult: closedResult ?? this.closedResult,
      analysisSummary: analysisSummary ?? this.analysisSummary,
      recommendations: recommendations ?? this.recommendations,
      report: report ?? this.report,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'photoPaths': photoPaths,
        'createdAt': createdAt.toIso8601String(),
        'state': _stateToString(state),
        'decision': decision,
        'closedResult': closedResult,
        'analysisSummary': analysisSummary,
        'recommendations': recommendations,
        'report': report?.toJson(),
      };

  factory LeakageTask.fromJson(Map<String, dynamic> j) {
    final reportJson = j['report'];
    final hasReport = reportJson is Map<String, dynamic>;
    // Default state: if missing, infer draft unless report exists -> open
    final inferredState =
        hasReport ? LeakageTaskState.open : LeakageTaskState.draft;

    return LeakageTask(
      id: j['id'] as String?,
      title: j['title'] as String,
      type: j['type'] as String,
      photoPaths: (j['photoPaths'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(j['createdAt'] as String),
      state: _stateFromString(j['state'] as String?) ?? inferredState,
      decision: j['decision'] as String?,
      closedResult: j['closedResult'] as String?,
      analysisSummary: j['analysisSummary'] as String?,
      recommendations: (j['recommendations'] as List<dynamic>?)?.cast<String>(),
      report: hasReport ? LeakReport.fromJson(reportJson) : null,
    );
  }
}
