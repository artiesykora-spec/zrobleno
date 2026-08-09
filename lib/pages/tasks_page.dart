import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_store.dart';
import '../dialogs.dart';
import '../models.dart';
import '../theme.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({required this.store, super.key}); final AppStore store;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: store, builder: (context, _) { final tasks = [...store.tasks]..sort((a,b) => a.done == b.done ? b.priority.index.compareTo(a.priority.index) : (a.done ? 1 : -1)); return Scaffold(backgroundColor: Colors.transparent, floatingActionButton: FloatingActionButton(onPressed: () => editTask(context, store), child: const Icon(Icons.add)), body: CustomScrollView(slivers: [
    const SliverPadding(padding: EdgeInsets.fromLTRB(20, 22, 20, 10), sliver: SliverToBoxAdapter(child: GradientTitle('Zrobleno'))),
    SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), sliver: tasks.isEmpty ? const SliverFillRemaining(hasScrollBody: false, child: _Empty()) : SliverList.builder(itemCount: tasks.length, itemBuilder: (context, i) { final task = tasks[i]; return Dismissible(key: ValueKey(task.id), direction: DismissDirection.endToStart, background: Container(margin: const EdgeInsets.symmetric(vertical: 5), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.delete)), onDismissed: (_) => store.deleteTask(task), child: Card(child: ListTile(onTap: () => editTask(context, store, task), leading: Checkbox(value: task.done, onChanged: (v) { task.done = v!; store.changed(); }), title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: task.done ? TextDecoration.lineThrough : null, color: task.done ? Colors.white38 : null)), subtitle: Wrap(spacing: 8, children: [Text(task.category), if (task.deadline != null) Text('• ${DateFormat('dd.MM').format(task.deadline!)}')]), trailing: Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: [Colors.blue, orange, Colors.redAccent][task.priority.index]))))); })),
  ])); });
}
class _Empty extends StatelessWidget { const _Empty(); @override Widget build(BuildContext context) => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.task_alt, size: 64, color: green), SizedBox(height: 16), Text('Усе зроблено!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text('Додайте перше завдання', style: TextStyle(color: Colors.white54))])); }
