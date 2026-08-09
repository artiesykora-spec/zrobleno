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
                    'Синичка: рівень ${store.game.birdStage + 1}',
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
                enabled: store.game.nestLevel < 5 &&
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
                enabled: store.game.gardenLevel < 5 &&
                    store.game.seeds >= store.gardenUpgradeCost(),
                onTap: store.upgradeGarden,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Тут немає покарань: прогрес не зникає. Клякса — лише жартівливе нагадування.',
                  style: TextStyle(color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
}

class _WorldScene extends StatelessWidget {
  const _WorldScene({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) => Container(
        height: 390,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF292052), Color(0xFF102C2C)],
          ),
          border: Border.all(color: const Color(0xFF393348)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: 22,
              right: 26,
              child: Icon(Icons.wb_sunny, color: sunYellow, size: 48),
            ),
            Positioned(
              left: 22,
              bottom: 44,
              child: _Garden(level: store.game.gardenLevel),
            ),
            Positioned(
              right: 25,
              bottom: 78,
              child: _Nest(level: store.game.nestLevel),
            ),
            Positioned(
              right: 66,
              bottom: 122,
              child: PixelBird(
                stage: store.game.birdStage,
                size: (86 + store.game.birdStage * 7).toDouble(),
              ),
            ),
            const Positioned(
              left: 20,
              top: 78,
              right: 105,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xEE17171C),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Рада, що ти повернувся! Давай зробимо сьогодні один хороший крок.',
                    style: TextStyle(fontFamily: 'monospace', height: 1.35),
                  ),
                ),
              ),
            ),
            if (store.game.wolfMess)
              Positioned(
                left: 105,
                bottom: 12,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutBack,
                  tween: Tween(begin: -1.0, end: 0.0),
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(value * 180, 0),
                    child: child,
                  ),
                  child: const _Wolf(),
                ),
              ),
            if (store.game.wolfMess)
              Positioned(
                right: 118,
                bottom: 20,
                child: Semantics(
                  button: true,
                  label: 'Прибрати жарт Клякси',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: store.cleanWolfMess,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Text('〰', style: TextStyle(color: Colors.white54)),
                          Text('💩', style: TextStyle(fontSize: 34)),
                          Text(
                            'прибрати',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _Nest extends StatelessWidget {
  const _Nest({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (level >= 3) const Text('✦', style: TextStyle(color: sunYellow)),
          Container(
            width: (110 + level * 6).toDouble(),
            height: (46 + level * 3).toDouble(),
            decoration: BoxDecoration(
              color: const Color(0xFF79543C),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(60),
                top: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFBA8556), width: 3),
            ),
          ),
        ],
      );
}

class _Garden extends StatelessWidget {
  const _Garden({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          2 + level,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(
              index.isEven ? Icons.local_florist : Icons.grass,
              color: index.isEven ? orange : green,
              size: (25 + index % 3 * 4).toDouble(),
            ),
          ),
        ),
      );
}

class _Wolf extends StatelessWidget {
  const _Wolf();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 115,
        height: 75,
        child: CustomPaint(painter: _WolfPainter()),
      );
}

class _WolfPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFF101012);
    final outline = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final rect = Rect.fromLTWH(10, 18, 88, 42);
    canvas.drawOval(rect, body);
    canvas.drawOval(rect, outline);
    canvas.drawPath(
      Path()
        ..moveTo(75, 20)
        ..lineTo(82, 3)
        ..lineTo(90, 22)
        ..close(),
      body,
    );
    final legs = Paint()
      ..color = Colors.white60
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [26.0, 46.0, 68.0, 88.0]) {
      canvas.drawLine(Offset(x, 54), Offset(x - 3, 70), legs);
    }
    final eye = Paint()..color = sunYellow;
    canvas.drawCircle(const Offset(82, 32), 3, eye);
    canvas.drawLine(const Offset(8, 35), const Offset(0, 26), legs);
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
