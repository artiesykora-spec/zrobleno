import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_store.dart';
import '../dialogs.dart';
import '../theme.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final tasks = [...store.tasks]..sort(
              (a, b) => a.done == b.done
                  ? b.priority.index.compareTo(a.priority.index)
                  : (a.done ? 1 : -1),
            );
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton(
              onPressed: () => editTask(context, store),
              child: const Icon(Icons.add),
            ),
            body: CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientTitle('МОЇ СПРАВИ'),
                        SizedBox(height: 3),
                        Text(
                          'Маленькі квести для великого прогресу',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: tasks.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _Empty(),
                        )
                      : SliverList.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Dismissible(
                              key: ValueKey(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade800,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(Icons.delete),
                              ),
                              onDismissed: (_) => store.deleteTask(task),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: PaperPanel(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 9,
                                  ),
                                  onTap: () => editTask(context, store, task),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () =>
                                            store.toggleTask(task, !task.done),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 260,
                                          ),
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: task.done
                                                ? gameMint
                                                : const Color(0xFFF9F3E5),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: gameInk,
                                              width: 2,
                                            ),
                                          ),
                                          child: task.done
                                              ? const Icon(
                                                  Icons.star_rounded,
                                                  color: gameInk,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: TextStyle(
                                                color: gameInk,
                                                fontWeight: FontWeight.w900,
                                                decoration: task.done
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Wrap(
                                              spacing: 7,
                                              children: [
                                                Text(
                                                  task.category,
                                                  style: const TextStyle(
                                                    color: Color(0xFF766A69),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                if (task.deadline != null)
                                                  Text(
                                                    '• ${DateFormat('dd.MM').format(task.deadline!)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF766A69),
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 12,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: [
                                            const Color(0xFF80A9D7),
                                            orange,
                                            gameCoral,
                                          ][task.priority.index],
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                            color: gameInk,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: PaperPanel(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration_rounded, size: 58, color: gameMint),
              SizedBox(height: 12),
              Text(
                'УСЕ ЗРОБЛЕНО!',
                style: TextStyle(
                  color: gameInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Додай нове завдання',
                style: TextStyle(color: Color(0xFF766A69), fontSize: 10),
              ),
            ],
          ),
        ),
      );
}
