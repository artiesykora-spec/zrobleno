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
        title: const Text('Світ синички'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _WorldScene(store: store),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.grain, color: sunYellow),
              const SizedBox(width: 8),
              Text(
                '${store.game.seeds} зерняток',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Синичка · рівень ${store.game.birdStage + 1}',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _UpgradeCard(
            icon: Icons.home_outlined,
            color: purple,
            title: 'Гніздечко · рівень ${store.game.nestLevel}',
            text: store.game.nestLevel >= 5
                ? 'Гніздечко вже максимально затишне.'
                : 'Додати нову деталь за ${store.nestUpgradeCost()} зерняток',
            enabled:
                store.game.nestLevel < 5 &&
                store.game.seeds >= store.nestUpgradeCost(),
            onTap: store.upgradeNest,
          ),
          _UpgradeCard(
            icon: Icons.local_florist_outlined,
            color: green,
            title: 'Садочок · рівень ${store.game.gardenLevel}',
            text: store.game.gardenLevel >= 5
                ? 'Садочок розквітнув повністю.'
                : 'Посадити щось за ${store.gardenUpgradeCost()} зерняток',
            enabled:
                store.game.gardenLevel < 5 &&
                store.game.seeds >= store.gardenUpgradeCost(),
            onTap: store.upgradeGarden,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Прогрес не зникає. Клякса — лише маленький жарт після пропущеного дня.',
              style: TextStyle(color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
  late bool lastMess;

  @override
  void initState() {
    super.initState();
    ambience = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    wolf = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    lastMess = widget.store.game.wolfMess;
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
    lastMess = hasMess;
  }

  @override
  void dispose() {
    ambience.dispose();
    wolf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 430,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF3A4D46), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: AnimatedBuilder(
      animation: Listenable.merge([ambience, wolf]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final breeze = math.sin(ambience.value * math.pi * 2);
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1.018,
                child: Transform.translate(
                  offset: Offset(breeze * 1.5, 0),
                  child: Image.asset(
                    'assets/game/world-background.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .04),
                      Colors.transparent,
                      Colors.black.withValues(alpha: .18),
                    ],
                  ),
                ),
              ),
              CustomPaint(
                painter: _WorldDetailsPainter(
                  progress: ambience.value,
                  nestLevel: widget.store.game.nestLevel,
                  gardenLevel: widget.store.game.gardenLevel,
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                width: math.min(width * .66, 238.0),
                child: _SpeechBubble(message: widget.store.assistantMessage),
              ),
              Positioned(
                right: 18,
                top: 121 + breeze * 3.5,
                child: PixelBird(
                  stage: widget.store.game.birdStage,
                  size: 142,
                  playful: true,
                ),
              ),
              if (widget.store.game.wolfMess) _buildWolf(width),
              if (widget.store.game.wolfMess && wolf.value >= .56)
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
                left: 12,
                bottom: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xC5141A18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x553EE4A1)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      'живий pixel-art світ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFD7FFE8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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
    if (value < .48) {
      x = -130 + (width * .60 + 130) * Curves.easeOut.transform(value / .48);
      squat = false;
    } else if (value < .71) {
      x = width * .60;
      squat = value > .54;
    } else {
      x =
          width * .60 +
          (width + 145 - width * .60) *
              Curves.easeIn.transform((value - .71) / .29);
      squat = false;
    }
    return Positioned(
      left: x,
      bottom: 12 + math.sin(value * math.pi * 16).abs() * (squat ? 0 : 5),
      child: PixelWolf(size: 125, squat: squat),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xE9161B20),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0x995CCBA2)),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10)],
    ),
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Text(
        message,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFFF0FFF7),
          fontSize: 12,
          height: 1.32,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _WorldDetailsPainter extends CustomPainter {
  const _WorldDetailsPainter({
    required this.progress,
    required this.nestLevel,
    required this.gardenLevel,
  });

  final double progress;
  final int nestLevel;
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

    final nestX = size.width * .72;
    final nestY = size.height * .47;
    for (var row = 0; row < 4 + nestLevel; row++) {
      final inset = row * pixel * .65;
      block(
        row.isEven ? const Color(0xFF6D4325) : const Color(0xFF9A6835),
        nestX + inset,
        nestY + row * pixel * 1.35,
        size.width * .23 - inset * 2,
        pixel * 1.6,
      );
    }
    if (nestLevel >= 2) {
      block(
        const Color(0xFFF1D78B),
        nestX + size.width * .06,
        nestY + pixel * 4,
        pixel * 4,
        pixel * 3,
      );
    }
    if (nestLevel >= 4) {
      block(
        const Color(0xFF8F70D8),
        nestX + size.width * .11,
        nestY + pixel * 3,
        pixel * 5,
        pixel * 2,
      );
    }

    final flowerColors = [
      const Color(0xFFFFD45C),
      const Color(0xFFFF8D7A),
      const Color(0xFF9B78FF),
      const Color(0xFF65E7A8),
      const Color(0xFFFFE9F2),
    ];
    for (var index = 0; index < gardenLevel; index++) {
      final x = size.width * (.10 + index * .075);
      final base = size.height * .82;
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

    final firefly = Paint()..color = const Color(0xFFFFE992);
    for (var i = 0; i < 9; i++) {
      final phase = progress * math.pi * 2 + i * .83;
      final x = size.width * (.08 + (i * .113) % .84) + math.sin(phase) * 7;
      final y = size.height * (.26 + (i * .17) % .57) + math.cos(phase) * 6;
      final opacity = (.25 + (math.sin(phase) + 1) * .34).clamp(0.0, 1.0);
      firefly.color = const Color(
        0xFFFFE992,
      ).withValues(alpha: opacity.toDouble());
      canvas.drawRect(Rect.fromLTWH(x, y, pixel * 1.5, pixel * 1.5), firefly);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldDetailsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.nestLevel != nestLevel ||
      oldDelegate.gardenLevel != gardenLevel;
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
          color: Color(0xCC17120E),
          borderRadius: BorderRadius.all(Radius.circular(7)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            'прибрати',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .16),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text),
      ),
      trailing: FilledButton(
        onPressed: enabled ? onTap : null,
        child: const Text('Додати'),
      ),
    ),
  );
}
