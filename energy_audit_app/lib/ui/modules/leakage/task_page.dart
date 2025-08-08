// lib/ui/modules/leakage/task_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p; // <-- needed for p.extension(...)

import '../../../models/leakage_task.dart';
import '../../../providers/leakage_task_provider.dart'; // moved from state/ to providers/
import '../../../providers/repository_providers.dart'; // moved from state/ to providers/
import '../../../providers/user_provider.dart'; // moved from state/ to providers/

class LeakageTaskPage extends ConsumerStatefulWidget {
  final String taskId;
  const LeakageTaskPage({Key? key, required this.taskId}) : super(key: key);

  @override
  ConsumerState<LeakageTaskPage> createState() => _LeakageTaskPageState();
}

class _Obs {
  String? rgbRel; // module-relative path
  String? thermalRel; // module-relative path
}

class _LeakageTaskPageState extends ConsumerState<LeakageTaskPage> {
  final _titleCtrl = TextEditingController();
  String _type = '';
  final List<_Obs> _obs = [];
  bool _saving = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  void _loadExisting() {
    final task = ref
        .read(leakageTaskListProvider.notifier)
        .getById(widget.taskId);
    if (task != null) {
      _titleCtrl.text = task.title;
      _type = task.type;
      // Convert flat photoPaths [rgb, thermal, rgb, thermal...] into obs pairs
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
      // fresh new task with one empty observation by default
      _obs.add(_Obs());
    }
    setState(() {});
  }

  Future<void> _saveLocally() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final photos = <String>[];
      for (final o in _obs) {
        if (o.rgbRel != null) photos.add(o.rgbRel!);
        if (o.thermalRel != null) photos.add(o.thermalRel!);
      }
      final current = ref
          .read(leakageTaskListProvider.notifier)
          .getById(widget.taskId);
      final task = LeakageTask(
        id: widget.taskId,
        title: _titleCtrl.text.trim(),
        type: _type,
        photoPaths: photos,
        createdAt: current?.createdAt,
        analysisSummary: current?.analysisSummary,
        recommendations: current?.recommendations,
        report: current?.report, // keep existing report if any
      );
      await ref.read(leakageTaskListProvider.notifier).upsertTask(task);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved locally')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitAndAnalyze() async {
    // Ask how many leak points to generate (mock)
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: '2');
        return AlertDialog(
          title: const Text('Detected points'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'How many leak points should be generated?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final n = int.tryParse(ctrl.text.trim()) ?? 0;
                Navigator.pop(ctx, n < 0 ? 0 : n);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (count == null) return;

    setState(() => _submitting = true);
    try {
      // 1) Save current edits
      await _saveLocally();
      // 2) Call mock backend via provider (will write report)
      await ref
          .read(leakageTaskListProvider.notifier)
          .submitForAnalysis(widget.taskId, detectedCount: count);
      if (!mounted) return;
      // 3) Go to report
      context.go('/leakage/report/${widget.taskId}');
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
    final uid =
        (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    // Suggested filename: obs<idx>_<kind>.<ext>
    final ext = p.extension(x.path).isNotEmpty ? p.extension(x.path) : '.jpg';
    final kind = isThermal ? 'thermal' : 'rgb';
    final preferred = 'obs${index}_${kind}$ext';

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
    final cs = Theme.of(context).colorScheme;

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
                  child:
                      _saving
                          ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Save Locally'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitAndAnalyze,
                  icon:
                      _submitting
                          ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.cloud_upload),
                  label: Text(
                    _submitting ? 'Submitting...' : 'Submit & Analyze',
                  ),
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
            DropdownButtonFormField<String>(
              value: _type.isEmpty ? null : _type,
              items:
                  const ['door', 'window', 'wall']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              decoration: const InputDecoration(labelText: 'Type'),
              onChanged: (v) => setState(() => _type = v ?? ''),
            ),
            const SizedBox(height: 16),

            // Observations
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Observations',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),

            for (int i = 0; i < _obs.length; i++)
              _ObservationCard(
                index: i,
                data: _obs[i],
                onPickRgb:
                    (fromCamera) => _pickOrCapture(
                      index: i,
                      isThermal: false,
                      fromCamera: fromCamera,
                    ),
                onPickThermal:
                    (fromCamera) => _pickOrCapture(
                      index: i,
                      isThermal: true,
                      fromCamera: fromCamera,
                    ),
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
            const SizedBox(height: 80), // leave space for bottom bar
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
    Key? key,
    required this.index,
    required this.data,
    required this.onPickRgb,
    required this.onPickThermal,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid =
        (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    Future<Widget> _preview(String? rel) async {
      if (rel == null) {
        return Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image, size: 40)),
        );
      }
      final abs = await fs.resolveModuleAbsolute(uid, 'leakage', rel);
      final f = File(abs);
      if (!await f.exists()) {
        return Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
        );
      }
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder:
                (_) => Dialog(
                  insetPadding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    maxScale: 6,
                    child: Image.file(f, fit: BoxFit.contain),
                  ),
                ),
          );
        },
        child: Image.file(
          f,
          height: 200,
          width: double.infinity,
          fit: BoxFit.contain, // show full image without cropping
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Observation ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // RGB block
            const Text('RGB Image'),
            FutureBuilder<Widget>(
              future: _preview(data.rgbRel),
              builder: (_, snap) => snap.data ?? const SizedBox(height: 120),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onPickRgb(true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onPickRgb(false),
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Thermal block
            const Text('Thermal Image'),
            FutureBuilder<Widget>(
              future: _preview(data.thermalRel),
              builder: (_, snap) => snap.data ?? const SizedBox(height: 120),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onPickThermal(true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onPickThermal(false),
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
