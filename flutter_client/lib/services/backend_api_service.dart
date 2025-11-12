import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/leakage_task.dart';
import 'file_storage_service.dart';

/// Configuration for real HTTP backend flow.
/// Keep it optional; when omitted, the service can still operate in mock mode.
class BackendConfig {
  final Uri baseUri; // e.g., https://api.example.com
  final String? apiKey; // optional header (e.g., Bearer token or custom)
  final Duration timeout; // per-request timeout
  final Duration pollInterval; // delay between job polls
  final Duration maxWait; // max overall wait for job completion

  const BackendConfig({
    required this.baseUri,
    this.apiKey,
    this.timeout = const Duration(seconds: 20),
    this.pollInterval = const Duration(seconds: 2),
    this.maxWait = const Duration(seconds: 45),
  });
}

/// Exception type for backend HTTP failures.
class BackendApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? cause;
  BackendApiException(this.message, {this.statusCode, this.cause});
  @override
  String toString() => 'BackendApiException($statusCode): $message';
}

/// Simulated/real backend service for leakage analysis.
/// - Keeps existing mock method: [analyzeLeakageTask]
/// - Adds a complete (but inert-by-default) HTTP flow: [analyzeLeakageTaskHttp]
class BackendApiService {
  final FileStorageService fs;
  final String uid;
  final String module;
  final BackendConfig? config;
  final http.Client _client;

  BackendApiService({
    required this.fs,
    required this.uid,
    this.module = 'leakage',
    this.config,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  // ---------------------------------------------------------------------------
  // MOCK FLOW (existing behavior; unchanged public signature)
  // ---------------------------------------------------------------------------


  /// Generate a mock report using user's uploaded media as display images.
  /// With the "point" layer removed, we now produce only report-level data.
  Future<LeakReport> analyzeLeakageTask(
    LeakageTask task, {
    int detectedCount = 2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final candidates = _pickImageCandidates(task.photoPaths); // relative paths
    final rel = candidates.isNotEmpty
        ? candidates.first
        : (task.photoPaths.isNotEmpty ? task.photoPaths.first : null);

    final suggestions = List<LeakSuggestion>.generate(detectedCount, (i) {
      return LeakSuggestion(
        title: 'General Weatherstripping',
        subtitle: 'Enter Subtitle here',
        costRange: r'$10–20',
        difficulty: 'Easy',
        lifetime: '3–5 years',
        estimatedReduction: '50–70%',
      );
    });

    return LeakReport(
      energyLossCost: detectedCount == 0 ? r'$0/year' : r'$142/year',
      energyLossValue: detectedCount == 0 ? '0 kWh/mo' : '15.8 kWh/mo',
      leakSeverity: detectedCount == 0 ? 'None' : 'Moderate',
      savingsCost: detectedCount == 0 ? r'$0/year' : r'$31/year',
      savingsPercent: detectedCount == 0 ? '0%' : '19% reduction',
      imagePath: rel,
      thumbPath: rel,
      suggestions: suggestions,
    );
  }

  // ---------------------------------------------------------------------------
  // REAL HTTP FLOW (shell implemented; not used unless you call it explicitly)
  // ---------------------------------------------------------------------------

  /// Full HTTP pipeline:
  /// 1) Upload media and create a job
  /// 2) Poll job status until "done" (or timeout/error)
  /// 3) Map backend JSON payload into our LeakReport model
  ///
  /// This method does NOT persist the task/report; it just returns the mapped report.
  /// The caller (provider) should upsert the task with the returned report.
  ///
  /// Parameters:
  /// - [overrideDetectedCount]: optional parameter to influence backend behavior (if API supports).
  /// - [dryRun]: when true, skip real HTTP calls and return a backend-like fake mapped into LeakReport.
  Future<LeakReport> analyzeLeakageTaskHttp(
    LeakageTask task, {
    int? overrideDetectedCount,
    bool dryRun = false,
  }) async {
    final cfg = config;
    if (cfg == null) {
      throw BackendApiException('HTTP flow requested but BackendConfig is null.');
    }

    // 1) Create job with multipart (media + metadata)
    final createResp = await _createJobWithMedia(task, cfg, overrideDetectedCount: overrideDetectedCount);

    final jobId = createResp['jobId'] as String? ?? createResp['id'] as String?;
    if (jobId == null || jobId.isEmpty) {
      throw BackendApiException('Missing jobId in create response', cause: createResp);
    }

    // 2) Poll job until done or timeout
    final result = await _pollJobUntilDone(jobId, cfg);

    // 3) Map to our internal model
    return _mapBackendReport(result, fallbackImageRel: _fallbackImageRel(task));
  }

  // --- (1) Create job + upload media -------------------------------------------------------------

  Future<Map<String, dynamic>> _createJobWithMedia(
    LeakageTask task,
    BackendConfig cfg, {
    int? overrideDetectedCount,
  }) async {
    final endpoint = cfg.baseUri.resolve('/detect_leak'); // e.g., POST https://api/v1/leakage/jobs

    // Serialize the entire task as JSON
    final taskJson = jsonEncode(task.toJson());
    
    // Resolve local media files (absolute paths)
    final rels = task.photoPaths; 
    final files = <File>[];
    for (final rel in rels) {
      final abs = await fs.resolveModuleAbsolute(uid, module, rel);
      if (abs.isNotEmpty) {
        final f = File(abs);
        if (await f.exists()) files.add(f);
      }
    }

    final req = http.MultipartRequest('POST', endpoint);
    // Headers
    if (cfg.apiKey != null && cfg.apiKey!.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer ${cfg.apiKey}';
    }
    req.headers['Accept'] = 'application/json';

    // Metadata fields
    req.fields['uid'] = uid;
    req.fields['task_json'] = taskJson;
    if (overrideDetectedCount != null) {
      req.fields['override_detected_count'] = overrideDetectedCount.toString();}

    // Media parts
    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final stream = http.ByteStream(f.openRead());
      final length = await f.length();
      final part = http.MultipartFile('media$i', stream, length, filename: f.uri.pathSegments.last);
      req.files.add(part);
    }

    final streamed = await req.send().timeout(cfg.timeout);
    final resp = await http.Response.fromStream(streamed).timeout(cfg.timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw BackendApiException(
        'Create job failed',
        statusCode: resp.statusCode,
        cause: resp.body,
      );
    }
    return _decodeJson(resp.body);
  }

  // --- (2) Poll job -----------------------------------------------------------------------------

  Future<Map<String, dynamic>> _pollJobUntilDone(String jobId, BackendConfig cfg) async {
    final started = DateTime.now();
    while (true) {
      if (DateTime.now().difference(started) > cfg.maxWait) {
        throw BackendApiException('Job $jobId timed out after ${cfg.maxWait.inSeconds}s');
      }

      final endpoint = cfg.baseUri.resolve('/detect_leak/$jobId');
      final resp = await _getJson(endpoint, cfg);
      final status = (resp['status'] as String?)?.toLowerCase() ?? 'unknown';

      if (status == 'done' || status == 'completed' || resp.containsKey('report')) {
        // Normalize: ensure the returned object contains a "report" section
        if (!resp.containsKey('report')) {
          throw BackendApiException('Job finished but missing report payload', cause: resp);
        }
        return resp['report'] as Map<String, dynamic>;
      }

      if (status == 'error' || status == 'failed') {
        throw BackendApiException('Job $jobId failed', cause: resp);
      }

      // queued/running: wait and poll again
      await Future.delayed(cfg.pollInterval);
    }
  }

  // --- (3) Mapping backend JSON -> our LeakReport -----------------------------------------------

  LeakReport _mapBackendReport(
    Map<String, dynamic> reportJson, {
    String? fallbackImageRel,
  }) {
    String fmtUsdPerYear(Object? v) {
      final n = _asNum(v);
      return n == null ? r'$0/year' : '\$${n.toString()}/year';
    }

    String fmtKwhPerMonth(Object? v) {
      final n = _asNum(v);
      return n == null ? '0 kWh/mo' : '${n.toString()} kWh/mo';
    }

    String fmtPercent(Object? v) {
      final n = _asNum(v);
      if (n == null) return '0%';
      // Some backends might return already formatted strings like "19% reduction"
      final s = v.toString();
      if (s.contains('%')) return s;
      return '${n.toString()}% reduction';
    }

    String? imageRelOrUrl = (reportJson['imageUrl'] ?? reportJson['imagePath'])?.toString();
    String? thumbRelOrUrl = (reportJson['thumbUrl'] ?? reportJson['thumbPath'])?.toString();

    imageRelOrUrl ??= fallbackImageRel;
    thumbRelOrUrl ??= imageRelOrUrl;

    final suggestions = <LeakSuggestion>[];

    final topSug = (reportJson['suggestions'] as List?) ?? const [];
    for (final s in topSug) {
      final sm = (s is Map<String, dynamic>) ? s : <String, dynamic>{};
      suggestions.add(
        LeakSuggestion(
          title: (sm['title'] ?? '').toString(),
          subtitle: (sm['subtitle'] ?? '').toString(),
          costRange: (sm['costRange'] ?? '').toString(),
          difficulty: (sm['difficulty'] ?? '').toString(),
          lifetime: (sm['lifetime'] ?? '').toString(),
          estimatedReduction: (sm['estimatedReduction'] ?? '').toString(),
        ),
      );
    }

    return LeakReport(
      energyLossCost: fmtUsdPerYear(reportJson['energyLossCostUsdPerYear'] ?? reportJson['energyLossCost']),
      energyLossValue: fmtKwhPerMonth(reportJson['energyLossKwhPerMonth'] ?? reportJson['energyLossValue']),
      leakSeverity: (reportJson['severity'] ?? reportJson['leakSeverity'] ?? 'Moderate').toString(),
      savingsCost: fmtUsdPerYear(reportJson['savingsUsdPerYear'] ?? reportJson['savingsCost']),
      savingsPercent: fmtPercent(reportJson['savingsPercent'] ?? reportJson['savingsPercentValue']),
      imagePath: imageRelOrUrl,
      thumbPath: thumbRelOrUrl,
      suggestions: suggestions,
    );
  }

  // --- HTTP helpers -----------------------------------------------------------------------------

  Future<Map<String, dynamic>> _getJson(Uri url, BackendConfig cfg) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (cfg.apiKey != null && cfg.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${cfg.apiKey}';
    }
    final resp = await _client.get(url, headers: headers).timeout(cfg.timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw BackendApiException('GET ${url.path} failed', statusCode: resp.statusCode, cause: resp.body);
    }
    return _decodeJson(resp.body);
  }

  Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw BackendApiException('Unexpected JSON type (expected object)', cause: decoded);
  }

  // --- Utilities --------------------------------------------------------------------------------

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

  /// Choose one module-relative image path to display in report mapping when backend provides only remote URLs.
  String? _fallbackImageRel(LeakageTask task) {
    final c = _pickImageCandidates(task.photoPaths);
    return c.isNotEmpty ? c.first : (task.photoPaths.isNotEmpty ? task.photoPaths.first : null);
  }

  num? _asNum(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    final s = v.toString().trim().replaceAll(RegExp(r'[^\d\.\-]'), '');
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }
}
