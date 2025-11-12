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
      return 'draft';
  }
}

/// Suggestion for a specific leak point.
class LeakSuggestion {
  final String title;            // e.g., "Weatherstripping"
  final String subtitle;
  final String? costRange;       // e.g., "$10–20"
  final String? difficulty;      // e.g., "Easy"
  final String? lifetime;        // e.g., "3–5 years"
  final String? estimatedReduction; // e.g., "50–70%"

  LeakSuggestion({
    required this.title,
    required this.subtitle,
    this.costRange,
    this.difficulty,
    this.lifetime,
    this.estimatedReduction,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'costRange': costRange,
        'difficulty': difficulty,
        'lifetime': lifetime,
        'estimatedReduction': estimatedReduction,
      };

  factory LeakSuggestion.fromJson(Map<String, dynamic> j) => LeakSuggestion(
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        costRange: j['costRange'] as String?,
        difficulty: j['difficulty'] as String?,
        lifetime: j['lifetime'] as String?,
        estimatedReduction: j['estimatedReduction'] as String?,
      );
}


/// Report payload embedded in a task (can be null when not analyzed yet).
class LeakReport {
  final String? energyLossCost;   // e.g., "$142/year"
  final String? energyLossValue;  // e.g., "15.8 kWh/mo"
  final String? leakSeverity;     // e.g., "Moderate"
  final String? savingsCost;      // e.g., "$31/year"
  final String? savingsPercent;   // e.g., "19% reduction"
  final List<LeakSuggestion> suggestions;
  final String? imagePath;          // module-relative path (thermal preferred)
  final String? thumbPath;          // optional thumbnail path


  const LeakReport({
    this.energyLossCost,
    this.energyLossValue,
    this.leakSeverity,
    this.savingsCost,
    this.savingsPercent,
    this.suggestions = const [],
    this.imagePath,
    this.thumbPath,
  });

  Map<String, dynamic> toJson() => {
        'energyLossCost': energyLossCost,
        'energyLossValue': energyLossValue,
        'leakSeverity': leakSeverity,
        'savingsCost': savingsCost,
        'savingsPercent': savingsPercent,
        'imagePath': imagePath,
        'thumbPath': thumbPath,
        'suggestions': suggestions.map((e) => e.toJson()).toList(),
      };

  factory LeakReport.fromJson(Map<String, dynamic> j) => LeakReport(
        energyLossCost: j['energyLossCost'] as String?,
        energyLossValue: j['energyLossValue'] as String?,
        leakSeverity: j['leakSeverity'] as String?,
        savingsCost: j['savingsCost'] as String?,
        savingsPercent: j['savingsPercent'] as String?,
        imagePath: j['imagePath'] as String?,
        thumbPath: j['thumbPath'] as String?,
        suggestions: (j['suggestions'] as List<dynamic>? ?? [])
            .map((e) => LeakSuggestion.fromJson(e as Map<String, dynamic>))
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

  //inside and outside temperature at time thermal images were taken
  String? insideTemp;
  String? outsideTemp;

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
    this.insideTemp,
    this.outsideTemp,
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
    String? insideTemp,
    String? outsideTemp,
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
      insideTemp: insideTemp ?? this.insideTemp,
      outsideTemp: outsideTemp ?? this.outsideTemp,
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
        'insideTemp': insideTemp,
        'outsideTemp': outsideTemp,
        'report': report?.toJson(),
      };

  factory LeakageTask.fromJson(Map<String, dynamic> j) {
    final reportJson = j['report'];
    final hasReport = reportJson is Map<String, dynamic>;
    // Default state: if missing, infer draft unless report exists -> open


    return LeakageTask(
      id: j['id'] as String?,
      title: j['title'] as String,
      type: j['type'] as String,
      photoPaths: (j['photoPaths'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(j['createdAt'] as String),
      state: _stateFromString(j['state'] as String?),
      decision: j['decision'] as String?,
      closedResult: j['closedResult'] as String?,
      analysisSummary: j['analysisSummary'] as String?,
      recommendations: (j['recommendations'] as List<dynamic>?)?.cast<String>(),
      insideTemp: j['insideTemp'] as String?,
      outsideTemp: j['outsideTemp'] as String?,
      report: hasReport ? LeakReport.fromJson(reportJson) : null,
    );
  }
}
