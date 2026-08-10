import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_store.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/pixel_bird.dart';
import 'assistant_page.dart';
import 'settings_page.dart';
import 'world_page.dart';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM', 'uk').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const GradientTitle('Сьогодні'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Нагадування',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsPage(store: store),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AssistantCard(store: store),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Ліки',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_time(store.reminders.morningHour, store.reminders.morningMinute)} · '
                '${_time(store.reminders.eveningHour, store.reminders.eveningMinute)}',
                style: const TextStyle(color: Colors.white38),
              ),
            ],
          ),
          Card(
            child: Column(
              children: [
                _Medicine(
                  title: 'Ранкові таблетки',
                  icon: Icons.wb_sunny_outlined,
                  iconColor: sunYellow,
                  value: store.morningMedicine,
                  onChanged: (value) {
                    final taken = value ?? false;
                    store.toggleMedicine(true, taken);
                    if (taken) {
                      NotificationService.instance.cancelToday(true);
                    }
                  },
                ),
                const Divider(height: 1),
                _Medicine(
                  title: 'Вечірні таблетки',
                  icon: Icons.nights_stay_outlined,
                  iconColor: purple,
                  value: store.eveningMedicine,
                  onChanged: (value) {
                    final taken = value ?? false;
                    store.toggleMedicine(false, taken);
                    if (taken) {
                      NotificationService.instance.cancelToday(false);
                    }
                  },
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
            ...tasks
                .take(3)
                .map(
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

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final message = store.assistantMessage;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => AssistantPage(store: store)),
      ),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1C3D33), Color(0xFF302253)],
          ),
          border: Border.all(color: const Color(0xFF3C4B47)),
        ),
        child: Row(
          children: [
            PixelBird(stage: store.game.birdStage, size: 78),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Синичка',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      const Icon(Icons.grain, color: sunYellow, size: 17),
                      Text(' ${store.game.seeds}'),
                      const SizedBox(width: 3),
                      IconButton(
                        tooltip: 'Світ синички',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => WorldPage(store: store),
                          ),
                        ),
                        icon: const Icon(
                          Icons.park_outlined,
                          color: green,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(message),
                    duration: const Duration(milliseconds: 1400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, _) {
                      final count = (message.length * value)
                          .ceil()
                          .clamp(0, message.length)
                          .toInt();
                      return Text(
                        message.substring(0, count),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.35,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Торкнись, щоб поговорити →',
                    style: TextStyle(color: green, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Medicine extends StatelessWidget {
  const _Medicine({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    secondary: Icon(icon, color: value ? iconColor : Colors.white38),
    title: Text(title),
    subtitle: Text(
      value ? 'Прийнято · +3 зернятка' : 'Ще не відмічено',
      style: TextStyle(color: value ? green : Colors.white38),
    ),
    value: value,
    onChanged: onChanged,
  );
}
