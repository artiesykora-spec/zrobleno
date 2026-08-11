import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_store.dart';
import '../theme.dart';
import '../widgets/pixel_bird.dart';

class WorldPage extends StatelessWidget {
  const WorldPage({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: store,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('СВІТ СИНИЧКИ'),
            backgroundColor: gamePlum,
            foregroundColor: const Color(0xFFFFE58D),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF304957), Color(0xFF1A1A2C)],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
              children: [
                _WorldScene(store: store),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _WorldStat(
                        icon: Icons.grain_rounded,
                        text: '${store.game.seeds} зерняток',
                        color: sunYellow,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _WorldStat(
                        icon: Icons.auto_awesome_rounded,
                        text: 'Рівень ${store.game.birdStage + 1}',
                        color: purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _UpgradeCard(
                  icon: Icons.cottage_rounded,
                  color: sunYellow,
                  title: 'Годівничка · ${store.game.nestLevel}/5',
                  text: store.game.nestLevel >= 5
                      ? 'Вона вже максимально затишна й чарівна.'
                      : 'Наступна деталь коштує ${store.nestUpgradeCost()} зерняток.',
                  enabled: store.game.nestLevel < 5 &&
                      store.game.seeds >= store.nestUpgradeCost(),
                  onTap: store.upgradeNest,
                ),
                const SizedBox(height: 10),
                _UpgradeCard(
                  icon: Icons.local_florist_rounded,
                  color: gameMint,
                  title: 'Садочок · ${store.game.gardenLevel}/5',
                  text: store.game.gardenLevel >= 5
                      ? 'Садочок розквітнув повністю.'
                      : 'Посадити квітку за ${store.gardenUpgradeCost()} зерняток.',
                  enabled: store.game.gardenLevel < 5 &&
                      store.game.seeds >= store.gardenUpgradeCost(),
                  onTap: store.upgradeGarden,
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 16, 12, 0),
                  child: Text(
                    'Тут немає покарань: Клякса лише інколи прибігає пожартувати. Увесь прогрес зберігається.',
                    style: TextStyle(color: Colors.white60, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _WorldStat extends StatelessWidget {
  const _WorldStat({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: gameInk, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x77211B2B), offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: gameInk, size: 19),
            const SizedBox(width: 7),
            Text(
              text,
              style: const TextStyle(
                color: gameInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _WorldScene extends StatefulWidget {
  const _WorldScene({required this.store});

  final AppStore store;

  @override
  State<_WorldScene> createState() => _WorldSceneState();
}

class _WorldSceneState extends State<_WorldScene>
    with TickerProviderStateMixin {
  late final AnimationController ambience;
  late final AnimationController wolf;
  late final AnimationController celebration;
  late bool lastMess;
  late int lastNestLevel;
  late int lastGardenLevel;

  @override
  void initState() {
    super.initState();
    ambience = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    wolf = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4700),
    );
    celebration = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    lastMess = widget.store.game.wolfMess;
    lastNestLevel = widget.store.game.nestLevel;
    lastGardenLevel = widget.store.game.gardenLevel;
    if (lastMess) wolf.forward();
  }

  @override
  void didUpdateWidget(covariant _WorldScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasMess = widget.store.game.wolfMess;
    if (hasMess && !lastMess) {
      wolf
        ..reset()
        ..forward();
    } else if (!hasMess && lastMess) {
      wolf.reset();
    }
    if (widget.store.game.nestLevel != lastNestLevel ||
        widget.store.game.gardenLevel != lastGardenLevel) {
      celebration
        ..reset()
        ..forward();
      lastNestLevel = widget.store.game.nestLevel;
      lastGardenLevel = widget.store.game.gardenLevel;
    }
    lastMess = hasMess;
  }

  @override
  void dispose() {
    ambience.dispose();
    wolf.dispose();
    celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 450,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF171323), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), offset: Offset(0, 7)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: Listenable.merge([ambience, wolf, celebration]),
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final breeze = math.sin(ambience.value * math.pi * 2);
              final party = celebration.value;
              final birdJump =
                  party == 0 ? breeze * 3 : -math.sin(party * math.pi) * 52;
              final birdTurn = party == 0
                  ? 0.0
                  : Curves.easeInOut.transform((party / .72).clamp(0, 1)) *
                      math.pi *
                      2;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: 1.02,
                    child: Transform.translate(
                      offset: Offset(breeze * 1.5, 0),
                      child: Image.asset(
                        'assets/game/world-background.png',
                        fit: BoxFit.cover,
                        alignment: const Alignment(.15, .1),
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x11000000),
                          Colors.transparent,
                          Color(0x44000000),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _WorldDetailsPainter(
                      progress: ambience.value,
                      gardenLevel: widget.store.game.gardenLevel,
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    width: math.min(width * .72, 255.0),
                    child:
                        _SpeechBubble(message: widget.store.assistantMessage),
                  ),
                  Positioned(
                    right: -7,
                    top: 171,
                    child: PixelFeeder(
                      level: widget.store.game.nestLevel,
                      size: 192,
                    ),
                  ),
                  Positioned(
                    left: 24,
                    top: 185 + birdJump,
                    child: Transform.rotate(
                      angle: birdTurn,
                      child: PixelBird(
                        stage: widget.store.game.birdStage,
                        size: 150,
                        playful: true,
                      ),
                    ),
                  ),
                  if (party > 0)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _CelebrationPainter(progress: party),
                      ),
                    ),
                  if (widget.store.game.wolfMess) _buildWolf(width),
                  if (widget.store.game.wolfMess && wolf.value >= .53)
                    Positioned(
                      left: width * .48,
                      bottom: 22,
                      child: Semantics(
                        button: true,
                        label: 'Прибрати жарт Клякси',
                        child: GestureDetector(
                          onTap: widget.store.cleanWolfMess,
                          child: const _PixelMess(),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 10,
                    bottom: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC3D315D),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: sunYellow),
                      ),
                      child: Text(
                        party > 0 ? 'УРА! НОВА НАГОРОДА!' : 'живий світ',
                        style: const TextStyle(
                          color: Color(0xFFFFE58D),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

  Widget _buildWolf(double width) {
    final value = wolf.value;
    final double x;
    final bool squat;
    if (value < .44) {
      x = -120 + (width * .55 + 120) * Curves.easeOut.transform(value / .44);
      squat = false;
    } else if (value < .7) {
      x = width * .55;
      squat = value > .51;
    } else {
      x = width * .55 +
          (width + 135 - width * .55) *
              Curves.easeIn.transform((value - .7) / .3);
      squat = false;
    }
    return Positioned(
      left: x,
      bottom: 2 + math.sin(value * math.pi * 16).abs() * (squat ? 0 : 6),
      child: PixelWolf(size: 116, squat: squat),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: gamePaper.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gameInk, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x55342B38), offset: Offset(2, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: gameInk,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      );
}

class _WorldDetailsPainter extends CustomPainter {
  const _WorldDetailsPainter({
    required this.progress,
    required this.gardenLevel,
  });

  final double progress;
  final int gardenLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final pixel = math.max(2.0, size.width / 180);
    final sway = math.sin(progress * math.pi * 2) * pixel;

    void block(Color color, double x, double y, double w, double h) {
      canvas.drawRect(
        Rect.fromLTWH(x, y, w, h),
        Paint()
          ..color = color
          ..isAntiAlias = false,
      );
    }

    final flowerColors = [
      sunYellow,
      gameCoral,
      purple,
      gameMint,
      const Color(0xFFFFE9F2),
    ];
    for (var index = 0; index < gardenLevel; index++) {
      final x = size.width * (.10 + index * .075);
      final base = size.height * .86;
      block(const Color(0xFF2D7C4C), x, base - 24, pixel * 1.5, 25);
      block(
        flowerColors[index % flowerColors.length],
        x - pixel * 1.5 + sway * (index.isEven ? 1 : -1),
        base - 31 - index % 2 * 5,
        pixel * 4.5,
        pixel * 4.5,
      );
      block(
        const Color(0xFFF8C947),
        x + sway * (index.isEven ? 1 : -1),
        base - 29 - index % 2 * 5,
        pixel * 1.5,
        pixel * 1.5,
      );
    }

    final firefly = Paint();
    for (var i = 0; i < 9; i++) {
      final phase = progress * math.pi * 2 + i * .83;
      final x = size.width * (.08 + (i * .113) % .84) + math.sin(phase) * 7;
      final y = size.height * (.26 + (i * .17) % .57) + math.cos(phase) * 6;
      final opacity = (.25 + (math.sin(phase) + 1) * .34).clamp(0.0, 1.0);
      firefly.color = sunYellow.withValues(alpha: opacity.toDouble());
      canvas.drawRect(Rect.fromLTWH(x, y, pixel * 1.5, pixel * 1.5), firefly);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldDetailsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.gardenLevel != gardenLevel;
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    const colors = [sunYellow, gameCoral, gameMint, purple, Colors.white];
    for (var i = 0; i < 24; i++) {
      final startX = random.nextDouble() * size.width;
      final speed = .65 + random.nextDouble() * .9;
      final y = -20 + progress * size.height * speed;
      final x = startX + math.sin(progress * 9 + i) * 15;
      final side = 3.0 + random.nextInt(5);
      canvas.drawRect(
        Rect.fromLTWH(x, y, side, side * 1.6),
        Paint()
          ..color = colors[i % colors.length]
          ..isAntiAlias = false,
      );
    }

    final burst = (1 - (progress - .36).abs() / .34).clamp(0.0, 1.0);
    if (burst <= 0) return;
    final center = Offset(size.width * .68, size.height * .18);
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi * 2 / 12;
      final inner = 18 + burst * 8;
      final outer = 28 + burst * 31;
      paint.color = colors[i % colors.length].withValues(alpha: burst);
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PixelMess extends StatelessWidget {
  const _PixelMess();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 34,
            child: CustomPaint(painter: _MessPainter()),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xDD3D315D),
              borderRadius: BorderRadius.all(Radius.circular(7)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Text(
                'ПРИБРАТИ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
}

class _MessPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()
      ..color = const Color(0xFF3A2418)
      ..isAntiAlias = false;
    final light = Paint()
      ..color = const Color(0xFF765039)
      ..isAntiAlias = false;
    canvas.drawRect(const Rect.fromLTWH(8, 22, 32, 8), dark);
    canvas.drawRect(const Rect.fromLTWH(13, 14, 24, 10), dark);
    canvas.drawRect(const Rect.fromLTWH(19, 7, 15, 9), dark);
    canvas.drawRect(const Rect.fromLTWH(21, 9, 8, 4), light);
    canvas.drawRect(const Rect.fromLTWH(15, 17, 10, 4), light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PaperPanel(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                      fontSize: 10,
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
                minimumSize: const Size(44, 42),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text('ДОДАТИ', style: TextStyle(fontSize: 9)),
            ),
          ],
        ),
      );
}
