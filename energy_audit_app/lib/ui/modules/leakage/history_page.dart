// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:uuid/uuid.dart';
// import '../../../models/leakage_task.dart';

// class LeakageHistoryPage extends ConsumerWidget {
//   const LeakageHistoryPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // TODO: 用 Provider/Service 读取持久化的任务列表
//     final tasks = <LeakageTask>[
//       LeakageTask(title: 'Front door leak test', type: 'door'),
//       LeakageTask(title: 'Window seal inspection', type: 'window'),
//     ];

//     return Scaffold(
//       appBar: AppBar(title: const Text('Leakage History')),
//       body: ListView.separated(
//         itemCount: tasks.length,
//         separatorBuilder: (_, __) => const Divider(),
//         itemBuilder: (ctx, i) {
//           final t = tasks[i];
//           return ListTile(
//             leading: const Icon(Icons.water_damage),
//             title: Text(t.title),
//             subtitle: Text(
//                 'Created: ${t.createdAt.toLocal().toString().split('.').first}'),
//             onTap: () => context.push('/leakage/task/${t.id}'),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () =>
//             context.push('/leakage/task/${const Uuid().v4()}'), // 新任务
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
