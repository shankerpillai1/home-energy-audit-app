import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../models/leakage_task.dart';
import '../../../providers/leakage_task_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_provider.dart';

class LeakageTaskListPage extends ConsumerStatefulWidget {
  const LeakageTaskListPage({super.key});

  @override
  ConsumerState<LeakageTaskListPage> createState() => _LeakageTaskListPageState();
}

class _LeakageTaskListPageState extends ConsumerState<LeakageTaskListPage> {
  bool _submitting = false;
  BuildContext? _progressSheetContext;
  
  /// Show a dismissible bottom sheet with an indeterminate progress indicator.
  void _showProgressSheet() {
    _progressSheetContext = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      isDismissible: true,
      useSafeArea: true,
      builder: (ctx) {
        _progressSheetContext = ctx;
        return const _AnalyzingSheet();
      },
    ).whenComplete(() {
      // When user swipes it down, we just clear the handle.
      _progressSheetContext = null;
    });
  }

  /// Close progress sheet if still shown.
  void _closeProgressSheetIfAny() {
    final c = _progressSheetContext;
    if (c != null) {
      // Try to pop only the sheet route.
      Navigator.of(c).maybePop();
      _progressSheetContext = null;
    }
  }

  Future<void> _submitAll() async {
    final tasks = ref.read(leakageTaskListProvider.notifier).state;
    final pending = <LeakageTask>[];

    for (final t in tasks) {
      if (t.state == LeakageTaskState.draft) {
        pending.add(t);
      }
    }

    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No draft tasks to submit')),
      );
      return;
    }

    setState(() => _submitting = true);
    _showProgressSheet();

    try {
      for (final t in pending) {
        String taskTitle = t.title;
        final hasTemps = (t.outsideTemp != null) && (t.insideTemp != null);
        if (!hasTemps) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$taskTitle is missing one or more temperature field required for analysis.')),
          );
        }

        else
        {
          final hasAnyImage = t.photoPaths.isNotEmpty;
          if (hasAnyImage) {
            ref
              .read(leakageTaskListProvider.notifier)
              .submitForAnalysis(t.id);
          }
          else{
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please add at least one image to $taskTitle for analysis.')),
            );
          }
        }
      }

      // On success: close the progress sheet and navigate to report.
      _closeProgressSheetIfAny();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission Complete')),
      );
      context.go('/leakage/dashboard');
    } catch (e) {
      _closeProgressSheetIfAny();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(leakageTaskListProvider)
      .where((t) => t.state == LeakageTaskState.draft)
      .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leakage Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final id = const Uuid().v4();
          await ref.read(leakageTaskListProvider.notifier).upsertTask(
                LeakageTask(
                  id: id,
                  title: '',
                  type: '',
                  photoPaths: [],
                  state: LeakageTaskState.draft,
                ),
              );

          context.push('/leakage/task/$id');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submitAll,
            icon: _submitting
                ? const SizedBox(
                    height: 16, width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload),
            label: Text(_submitting ? 'Analyzing...' : 'Analyze All'),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),

          if (tasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No tasks available.', style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          else
            Column(
              children: tasks
                  .map((dft) => _DraftListTile(
                        taskId: dft.id,
                        draft: dft,
                      ))
                  .toList(),
            ),
        ]),
      ),
    );
  }
}

class _DraftListTile extends ConsumerWidget {
  final String taskId;
  final LeakageTask draft;
  const _DraftListTile({required this.taskId, required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: _DraftThumb(draft: draft),
        title: Text(draft.title),
        subtitle: Text('Images: ${draft.photoPaths.length}'),
        trailing: const Icon(Icons.keyboard_arrow_up), // hint for slide-up detail
        onTap: () {
          context.push('/leakage/task/${draft.id}');
        },
      ),
    );
  }
}

class _DraftThumb extends ConsumerWidget {
  final LeakageTask draft;
  const _DraftThumb({required this.draft});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    Future<String?> absOrNull(String? relOrAbs) async {
      if (relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    return FutureBuilder<String?>(
      future: (draft.photoPaths.isNotEmpty)
        ? absOrNull(draft.photoPaths.first)
        : Future.value(null),
      builder: (context, snap) {
        final path = snap.data;
        if (path == null || !File(path).existsSync()) {
          return const SizedBox(
            width: 56,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
              child: Icon(Icons.image_not_supported),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(File(path), width: 56, height: 56, fit: BoxFit.cover),
        );
      },
    );
  }
}

class LeakageTaskPage extends ConsumerStatefulWidget {
  final String taskId;
  const LeakageTaskPage({super.key, required this.taskId});

  @override
  ConsumerState<LeakageTaskPage> createState() => _LeakageTaskPageState();
}

class _Obs {
  String? rgbRel; // module-relative path
  String? thermalRel; // module-relative path
}

class _LeakageTaskPageState extends ConsumerState<LeakageTaskPage> {
  final _titleCtrl = TextEditingController();
  final _outsideTempCtrl = TextEditingController();
  final _insideTempCtrl = TextEditingController();
  String _type = '';
  final List<_Obs> _obs = [];
  bool _saving = false;
  bool _submitting = false;

  // Keep a handle to progress sheet context so we can close it programmatically.
  BuildContext? _progressSheetContext;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final task = ref.read(leakageTaskListProvider.notifier).getById(widget.taskId);
    if (task != null) {
      _titleCtrl.text = task.title;
      _outsideTempCtrl.text = (task.outsideTemp == null) ? '' : task.outsideTemp.toString();
      _insideTempCtrl.text = (task.insideTemp == null) ? '' : task.insideTemp.toString();
      _type = task.type;
      final pp = task.photoPaths;
      if (pp.isNotEmpty) {
        for (int i = 0; i < pp.length; i += 2) {
          final o = _Obs();
          o.rgbRel = pp[i];
          if (i + 1 < pp.length) o.thermalRel = pp[i + 1];
          _obs.add(o);
        }
      }
    } else {
      _obs.add(_Obs()); // fresh draft: one empty observation
    }
    setState(() {});
  }

  Future<void> _saveLocally() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final hasAnyImage = _obs.any((o) => o.rgbRel != null || o.thermalRel != null);
      if (!hasAnyImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image before submitting for analysis')),
        );
      }
      final hasTemps = (_outsideTempCtrl.text != "") && (_insideTempCtrl.text != "");
      if (!hasTemps) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing one or more temperature field. Please add before submitting for analysis')),
        );
      }  

      final photos = <String>[];
      for (final o in _obs) {
        if (o.rgbRel != null) photos.add(o.rgbRel!);
        if (o.thermalRel != null) photos.add(o.thermalRel!);
      }
      final current =
          ref.read(leakageTaskListProvider.notifier).getById(widget.taskId);

      final task = (current ?? LeakageTask(title: '', type: ''))
          .copyWith( // keep status/result/decision/report if present
            title: _titleCtrl.text.trim(),
            outsideTemp: _outsideTempCtrl.text.trim(),
            insideTemp: _insideTempCtrl.text.trim(),
            type: _type,
            photoPaths: photos,
          );

      await ref.read(leakageTaskListProvider.notifier).upsertTask(
            task.copyWith(), // updatedAt auto-bumped in copyWith
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved locally')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Show a dismissible bottom sheet with an indeterminate progress indicator.
  void _showProgressSheet() {
    _progressSheetContext = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      isDismissible: true,
      useSafeArea: true,
      builder: (ctx) {
        _progressSheetContext = ctx;
        return const _AnalyzingSheet();
      },
    ).whenComplete(() {
      // When user swipes it down, we just clear the handle.
      _progressSheetContext = null;
    });
  }

  /// Close progress sheet if still shown.
  void _closeProgressSheetIfAny() {
    final c = _progressSheetContext;
    if (c != null) {
      // Try to pop only the sheet route.
      Navigator.of(c).maybePop();
      _progressSheetContext = null;
    }
  }

  Future<void> _submitAndAnalyze() async {
    // Optional: simple validation hint (at least one image)
    final hasAnyImage = _obs.any((o) => o.rgbRel != null || o.thermalRel != null);
    if (!hasAnyImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    final hasTemps = (_outsideTempCtrl.text != "") && (_insideTempCtrl.text != "");
    if (!hasTemps) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing one or more temperature field')),
      );
      return;
    }
    

    setState(() => _submitting = true);
    _showProgressSheet();

    try {
      // Persist draft edits first.
      await _saveLocally();

      // Kick off the analysis (mock or HTTP dry-run based on providers).
      // We await it here to keep a single submission pipeline; the UI remains usable,
      // and the user can dismiss the progress sheet anytime.
      await ref
          .read(leakageTaskListProvider.notifier)
          .submitForAnalysis(widget.taskId);

      // On success: close the progress sheet and navigate to report.
      _closeProgressSheetIfAny();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report ready')),
      );
      context.go('/leakage/report/${widget.taskId}');
    } catch (e) {
      _closeProgressSheetIfAny();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickOrCapture({
    required int index,
    required bool isThermal,
    required bool fromCamera,
  }) async {
    final picker = ImagePicker();
    final XFile? x = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (x == null) return;

    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    final ext = p.extension(x.path).isNotEmpty ? p.extension(x.path) : '.jpg';
    final kind = isThermal ? 'thermal' : 'rgb';
    final preferred = 'obs${index}_$kind$ext';

    final rel = await fs.saveMediaFromFilePath(
      uid: uid,
      module: 'leakage',
      taskId: widget.taskId,
      sourcePath: x.path,
      preferredFileName: preferred,
    );

    final o = _obs[index];
    setState(() {
      if (isThermal) {
        o.thermalRel = rel;
      } else {
        o.rgbRel = rel;
      }
    });
  }

  void _addObservation() => setState(() => _obs.add(_Obs()));
  void _removeObservation(int index) => setState(() => _obs.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leakage Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/leakage/dashboard');
            }
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _saveLocally,
                  child: _saving
                      ? const SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitAndAnalyze,
                  icon: _submitting
                      ? const SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload),
                  label: Text(_submitting ? 'Analyzing…' : 'Analyze'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _outsideTempCtrl,
              decoration: const InputDecoration(labelText: 'Outside Temperature'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _insideTempCtrl,
              decoration: const InputDecoration(labelText: 'Inside Temperature'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type.isEmpty ? null : _type,
              items: const ['door', 'window', 'wall']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Type'),
              onChanged: (v) => setState(() => _type = v ?? ''),
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Observations', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),

            for (int i = 0; i < _obs.length; i++)
              _ObservationCard(
                index: i,
                data: _obs[i],
                onPickRgb: (fromCamera) =>
                    _pickOrCapture(index: i, isThermal: false, fromCamera: fromCamera),
                onPickThermal: (fromCamera) =>
                    _pickOrCapture(index: i, isThermal: true, fromCamera: fromCamera),
                onRemove: () => _removeObservation(i),
              ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addObservation,
                icon: const Icon(Icons.add),
                label: const Text('Add Observation'),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ObservationCard extends ConsumerWidget {
  final int index;
  final _Obs data;
  final void Function(bool fromCamera) onPickRgb;
  final void Function(bool fromCamera) onPickThermal;
  final VoidCallback onRemove;

  const _ObservationCard({
    required this.index,
    required this.data,
    required this.onPickRgb,
    required this.onPickThermal,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    Future<Widget> preview(String? rel) async {
      if (rel == null) {
        return Container(
          height: 200, width: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image, size: 40)),
        );
      }
      final abs = await fs.resolveModuleAbsolute(uid, 'leakage', rel);
      final f = File(abs);
      if (!await f.exists()) {
        return Container(
          height: 200, width: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
        );
      }
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(12),
              child: InteractiveViewer(maxScale: 6, child: Image.file(f, fit: BoxFit.contain)),
            ),
          );
        },
        child: Image.file(f, height: 200, width: double.infinity, fit: BoxFit.contain),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Observation ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(tooltip: 'Remove', onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
            ]),
            const SizedBox(height: 8),

            const Text('RGB Image'),
            FutureBuilder<Widget>(
              future: preview(data.rgbRel),
              builder: (_, snap) => snap.data ?? const SizedBox(height: 120),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => onPickRgb(true),
                icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => onPickRgb(false),
                icon: const Icon(Icons.upload), label: const Text('Upload'))),
            ]),

            const SizedBox(height: 16),

            const Text('Thermal Image'),
            FutureBuilder<Widget>(
              future: preview(data.thermalRel),
              builder: (_, snap) => snap.data ?? const SizedBox(height: 120),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => onPickThermal(true),
                icon: const Icon(Icons.camera_alt), label: const Text('Camera'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => onPickThermal(false),
                icon: const Icon(Icons.upload), label: const Text('Upload'))),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Simple, dismissible progress UI shown during analysis.
class _AnalyzingSheet extends StatelessWidget {
  const _AnalyzingSheet();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Container(
            width: 44, height: 4,
            decoration: BoxDecoration(
              color: Colors.black26, borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Analyzing your submission…', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'You can swipe down to continue using the app while analysis is completed.',
            style: textTheme.bodyMedium, textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down),
            label: const Text('Hide'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
