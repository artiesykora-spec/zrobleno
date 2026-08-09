import 'package:flutter/material.dart';

import '../theme.dart';

class PixelBird extends StatelessWidget {
  const PixelBird({this.stage = 0, this.size = 72, super.key});

  final int stage;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _BirdPainter(stage)),
      );
}

class _BirdPainter extends CustomPainter {
  const _BirdPainter(this.stage);

  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 12;
    final dark = Paint()..color = const Color(0xFF20252B);
    final blue = Paint()..color = const Color(0xFF5BAFCB);
    final yellow = Paint()..color = sunYellow;
    final white = Paint()..color = const Color(0xFFF6F3DE);
    final black = Paint()..color = Colors.black;
    final bodyBoost = stage.clamp(0, 3).toDouble() * 0.35;

    void block(Paint paint, double x, double y, double w, double h) {
      canvas.drawRect(
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
        paint,
      );
    }

    block(dark, 3, 2 - bodyBoost, 5, 2);
    block(blue, 2.5, 3.5 - bodyBoost, 6, 5 + bodyBoost);
    block(yellow, 4, 5, 4, 3 + bodyBoost);
    block(dark, 1.5, 5, 2, 3);
    block(white, 6.5, 3, 1.5, 1.5);
    block(black, 7.1, 3.4, .55, .55);
    block(sunYellowPaint, 8.5, 4.3, 2, 1);
    block(dark, 4, 8.5 + bodyBoost, 1, 1.5);
    block(dark, 6.5, 8.5 + bodyBoost, 1, 1.5);
  }

  Paint get sunYellowPaint => Paint()..color = sunYellow;

  @override
  bool shouldRepaint(covariant _BirdPainter oldDelegate) =>
      oldDelegate.stage != stage;
}
