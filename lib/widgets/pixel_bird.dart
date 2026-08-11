import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PixelBird extends StatelessWidget {
  const PixelBird({
    this.stage = 0,
    this.size = 72,
    this.playful = false,
    super.key,
  });

  final int stage;
  final double size;
  final bool playful;

  @override
  Widget build(BuildContext context) {
    final growth = 1.0 + stage.clamp(0, 3).toInt() * .045;
    return Transform.scale(
      scale: growth,
      child: PixelSpriteAtlas(
        asset: 'assets/game/bird-atlas.png',
        columns: 4,
        rows: 2,
        frameSequence: playful
            ? const [0, 1, 0, 2, 0, 3, 0, 4, 5, 6, 7, 5, 0, 1]
            : const [0, 1, 0, 1, 0, 2, 0, 3],
        framesPerSecond: playful ? 5 : 2.6,
        size: Size.square(size),
      ),
    );
  }
}

class PixelWolf extends StatelessWidget {
  const PixelWolf({
    this.size = 116,
    this.squat = false,
    this.surprised = false,
    super.key,
  });

  final double size;
  final bool squat;
  final bool surprised;

  @override
  Widget build(BuildContext context) => PixelSpriteAtlas(
        asset: 'assets/game/klaksa-atlas-v2.png',
        columns: 4,
        rows: 2,
        frameSequence: surprised
            ? const [3]
            : squat
                ? const [4, 5, 5, 4]
                : const [1, 2, 1, 7],
        framesPerSecond: surprised ? 1 : (squat ? 2 : 7),
        size: Size.square(size),
      );
}

class PixelFeeder extends StatelessWidget {
  const PixelFeeder({required this.level, this.size = 160, super.key});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) => PixelSpriteAtlas(
        asset: 'assets/game/feeder-atlas-v2.png',
        columns: 4,
        rows: 1,
        frameSequence: [level.clamp(0, 3).toInt()],
        framesPerSecond: 1,
        size: Size(size, size * .86),
      );
}

class PixelSpriteAtlas extends StatefulWidget {
  const PixelSpriteAtlas({
    required this.asset,
    required this.columns,
    required this.rows,
    required this.frameSequence,
    required this.size,
    this.framesPerSecond = 6,
    super.key,
  });

  final String asset;
  final int columns;
  final int rows;
  final List<int> frameSequence;
  final Size size;
  final double framesPerSecond;

  @override
  State<PixelSpriteAtlas> createState() => _PixelSpriteAtlasState();
}

class _PixelSpriteAtlasState extends State<PixelSpriteAtlas>
    with SingleTickerProviderStateMixin {
  ui.Image? image;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this)
      ..addListener(_tick)
      ..repeat(period: _period);
    _load();
  }

  Duration get _period {
    final seconds = widget.frameSequence.length / widget.framesPerSecond;
    return Duration(
      milliseconds: (seconds * 1000).round().clamp(240, 30000).toInt(),
    );
  }

  @override
  void didUpdateWidget(covariant PixelSpriteAtlas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _load();
    if (oldWidget.frameSequence != widget.frameSequence ||
        oldWidget.framesPerSecond != widget.framesPerSecond) {
      controller.repeat(period: _period);
    }
  }

  Future<void> _load() async {
    final data = await rootBundle.load(widget.asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    image?.dispose();
    setState(() => image = frame.image);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller
      ..removeListener(_tick)
      ..dispose();
    image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaded = image;
    if (loaded == null) {
      return SizedBox.fromSize(size: widget.size);
    }
    final index = (controller.value * widget.frameSequence.length)
        .floor()
        .clamp(0, widget.frameSequence.length - 1)
        .toInt();
    return SizedBox.fromSize(
      size: widget.size,
      child: CustomPaint(
        painter: _AtlasPainter(
          image: loaded,
          columns: widget.columns,
          rows: widget.rows,
          frame: widget.frameSequence[index],
        ),
      ),
    );
  }
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.frame,
  });

  final ui.Image image;
  final int columns;
  final int rows;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final safeFrame = frame.clamp(0, columns * rows - 1).toInt();
    final sourceWidth = image.width / columns;
    final sourceHeight = image.height / rows;
    final source = Rect.fromLTWH(
      (safeFrame % columns) * sourceWidth,
      (safeFrame ~/ columns) * sourceHeight,
      sourceWidth,
      sourceHeight,
    );
    final fitted = applyBoxFit(BoxFit.contain, source.size, size);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    canvas.drawImageRect(image, source, destination, paint);
  }

  @override
  bool shouldRepaint(covariant _AtlasPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.image != image;
}
