import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_store.dart';
import '../theme.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final tasks = store.tasks
              .where(
                (task) =>
                    !task.done &&
                    (task.deadline == null || store.isToday(task.deadline!)),
              )
              .toList();
          final expenses = store.expenses
              .where((expense) => store.isToday(expense.date))
              .fold<double>(0, (sum, expense) => sum + expense.amount);
          final calories = store.foods
              .where((food) => store.isToday(food.date))
              .fold<double>(0, (sum, food) => sum + food.calories);
          final medicineCount = [
            store.morningMedicine,
            store.eveningMedicine,
          ].where((taken) => taken).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
            children: [
              Text(
                DateFormat('EEEE, d MMMM', 'uk').format(DateTime.now()),
                style: const TextStyle(color: Colors.white54),
              ),
              const GradientTitle('Сьогодні'),
              const SizedBox(height: 18),
              const Text(
                'Ліки',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Column(
                  children: [
                    _Medicine(
                      title: 'Ранкові таблетки',
                      icon: Icons.wb_sunny_outlined,
                      value: store.morningMedicine,
                      onChanged: (value) =>
                          store.toggleMedicine(true, value!),
                    ),
                    const Divider(height: 1),
                    _Medicine(
                      title: 'Вечірні таблетки',
                      icon: Icons.nights_stay_outlined,
                      value: store.eveningMedicine,
                      onChanged: (value) =>
                          store.toggleMedicine(false, value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                children: [
                  MetricCard(
                    icon: Icons.task_alt,
                    value: '${tasks.length}',
                    label: 'активних завдань',
                  ),
                  MetricCard(
                    icon: Icons.payments_outlined,
                    value: '${expenses.toStringAsFixed(0)} ₴',
                    label: 'витрачено',
                    color: orange,
                  ),
                  MetricCard(
                    icon: Icons.local_fire_department_outlined,
                    value: '${calories.round()}',
                    label: 'ккал сьогодні',
                    color: purple,
                  ),
                  MetricCard(
                    icon: Icons.medication_outlined,
                    value: '$medicineCount/2',
                    label: 'приймання ліків',
                  ),
                ],
              ),
              if (tasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'У планах',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ...tasks.take(3).map(
                      (task) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.radio_button_unchecked,
                            color: green,
                          ),
                          title: Text(task.title),
                          subtitle: Text(task.category),
                        ),
                      ),
                    ),
              ],
            ],
          );
        },
      );
}

class _Medicine extends StatelessWidget {
  const _Medicine({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
        secondary: Icon(icon, color: value ? green : Colors.white38),
        title: Text(title),
        subtitle: Text(
          value ? 'Прийнято' : 'Ще не відмічено',
          style: TextStyle(color: value ? green : Colors.white38),
        ),
        value: value,
        onChanged: onChanged,
      );
}
