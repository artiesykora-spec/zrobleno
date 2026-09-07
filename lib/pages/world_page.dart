import 'package:flutter/material.dart';

import '../app_store.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/pixel_bird.dart';
import '../widgets/rpg_garden_view.dart';

class WorldPage extends StatefulWidget {
  const WorldPage({required this.store, super.key});

  final AppStore store;

  @override
  State<WorldPage> createState() => _WorldPageState();
}

class _WorldPageState extends State<WorldPage> {
  final _garden = RpgGardenController();
  bool _birdMoved = false;
  bool _feederFound = false;

  int _feederFrame() =>
      (((widget.store.game.nestLevel - 1).clamp(0, 4) * 3) / 4).round();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final store = widget.store;
      return Scaffold(
        appBar: AppBar(
          title: const Text('СТАРИЙ САД'),
          backgroundColor: gamePlum,
          foregroundColor: const Color(0xFFFFE58D),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: _HudPill(
                  icon: Icons.grain_rounded,
                  label: '${store.game.seeds}',
                  color: sunYellow,
                ),
              ),
            ),
          ],
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF304957), Color(0xFF17182B)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
            children: [
              _GardenScene(
                store: store,
                controller: _garden,
                feederLevel: _feederFrame(),
                birdMoved: _birdMoved,
                feederFound: _feederFound,
                onFirstMove: () => setState(() => _birdMoved = true),
                onFeederTap: () {
                  setState(() => _feederFound = true);
                  _garden.celebrate();
                },
                showMess: store.game.wolfMess,
                onMessSweep: () =>
                    SoundService.instance.play(AppSound.broomSweep),
                onMessCleaned: () {
                  store.cleanWolfMess();
                  _garden.celebrate();
                },
              ),
              const SizedBox(height: 15),
              _WorldStats(store: store),
              if (store.game.wolfMess) ...[
                const SizedBox(height: 14),
                const _KlaksaEncounter(),
              ],
              const SizedBox(height: 14),
              _ChapterMap(store: store),
              const SizedBox(height: 14),
              _UpgradeCard(
                icon: Icons.cottage_rounded,
                color: sunYellow,
                title: 'Годівничка · ${store.game.nestLevel}/5',
                text: store.game.nestLevel >= 5
                    ? 'Максимальний рівень: теплий дім Старого саду.'
                    : 'Нова видима деталь коштує ${store.nestUpgradeCost()} зерняток.',
                button: 'БУДУВАТИ',
                enabled:
                    store.game.nestLevel < 5 &&
                    store.game.seeds >= store.nestUpgradeCost(),
                onTap: store.upgradeNest,
              ),
              const SizedBox(height: 10),
              _UpgradeCard(
                icon: Icons.auto_awesome_rounded,
                color: gameMint,
                title: 'Магія саду · ${store.game.gardenLevel}/5',
                text: store.game.gardenLevel >= 5
                    ? 'Локація повністю пробуджена.'
                    : 'Пробудити наступний ефект за ${store.gardenUpgradeCost()} зерняток.',
                button: 'ПРОБУДИТИ',
                enabled:
                    store.game.gardenLevel < 5 &&
                    store.game.seeds >= store.gardenUpgradeCost(),
                onTap: () {
                  if (store.upgradeGarden()) _garden.celebrate();
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 17, 12, 0),
                child: Text(
                  'Пропущений день не обнуляє прогрес. Максимум — Клякса знову десь наслідить.',
                  style: TextStyle(color: Colors.white60, fontSize: 9.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _GardenScene extends StatelessWidget {
  const _GardenScene({
    required this.store,
    required this.controller,
    required this.feederLevel,
    required this.birdMoved,
    required this.feederFound,
    required this.onFirstMove,
    required this.onFeederTap,
    required this.showMess,
    required this.onMessSweep,
    required this.onMessCleaned,
  });

  final AppStore store;
  final RpgGardenController controller;
  final int feederLevel;
  final bool birdMoved;
  final bool feederFound;
  final VoidCallback onFirstMove;
  final VoidCallback onFeederTap;
  final bool showMess;
  final VoidCallback onMessSweep;
  final VoidCallback onMessCleaned;

  @override
  Widget build(BuildContext context) => Container(
    height: 500,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: gameInk, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x99000000), offset: Offset(0, 7)),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        RpgGardenView(
          feederLevel: feederLevel,
          controller: controller,
          onFirstMove: onFirstMove,
          onFeederTap: onFeederTap,
          showMess: showMess,
          onMessSweep: onMessSweep,
          onMessCleaned: onMessCleaned,
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Color(0x80112033), Colors.transparent],
              ),
            ),
          ),
        ),
        const Positioned(left: 12, top: 12, child: _LocationPlate()),
        Positioned(
          right: 11,
          top: 12,
          child: _HudPill(
            icon: Icons.auto_awesome_rounded,
            label: 'LVL ${store.game.birdStage + 1}',
            color: purple,
          ),
        ),
        Positioned(
          left: 12,
          top: 66,
          width: 196,
          child: _SpeechBubble(message: store.assistantMessage),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _SceneHint(
                key: ValueKey((birdMoved, feederFound)),
                text: feederFound
                    ? 'Годівничку перевірено. Тут усе гаразд.'
                    : showMess
                    ? 'Клякса наслідила під деревом. Натисни на какашку п\u2019ять разів, щоб прибрати її віником.'
                    : birdMoved
                    ? 'Тепер натисни на годівничку.'
                    : 'Торкнися гілки або галявини, щоб перемістити Синичку.',
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LocationPlate extends StatelessWidget {
  const _LocationPlate();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xE63D315D),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: sunYellow, width: 1.5),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ЛОКАЦІЯ 01',
          style: TextStyle(
            color: gameMint,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'СТАРИЙ САД',
          style: TextStyle(
            color: Color(0xFFFFE58D),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: gamePaper.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: gameInk, width: 1.5),
      boxShadow: const [
        BoxShadow(color: Color(0x55342B38), offset: Offset(2, 3)),
      ],
    ),
    child: Text(
      message,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: gameInk, fontSize: 9.5, height: 1.35),
    ),
  );
}

class _SceneHint extends StatelessWidget {
  const _SceneHint({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xDF332A4C),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: gameMint, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.touch_app_rounded, color: gameMint, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: gameInk, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: gameInk, size: 15),
        const SizedBox(width: 4),
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
  );
}

class _WorldStats extends StatelessWidget {
  const _WorldStats({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _WorldStat(
          icon: Icons.grain_rounded,
          value: '${store.game.seeds}',
          label: 'зерняток',
          color: sunYellow,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _WorldStat(
          icon: Icons.auto_awesome_rounded,
          value: '${store.game.xp}',
          label: 'досвіду',
          color: purple,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _WorldStat(
          icon: Icons.map_rounded,
          value: '1',
          label: 'локація',
          color: gameMint,
        ),
      ),
    ],
  );
}

class _WorldStat extends StatelessWidget {
  const _WorldStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 69,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: gameInk, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x77211B2B), offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: gameInk, size: 17),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: gameInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: gameInk,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _KlaksaEncounter extends StatelessWidget {
  const _KlaksaEncounter();

  @override
  Widget build(BuildContext context) => PaperPanel(
    color: const Color(0xFFE8D5B2),
    padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
    child: Row(
      children: [
        const PixelWolf(size: 102, squat: true),
        const SizedBox(width: 3),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'МІНІБОС: КЛЯКСА',
                style: TextStyle(
                  color: gameInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ми застали її на місці злочину: вона втекла, а какашка димиться під деревом. П\u2019ять разів натисни на неї \u2014 віник зробить решту.',
                style: TextStyle(
                  color: Color(0xFF746363),
                  fontSize: 9.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.cleaning_services_rounded, color: gamePlum, size: 32),
      ],
    ),
  );
}

class _ChapterMap extends StatelessWidget {
  const _ChapterMap({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final unlocked = 1 + store.game.birdStage;
    return PaperPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'МАПА ПРИГОДИ',
            style: TextStyle(
              color: gameInk,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Перший вертикальний зріз RPG. Наступні локації відкриються з розвитком Синички.',
            style: TextStyle(
              color: Color(0xFF766A69),
              fontSize: 9,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              final available = index < unlocked;
              final labels = ['Сад', 'Галявина', 'Озеро', 'Вежа'];
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: available ? gameMint : gamePaperShadow,
                        shape: BoxShape.circle,
                        border: Border.all(color: gameInk, width: 2),
                      ),
                      child: Icon(
                        available ? Icons.flag_rounded : Icons.lock_rounded,
                        color: gameInk,
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      labels[index],
                      style: const TextStyle(
                        color: gameInk,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    required this.button,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final String button;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PaperPanel(
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gameInk, width: 2),
          ),
          child: Icon(icon, color: gameInk),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: gameInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF766A69),
                  fontSize: 9,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 42),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(button, style: const TextStyle(fontSize: 7.5)),
        ),
      ],
    ),
  );
}
