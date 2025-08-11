import 'dart:async';

import '../models/leakage_task.dart';
import '../services/file_storage_service.dart';

/// Simulated backend service for leakage analysis.
/// Uses user-uploaded images only; no template fallback anymore.
class BackendApiService {
  final FileStorageService fs;
  final String uid;
  final String module;

  BackendApiService({
    required this.fs,
    required this.uid,
    this.module = 'leakage',
  });

  /// Generate a mock report.
  /// - detectedCount: number of leak points to create (>=0)
  /// Images are chosen from user's uploaded photos (prefer thermal).
  Future<LeakReport> analyzeLeakageTask(
    LeakageTask task, {
    int detectedCount = 2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final candidates = _pickImageCandidates(task.photoPaths); // relative paths
    final points = <LeakReportPoint>[];

    for (int i = 0; i < detectedCount; i++) {
      final rel = candidates.isNotEmpty ? candidates[i % candidates.length] : null;

      points.add(
        LeakReportPoint(
          title: 'Detected Leak #${i + 1}',
          subtitle: 'Location: N/A\nGap size: N/A\nHeat loss: N/A',
          imagePath: rel,
          thumbPath: rel,
          markerX: 0.12 + 0.15 * (i % 5),
          markerY: 0.18 + 0.12 * (i % 4),
          markerW: 0.18,
          markerH: 0.20,
          suggestions: [
            LeakSuggestion(
              title: 'General Weatherstripping',
              costRange: r'$10–20',
              difficulty: 'Easy',
              lifetime: '3–5 years',
              estimatedReduction: '50–70%',
            ),
          ],
        ),
      );
    }

    return LeakReport(
      energyLossCost: detectedCount == 0 ? r'$0/year' : r'$142/year',
      energyLossValue: detectedCount == 0 ? '0 kWh/mo' : '15.8 kWh/mo',
      leakSeverity: detectedCount == 0 ? 'None' : 'Moderate',
      savingsCost: detectedCount == 0 ? r'$0/year' : r'$31/year',
      savingsPercent: detectedCount == 0 ? '0%' : '19% reduction',
      points: points,
    );
  }

  /// Prefer thermal (odd indices), otherwise fall back to RGB.
  List<String> _pickImageCandidates(List<String> paths) {
    if (paths.isEmpty) return const [];
    final thermals = <String>[];
    final rgbs = <String>[];
    for (int i = 0; i < paths.length; i++) {
      if (i % 2 == 1) {
        thermals.add(paths[i]);
      } else {
        rgbs.add(paths[i]);
      }
    }
    return thermals.isNotEmpty ? thermals : rgbs;
  }
}
