// lib/ui/modules/leakage/leakage_task_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/leakage_task.dart';
import '../../../state/leakage_task_provider.dart';

class LeakageTaskPage extends ConsumerStatefulWidget {
  final String taskId;
  const LeakageTaskPage({Key? key, required this.taskId}) : super(key: key);

  @override
  ConsumerState<LeakageTaskPage> createState() => _LeakageTaskPageState();
}

/// Model for one leakage point's media
class LeakagePoint {
  String? rgbPath;
  String? thermalPath;
  LeakagePoint({this.rgbPath, this.thermalPath});
}

class _LeakageTaskPageState extends ConsumerState<LeakageTaskPage> {
  late TextEditingController _titleCtrl;
  String _selectedType = '';
  List<LeakagePoint> _points = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(leakageTaskListProvider.notifier);
    final existing = notifier.getById(widget.taskId);
    if (existing != null) {
      _titleCtrl = TextEditingController(text: existing.title);
      _selectedType = existing.type;
      final paths = existing.photoPaths;
      for (int i = 0; i < paths.length; i += 2) {
        _points.add(LeakagePoint(
          rgbPath: paths[i],
          thermalPath: i + 1 < paths.length ? paths[i + 1] : null,
        ));
      }
      if (_points.isEmpty) {
        _points = [LeakagePoint()];
      }
    } else {
      _titleCtrl = TextEditingController();
      _points = [LeakagePoint()];
    }
  }

  void _addPoint() {
    setState(() {
      _points.add(LeakagePoint());
    });
  }

  void _removePoint(int index) {
    setState(() {
      _points.removeAt(index);
    });
  }

  void _saveDraft() {
    final notifier = ref.read(leakageTaskListProvider.notifier);
    final existing = notifier.getById(widget.taskId);
    final allPaths = <String>[];
    for (var pt in _points) {
      if (pt.rgbPath != null) allPaths.add(pt.rgbPath!);
      if (pt.thermalPath != null) allPaths.add(pt.thermalPath!);
    }
    final task = LeakageTask(
      id: widget.taskId,
      title: _titleCtrl.text,
      type: _selectedType,
      photoPaths: allPaths,
      createdAt: existing?.createdAt,
      analysisSummary: existing?.analysisSummary,
      recommendations: existing?.recommendations,
    );
    notifier.upsertTask(task);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved locally')),
    );
  }

  void _submit() {
    _saveDraft();
    context.push('/leakage/report/${widget.taskId}');
  }

  Future<void> _captureRgb(int index) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _points[index].rgbPath = file.path);
    }
  }

  Future<void> _pickRgb(int index) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _points[index].rgbPath = file.path);
    }
  }

  Future<void> _captureThermal(int index) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _points[index].thermalPath = file.path);
    }
  }

  Future<void> _pickThermal(int index) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _points[index].thermalPath = file.path);
    }
  }

  Widget _buildPointCard(int index) {
    final point = _points[index];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Leakage Point ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_points.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePoint(index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // RGB section
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: point.rgbPath == null
                            ? const Center(
                                child:
                                    Icon(Icons.image, color: Colors.grey))
                            : Image.file(File(point.rgbPath!),
                                fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _captureRgb(index),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton.icon(
                        onPressed: () => _pickRgb(index),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Thermal section
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: point.thermalPath == null
                            ? const Center(
                                child: Icon(Icons.thermostat,
                                    color: Colors.grey))
                            : Image.file(File(point.thermalPath!),
                                fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _captureThermal(index),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton.icon(
                        onPressed: () => _pickThermal(index),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/leakage/dashboard'),
        ),
        title: const Text('Create Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Living Room North Window',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Type',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ToggleButtons(
              isSelected: [
                _selectedType == 'window',
                _selectedType == 'door',
                _selectedType == 'wall',
              ],
              onPressed: (i) {
                setState(() {
                  _selectedType = ['window', 'door', 'wall'][i];
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Window')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Door')),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Wall')),
              ],
            ),
            const SizedBox(height: 24),
            // Point cards
            ...List.generate(_points.length, (i) => _buildPointCard(i)),
            // Add new point button
            Center(
              child: TextButton.icon(
                onPressed: _addPoint,
                icon: const Icon(Icons.add),
                label: const Text('Add New Point'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: _saveDraft, child: const Text('Save Draft'))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Submit & Analyze'))),
          ],
        ),
      ),
    );
  }
}
