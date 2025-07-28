import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/leakage_task.dart';

class LeakageTaskPage extends ConsumerStatefulWidget {
  final String taskId;
  const LeakageTaskPage({Key? key, required this.taskId}) : super(key: key);

  @override
  _LeakageTaskPageState createState() => _LeakageTaskPageState();
}

class _LeakageTaskPageState extends ConsumerState<LeakageTaskPage> {
  late LeakageTask _task;
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // TODO: 从 Provider/Service 加载已有任务；若不存在则新建
    _task = LeakageTask(id: widget.taskId, title: '', type: '');
    _titleCtrl.text = _task.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leakage Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Task Title'),
            onChanged: (v) => _task.title = v,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _task.type.isEmpty ? null : _task.type,
            items: ['door', 'window', 'attic']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            decoration: const InputDecoration(labelText: 'Type'),
            onChanged: (v) => setState(() => _task.type = v!),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 调用 camera 插件，拍照并保存路径到 _task.photoPaths
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Upload Photo'),
          ),
          const Spacer(),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: 本地保存 _task
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved locally')));
                },
                child: const Text('Save Locally'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: 提交给后端 AI 分析，拿到结果后更新 _task.analysisSummary / recommendations
                  // 然后跳转到 ReportPage
                  context.push('/leakage/report/${_task.id}');
                },
                child: const Text('Submit & Analyze'),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
