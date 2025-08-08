// lib/services/backend_api_service.dart
import 'dart:async';
import 'package:path/path.dart' as p;

import '../models/leakage_task.dart';
import '../services/file_storage_service.dart';
import '../utils/asset_to_file.dart';

/// Simulated backend service for leakage analysis.
/// Later, replace this with real HTTP calls.
class BackendApiService {
  final FileStorageService fs;
  final String uid;
  final String module;

  BackendApiService({
    required this.fs,
    required this.uid,
    this.module = 'leakage',
  });

  /// Analyze a task and return a mock report.
  /// [detectedCount]: how many leak points to generate (>=0).
  Future<LeakReport> analyzeLeakageTask(
    LeakageTask task, {
    int detectedCount = 2,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 600));

    // Try to use user's thermal photos if any; fallback to template
    final thermalRelList = _extractThermalRelPaths(task.photoPaths);
    final hasThermal = thermalRelList.isNotEmpty;

    // Ensure template is available for fallback
    final templateRel = await AssetToFile(fs, uid: uid, module: module)
        .ensureCopied(
      assetPath: 'assets/images/thermal_template.jpg',
      targetRelativePath: 'templates/thermal_template.jpg',
    );

    final points = <LeakReportPoint>[];
    for (int i = 0; i < detectedCount; i++) {
      // round-robin choose a thermal image
      final imgRel = hasThermal
          ? thermalRelList[i % thermalRelList.length]
          : templateRel;

      points.add(
        LeakReportPoint(
          title: 'Detected Leak #${i + 1}',
          subtitle: 'Location: N/A\nGap size: N/A\nHeat loss: N/A',
          imagePath: imgRel,
          thumbPath: imgRel,
          // fake a marker moving around
          markerX: 0.15 + 0.12 * (i % 5),
          markerY: 0.18 + 0.10 * (i % 4),
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

    // Simple high-level numbers for demo
    final report = LeakReport(
      energyLossCost: detectedCount == 0 ? r'$0/year' : r'$142/year',
      energyLossValue: detectedCount == 0 ? '0 kWh/mo' : '15.8 kWh/mo',
      leakSeverity: detectedCount == 0 ? 'None' : 'Moderate',
      savingsCost: detectedCount == 0 ? r'$0/year' : r'$31/year',
      savingsPercent: detectedCount == 0 ? '0%' : '19% reduction',
      points: points,
    );

    return report;
  }

  /// We treat every pair as [RGB, Thermal]. Thermal are at odd indices.
  List<String> _extractThermalRelPaths(List<String> photoPaths) {
    final result = <String>[];
    for (int i = 0; i < photoPaths.length; i++) {
      if (i % 2 == 1) {
        result.add(photoPaths[i]);
      }
    }
    return result;
  }
}
