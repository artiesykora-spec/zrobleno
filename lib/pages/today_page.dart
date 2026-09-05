import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_store.dart';
import '../models.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/pixel_bird.dart';
import '../widgets/rpg_garden_view.dart';
import 'assistant_page.dart';
import 'settings_page.dart';
import 'world_page.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({required this.store, super.key});

  final AppStore store;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _klaksa;
  final _garden = RpgGardenController();
  bool _klaksaRunning = false;

  static const dailyQuests = <_DailyQuest>[
    _DailyQuest(
      id: 'focus',
      title: '25 хвилин спокійного фокусу',
      note: 'Головний крок дня',
      icon: Icons.bolt_rounded,
      color: sunYellow,
      seeds: 3,
    ),
    _DailyQuest(
      id: 'water',
      title: 'Випити склянку води',
      note: 'Маленьке відновлення',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF79C9DF),
    ),
    _DailyQuest(
      id: 'food_log',
      title: 'Записати прийом їжі',
      note: 'Щоденник без здогадок',
      icon: Icons.restaurant_rounded,
      color: orange,
    ),
    _DailyQuest(
      id: 'money',
      title: 'Перевірити витрати дня',
      note: 'Один погляд на гаманець',
      icon: Icons.savings_rounded,
      color: gameMint,
    ),
    _DailyQuest(
      id: 'move',
      title: '5 хвилин руху або повітря',
      note: 'У своєму комфортному темпі',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF91C96C),
    ),
    _DailyQuest(
      id: 'tidy',
      title: 'Навести лад в одному місці',
      note: 'Достатньо зовсім маленької зони',
      icon: Icons.cleaning_services_rounded,
      color: purple,
    ),
    _DailyQuest(
      id: 'pause',
      title: 'Коротка перерва без екрана',
      note: 'Перепочинок теж частина пригоди',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF9CB9E8),
    ),
    _DailyQuest(
      id: 'connection',
      title: 'Написати важливій людині',
      note: 'Одне тепле повідомлення',
      icon: Icons.favorite_rounded,
      color: gameCoral,
    ),
    _DailyQuest(
      id: 'tomorrow',
      title: 'Підготувати одну річ на завтра',
      note: 'Щоб ранок був легшим',
      icon: Icons.backpack_rounded,
      color: Color(0xFFE3A967),
    ),
    _DailyQuest(
      id: 'reflection',
      title: 'Занотувати одну перемогу дня',
      note: 'Навіть найменшу',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFB58CE0),
      seeds: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _klaksa = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void dispose() {
    _klaksa.dispose();
    super.dispose();
  }

  Future<void> _startKlaksaRaid() async {
    if (_klaksaRunning) return;
    setState(() => _klaksaRunning = true);
    await _klaksa.forward(from: 0);
    if (!mounted) return;
    _klaksa.reset();
    setState(() => _klaksaRunning = false);
  }

  int _feederFrame(AppStore store) =>
      (((store.game.nestLevel - 1).clamp(0, 4) * 3) / 4).round();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.store, _klaksa]),
    builder: (context, _) {
      final store = widget.store;
      final customTasks = store.tasks
          .where(
            (task) => task.deadline == null || store.isToday(task.deadline!),
          )
          .take(8)
          .toList(growable: false);
      final completed =
          (store.morningMedicine ? 1 : 0) +
          (store.eveningMedicine ? 1 : 0) +
          dailyQuests
              .where((quest) => store.isDailyQuestDone(quest.id))
              .length +
          customTasks.where((task) => task.done).length;
      final total = 2 + dailyQuests.length + customTasks.length;
      final progress = total == 0 ? 0.0 : completed / total;

      return ListView(
        key: const PageStorageKey('rpg-today-scroll'),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 30),
        children: [
          _PageHeading(store: store),
          const SizedBox(height: 12),
          _WorldHero(
            store: store,
            garden: _garden,
            feederLevel: _feederFrame(store),
            klaksaProgress: _klaksa.value,
            showKlaksa: _klaksaRunning,
            onWorld: () => _openWorld(context),
          ),
          const SizedBox(height: 14),
          _CampaignProgress(
            completed: completed,
            total: total,
            progress: progress,
            seeds: store.game.seeds,
            level: store.game.birdStage + 1,
          ),
          if (store.game.wolfMess) ...[
            const SizedBox(height: 14),
            _KlaksaAlert(onTap: () => _openWorld(context)),
          ],
          const SizedBox(height: 16),
          _QuestChapter(
            eyebrow: 'ГОЛОВНА ЛІНІЯ',
            title: 'РИТУАЛИ СТАРОГО САДУ',
            subtitle: 'Розбуди сад і не дай Кляксі все переплутати.',
            accent: sunYellow,
            children: [
              _QuestRow(
                title: 'Випити ранкові таблетки',
                note: _time(
                  store.reminders.morningHour,
                  store.reminders.morningMinute,
                ),
                reward: 3,
                done: store.morningMedicine,
                completedIcon: Icons.medication_rounded,
                color: sunYellow,
                onTap: () => _toggleMedicine(true),
              ),
              _QuestRow(
                title: 'Випити вечірні таблетки',
                note: _time(
                  store.reminders.eveningHour,
                  store.reminders.eveningMinute,
                ),
                reward: 3,
                done: store.eveningMedicine,
                completedIcon: Icons.medication_rounded,
                color: purple,
                onTap: () => _toggleMedicine(false),
              ),
              ...dailyQuests.take(4).map(_dailyQuestRow),
            ],
          ),
          const SizedBox(height: 14),
          _QuestChapter(
            eyebrow: 'ПОБІЧНІ КВЕСТИ',
            title: 'ЕКСПЕДИЦІЯ НА СЬОГОДНІ',
            subtitle:
                'Не обов’язково робити все одразу. Кожен крок дає досвід.',
            accent: gameMint,
            children: [
              ...dailyQuests.skip(4).map(_dailyQuestRow),
              ...customTasks.map(_customTaskRow),
            ],
          ),
          const SizedBox(height: 14),
          _DailyChest(
            ready: completed == total,
            claimed: store.dailyChestClaimed,
            completed: completed,
            total: total,
            onClaim: () {
              store.claimDailyChest();
              _garden.celebrate();
            },
          ),
          const SizedBox(height: 16),
          _DailyNumbers(store: store),
        ],
      );
    },
  );

  _QuestRow _dailyQuestRow(_DailyQuest quest) {
    final done = widget.store.isDailyQuestDone(quest.id);
    return _QuestRow(
      title: quest.title,
      note: quest.note,
      reward: quest.seeds,
      done: done,
      completedIcon: quest.icon,
      color: quest.color,
      onTap: () {
        widget.store.toggleDailyQuest(
          quest.id,
          !done,
          seeds: quest.seeds,
          xp: quest.seeds + 2,
        );
        if (!done) _garden.celebrate();
      },
    );
  }

  _QuestRow _customTaskRow(TodoItem task) => _QuestRow(
    title: task.title,
    note: '${task.category} · твій квест',
    reward: 2,
    done: task.done,
    completedIcon: Icons.star_rounded,
    color: gameCoral,
    onTap: () {
      widget.store.toggleTask(task, !task.done);
      if (task.done) _garden.celebrate();
    },
  );

  void _toggleMedicine(bool morning) {
    final store = widget.store;
    final wasTaken = morning ? store.morningMedicine : store.eveningMedicine;
    store.toggleMedicine(morning, !wasTaken);
    if (!wasTaken) {
      NotificationService.instance.cancelToday(morning);
      _garden.celebrate();
      if (!store.game.wolfMess) store.triggerKlaksa();
      _startKlaksaRaid();
    }
  }

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  void _openWorld(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => WorldPage(store: widget.store)),
  );
}

class _DailyQuest {
  const _DailyQuest({
    required this.id,
    required this.title,
    required this.note,
    required this.icon,
    required this.color,
    this.seeds = 2,
  });

  final String id;
  final String title;
  final String note;
  final IconData icon;
  final Color color;
  final int seeds;
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
      const _ActBadge(),
      const SizedBox(width: 6),
      IconButton.filledTonal(
        tooltip: 'Налаштування',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => SettingsPage(store: store)),
        ),
        icon: const Icon(Icons.settings_rounded),
      ),
    ],
  );
}

class _ActBadge extends StatelessWidget {
  const _ActBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: gameCoral,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: gameInk, width: 1.5),
    ),
    child: const Text(
      'АКТ I',
      style: TextStyle(
        color: gameInk,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _WorldHero extends StatelessWidget {
  const _WorldHero({
    required this.store,
    required this.garden,
    required this.feederLevel,
    required this.klaksaProgress,
    required this.showKlaksa,
    required this.onWorld,
  });

  final AppStore store;
  final RpgGardenController garden;
  final int feederLevel;
  final double klaksaProgress;
  final bool showKlaksa;
  final VoidCallback onWorld;

  @override
  Widget build(BuildContext context) => Container(
    height: 248,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: gameInk, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x99000000), offset: Offset(0, 7)),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          RpgGardenView(
            compact: true,
            feederLevel: feederLevel,
            controller: garden,
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x8D142139), Colors.transparent],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 12,
            top: 10,
            child: Text(
              'СТАРИЙ САД',
              style: TextStyle(
                color: Color(0xFFFFE58D),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: gameInk, offset: Offset(2, 3))],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 9,
            child: _SeedBadge(value: store.game.seeds),
          ),
          Positioned(
            left: 12,
            top: 58,
            width: 166,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: gamePaper.withValues(alpha: .93),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gameInk, width: 1.5),
              ),
              child: Text(
                store.assistantMessage,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: gameInk,
                  fontSize: 9.5,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (showKlaksa)
            Positioned(
              left: lerpDouble(
                -92,
                constraints.maxWidth + 16,
                Curves.easeInOutCubic.transform(klaksaProgress),
              ),
              bottom: 5 + (klaksaProgress * 8 % 1 < .5 ? 0 : 7),
              child: const PixelWolf(size: 88),
            ),
          Positioned(
            left: 12,
            bottom: 11,
            child: Row(
              children: [
                _HeroButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'ПОМІЧНИЦЯ',
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
                  icon: Icons.sports_esports_rounded,
                  label: 'У СВІТ',
                  color: sunYellow,
                  onTap: onWorld,
                ),
              ],
            ),
          ),
        ],
      ),
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
                fontSize: 9,
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
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _CampaignProgress extends StatelessWidget {
  const _CampaignProgress({
    required this.completed,
    required this.total,
    required this.progress,
    required this.seeds,
    required this.level,
  });

  final int completed;
  final int total;
  final double progress;
  final int seeds;
  final int level;

  @override
  Widget build(BuildContext context) => PaperPanel(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'СЬОГОДНІШНІЙ ПОХІД',
                style: TextStyle(
                  color: gameInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _MiniStat(label: 'LVL $level', color: purple),
            const SizedBox(width: 5),
            _MiniStat(label: '$seeds ЗЕРЕН', color: sunYellow),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 13,
            backgroundColor: gamePaperShadow,
            valueColor: const AlwaysStoppedAnimation(gameCoral),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '$completed із $total квестів · ${(progress * 100).round()}%',
          style: const TextStyle(
            color: Color(0xFF746668),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: gameInk, width: 1.5),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: gameInk,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _QuestChapter extends StatelessWidget {
  const _QuestChapter({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.children,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => PaperPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: gameInk, width: 1.3),
          ),
          child: Text(
            eyebrow,
            style: const TextStyle(
              color: gameInk,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(
            color: gameInk,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF786B68),
            fontSize: 9.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.title,
    required this.note,
    required this.reward,
    required this.done,
    required this.completedIcon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String note;
  final int reward;
  final bool done;
  final IconData completedIcon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: done,
    button: true,
    label: title,
    child: InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 330),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut,
                ),
                child: child,
              ),
              child: Container(
                key: ValueKey(done),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: done ? color : const Color(0xFFFBF5E7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: gameInk, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x44342B38), offset: Offset(1, 2)),
                  ],
                ),
                child: done
                    ? Icon(completedIcon, color: gameInk, size: 22)
                    : const Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: Color(0xFFBBAE98),
                        size: 15,
                      ),
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done ? 'Виконано · $note' : note,
                    style: const TextStyle(
                      color: Color(0xFF7B6B69),
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: done ? color : gamePaperShadow,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grain_rounded, color: gameInk, size: 13),
                  const SizedBox(width: 2),
                  Text(
                    '+$reward',
                    style: const TextStyle(
                      color: gameInk,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _KlaksaAlert extends StatelessWidget {
  const _KlaksaAlert({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PaperPanel(
    color: const Color(0xFFEAD9BB),
    padding: const EdgeInsets.fromLTRB(10, 3, 12, 3),
    onTap: onTap,
    child: Row(
      children: [
        const PixelWolf(size: 80, surprised: true),
        const SizedBox(width: 2),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ЗАСІДКА КЛЯКСИ!',
                style: TextStyle(color: gameInk, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                'Вона втекла у Старий сад. Зайди у світ і прибери її жарт.',
                style: TextStyle(
                  color: Color(0xFF746363),
                  fontSize: 9.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.sports_esports_rounded, color: gameInk),
      ],
    ),
  );
}

class _DailyChest extends StatelessWidget {
  const _DailyChest({
    required this.ready,
    required this.claimed,
    required this.completed,
    required this.total,
    required this.onClaim,
  });

  final bool ready;
  final bool claimed;
  final int completed;
  final int total;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF66539A), Color(0xFF3E315E)],
      ),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: gameInk, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x88000000), offset: Offset(0, 5)),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: claimed ? gameMint : sunYellow,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: gameInk, width: 2),
          ),
          child: Icon(
            claimed ? Icons.check_rounded : Icons.inventory_2_rounded,
            color: gameInk,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                claimed ? 'СКАРБ ОТРИМАНО' : 'СКАРБ ДНЯ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                claimed
                    ? '+10 зерен · +18 досвіду'
                    : ready
                    ? 'Усі квести виконано — відкривай!'
                    : 'Ще ${total - completed} квестів до нагороди',
                style: const TextStyle(color: Colors.white70, fontSize: 9.5),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: ready && !claimed ? onClaim : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(74, 42),
            padding: const EdgeInsets.symmetric(horizontal: 9),
          ),
          child: Text(
            claimed ? 'ГОТОВО' : 'ВІДКРИТИ',
            style: const TextStyle(fontSize: 8),
          ),
        ),
      ],
    ),
  );
}

class _DailyNumbers extends StatelessWidget {
  const _DailyNumbers({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final expenses = store.expenses
        .where((expense) => store.isToday(expense.date))
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            icon: Icons.local_fire_department_rounded,
            value: '${store.todayCalories.round()}',
            label: 'ккал сьогодні',
            color: const Color(0xFF80A9D7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricCard(
            icon: Icons.savings_rounded,
            value: '${expenses.toStringAsFixed(0)} ₴',
            label: 'витрати сьогодні',
            color: orange,
          ),
        ),
      ],
    );
  }
}
