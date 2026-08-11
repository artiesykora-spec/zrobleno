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
          final calories = store.todayCalories;
          final medicineCount = [
            store.morningMedicine,
            store.eveningMedicine,
          ].where((taken) => taken).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            children: [
              _PageHeading(store: store),
              const SizedBox(height: 12),
              _WorldHero(store: store),
              const SizedBox(height: 14),
              _QuickStats(
                seeds: store.game.seeds,
                level: store.game.birdStage + 1,
                tasks: tasks.length,
              ),
              const SizedBox(height: 16),
              PaperPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: gameCoral),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ЩОДЕННІ ПРИГОДИ',
                            style: TextStyle(
                              color: gameInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_time(store.reminders.morningHour, store.reminders.morningMinute)} ранкові · '
                      '${_time(store.reminders.eveningHour, store.reminders.eveningMinute)} вечірні',
                      style: const TextStyle(
                        color: Color(0xFF766A69),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _QuestRow(
                      title: 'Випити ранкові таблетки',
                      reward: '+3 зернятка',
                      done: store.morningMedicine,
                      completedIcon: Icons.medication_rounded,
                      color: sunYellow,
                      onTap: () {
                        final taken = !store.morningMedicine;
                        store.toggleMedicine(true, taken);
                        if (taken) {
                          NotificationService.instance.cancelToday(true);
                        }
                      },
                    ),
                    _QuestRow(
                      title: 'Випити вечірні таблетки',
                      reward: '+3 зернятка',
                      done: store.eveningMedicine,
                      completedIcon: Icons.medication_rounded,
                      color: purple,
                      onTap: () {
                        final taken = !store.eveningMedicine;
                        store.toggleMedicine(false, taken);
                        if (taken) {
                          NotificationService.instance.cancelToday(false);
                        }
                      },
                    ),
                    ...tasks.take(3).map(
                          (task) => _QuestRow(
                            title: task.title,
                            reward: '${task.category} · +2 зернятка',
                            done: task.done,
                            completedIcon: Icons.star_rounded,
                            color: gameMint,
                            onTap: () => store.toggleTask(task, !task.done),
                          ),
                        ),
                    if (tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          children: [
                            Icon(Icons.celebration_rounded, color: gameMint),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Справи на сьогодні виконані. Синичка пишається!',
                                style: TextStyle(
                                  color: gameInk,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (store.game.wolfMess) ...[
                const SizedBox(height: 14),
                _KlaksaAlert(
                  onTap: () => _openWorld(context),
                ),
              ],
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  MetricCard(
                    icon: Icons.task_alt_rounded,
                    value: '${tasks.length}',
                    label: 'активних справ',
                    color: gameMint,
                  ),
                  MetricCard(
                    icon: Icons.savings_rounded,
                    value: '${expenses.toStringAsFixed(0)} ₴',
                    label: 'витрачено сьогодні',
                    color: orange,
                  ),
                  MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    value: '${calories.round()}',
                    label: 'ккал із ${store.dailyCalorieGoal}',
                    color: const Color(0xFF80A9D7),
                  ),
                  MetricCard(
                    icon: Icons.medication_rounded,
                    value: '$medicineCount/2',
                    label: 'приймання ліків',
                    color: sunYellow,
                  ),
                ],
              ),
            ],
          );
        },
      );

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  void _openWorld(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => WorldPage(store: store)),
      );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ZROBLENO',
                  style: TextStyle(
                    color: sunYellow,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(color: Color(0xFF171323), offset: Offset(2, 3)),
                    ],
                  ),
                ),
                Text(
                  DateFormat('EEEE, d MMMM', 'uk').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Налаштування',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(store: store),
              ),
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      );
}

class _WorldHero extends StatelessWidget {
  const _WorldHero({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) => Container(
        height: 222,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF171323), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x88000000), offset: Offset(0, 6)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/game/world-background.png',
              fit: BoxFit.cover,
              alignment: const Alignment(.05, .1),
              filterQuality: FilterQuality.none,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xDB20253A), Color(0x30161B25)],
                  stops: [.0, .72],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 13,
              child: Text(
                'СВІТ СИНИЧКИ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFFFE58D),
                  shadows: const [
                    Shadow(
                      color: Color(0xFF171323),
                      offset: Offset(2, 3),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _SeedBadge(value: store.game.seeds),
            ),
            Positioned(
              right: 5,
              bottom: 2,
              child: PixelBird(
                stage: store.game.birdStage,
                size: 145,
                playful: true,
              ),
            ),
            Positioned(
              left: 12,
              top: 55,
              width: 220,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gamePaper.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: gameInk, width: 2),
                ),
                child: Text(
                  store.assistantMessage,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: gameInk,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
                children: [
                  _HeroButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Поговорити',
                    color: gameMint,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AssistantPage(store: store),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  _HeroButton(
                    icon: Icons.park_rounded,
                    label: 'У світ',
                    color: sunYellow,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => WorldPage(store: store),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: gameInk, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Row(
              children: [
                Icon(icon, color: gameInk, size: 15),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: gameInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SeedBadge extends StatelessWidget {
  const _SeedBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xDD332A4C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sunYellow, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grain_rounded, color: sunYellow, size: 16),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.seeds,
    required this.level,
    required this.tasks,
  });

  final int seeds;
  final int level;
  final int tasks;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.auto_awesome_rounded,
              label: 'Рівень $level',
              color: purple,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _StatChip(
              icon: Icons.grain_rounded,
              label: '$seeds зерен',
              color: sunYellow,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _StatChip(
              icon: Icons.flag_rounded,
              label: '$tasks справ',
              color: gameCoral,
            ),
          ),
        ],
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gameInk, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x66211B2B), offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: gameInk, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  color: gameInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.title,
    required this.reward,
    required this.done,
    required this.completedIcon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String reward;
  final bool done;
  final IconData completedIcon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.elasticOut,
                  ),
                  child: child,
                ),
                child: Container(
                  key: ValueKey(done),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: done ? color : const Color(0xFFF9F3E5),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: gameInk, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44342B38),
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                  child: done
                      ? Icon(completedIcon, color: gameInk, size: 21)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: gameInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      done ? 'Виконано · $reward' : reward,
                      style: const TextStyle(
                        color: Color(0xFF7B6B69),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                done ? Icons.auto_awesome_rounded : Icons.add_rounded,
                color: done ? gameCoral : const Color(0xFF8A7A74),
                size: 20,
              ),
            ],
          ),
        ),
      );
}

class _KlaksaAlert extends StatelessWidget {
  const _KlaksaAlert({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PaperPanel(
        color: const Color(0xFFE8D9BC),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        onTap: onTap,
        child: Row(
          children: [
            const PixelWolf(size: 82, surprised: true),
            const SizedBox(width: 4),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ОЙ! КЛЯКСА ПРИБІГЛА',
                    style: TextStyle(
                      color: gameInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'У світі лишився її маленький жарт. Торкнись, щоб прибрати.',
                    style: TextStyle(
                      color: Color(0xFF746363),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: gameInk),
          ],
        ),
      );
}
