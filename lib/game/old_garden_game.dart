import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

/// The first playable Zrobleno RPG location.
///
/// Flutter still owns navigation, forms and journals. Flame owns the moving
/// world so character placement, input and animation share one coordinate
/// system instead of a collection of unrelated Positioned widgets.
class OldGardenGame extends FlameGame with TapCallbacks {
  OldGardenGame({
    this.compact = false,
    this.initialFeederLevel = 0,
    this.showMess = false,
    this.onFirstMove,
    this.onFeederTap,
    this.onMessSweep,
    this.onMessCleaned,
  });

  static const _backgroundAsset = 'game/rpg/old-garden.webp';
  static const _birdAsset = 'game/rpg/bird-atlas.webp';
  static const _feederAsset = 'game/rpg/feeder-atlas.webp';
  static const _klaksaAsset = 'game/rpg/klaksa-atlas.webp';

  final bool compact;
  final int initialFeederLevel;
  bool showMess;
  final VoidCallback? onFirstMove;
  final VoidCallback? onFeederTap;
  final VoidCallback? onMessSweep;
  final VoidCallback? onMessCleaned;

  late final Image _backgroundImage;
  late final SpriteComponent _background;
  late final GardenBird _bird;
  late final SpriteSheet _feederSheet;
  late final SpriteComponent _feeder;
  GardenMess? _mess;
  GardenKlaksa? _klaksa;
  final List<GardenSparkle> _sparkles = [];

  bool _reportedFirstMove = false;
  int _feederLevel = 0;
  double _perchY = 0;
  double _celebrationRemaining = 0;

  @override
  Color backgroundColor() => const Color(0xFF6AC8E7);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';

    _backgroundImage = await images.load(_backgroundAsset);
    _background = SpriteComponent(priority: -100);
    add(_background);

    final birdImage = await images.load(_birdAsset);
    final birdSheet = SpriteSheet(image: birdImage, srcSize: Vector2.all(222));
    _bird = GardenBird(sheet: birdSheet, compact: compact);
    add(_bird);

    final feederImage = await images.load(_feederAsset);
    _feederSheet = SpriteSheet(image: feederImage, srcSize: Vector2.all(314));
    _feederLevel = initialFeederLevel.clamp(0, 3).toInt();
    _feeder = SpriteComponent(
      sprite: _feederSheet.getSpriteById(_feederLevel),
      anchor: Anchor.topCenter,
      priority: 4,
    );
    add(_feeder);

    if (showMess && !compact) await _addMessEvent();

    _layout(size);
  }

  Future<void> _addMessEvent() async {
    if (_mess != null) return;
    final klaksaImage = await images.load(_klaksaAsset);
    final klaksaSheet = SpriteSheet(
      image: klaksaImage,
      srcSize: Vector2.all(222),
    );
    _klaksa = GardenKlaksa(sheet: klaksaSheet);
    _mess = GardenMess();
    addAll([_klaksa!, _mess!]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout(size);
  }

  void _layout(Vector2 canvasSize) {
    if (canvasSize.x <= 0 || canvasSize.y <= 0) return;

    const sourceWidth = 768.0;
    const sourceHeight = 907.0;
    const sourceBranchY = 458.0;
    final sourceAspect = sourceWidth / sourceHeight;
    final targetAspect = canvasSize.x / canvasSize.y;

    double cropX = 0;
    double cropY = 0;
    double cropWidth = sourceWidth;
    double cropHeight = sourceHeight;
    if (sourceAspect > targetAspect) {
      cropWidth = sourceHeight * targetAspect;
      cropX = (sourceWidth - cropWidth) / 2;
    } else {
      cropHeight = sourceWidth / targetAspect;
      cropY = (sourceHeight - cropHeight) / 2;
    }

    _background
      ..sprite = Sprite(
        _backgroundImage,
        srcPosition: Vector2(cropX, cropY),
        srcSize: Vector2(cropWidth, cropHeight),
      )
      ..position = Vector2.zero()
      ..size = canvasSize;

    _perchY = ((sourceBranchY - cropY) / cropHeight * canvasSize.y)
        .clamp(canvasSize.y * .32, canvasSize.y * .69)
        .toDouble();
    final birdWidth = math.min(canvasSize.x * (compact ? .17 : .185), 74.0);
    _bird
      ..size = Vector2.all(birdWidth)
      ..home = Vector2(canvasSize.x * .52, _perchY + birdWidth * .055)
      ..groundY = canvasSize.y * .885;
    if (!_bird.hasMoved) _bird.position = _bird.home.clone();

    final feederSize = math.min(canvasSize.x * (compact ? .26 : .31), 126.0);
    _feeder
      ..size = Vector2.all(feederSize)
      ..position = Vector2(
        canvasSize.x * .79,
        _perchY - feederSize * .045,
      );

    final mess = _mess;
    if (mess != null) {
      mess
        ..size = Vector2(canvasSize.x * .14, canvasSize.x * .10)
        ..position = Vector2(canvasSize.x * .52, canvasSize.y * .79);
    }
    _klaksa?.place(canvasSize);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final point = event.localPosition;
    final mess = _mess;
    if (showMess && mess != null && !mess.isRemoved) {
      if ((point - mess.position).length < mess.size.x * .72) {
        onMessSweep?.call();
        if (mess.sweep()) {
          showMess = false;
          onMessCleaned?.call();
        }
        return;
      }
    }
    final feederCenter = _feeder.position + Vector2(0, _feeder.size.y * .5);
    if ((point - feederCenter).length < _feeder.size.x * .62) {
      celebrate();
      onFeederTap?.call();
      return;
    }

    if (compact) {
      _bird.playHappy();
      return;
    }

    final destinationY = point.y > size.y * .69 ? _bird.groundY : _perchY;
    _bird.moveTo(
      Vector2(
        point.x
            .clamp(_bird.size.x * .52, size.x - _bird.size.x * .52)
            .toDouble(),
        destinationY,
      ),
    );
    if (!_reportedFirstMove) {
      _reportedFirstMove = true;
      onFirstMove?.call();
    }
  }

  void setFeederLevel(int value, {bool withCelebration = false}) {
    _feederLevel = value.clamp(0, 3).toInt();
    if (!isLoaded) return;
    _feeder.sprite = _feederSheet.getSpriteById(_feederLevel);
    if (withCelebration) celebrate();
  }

  Future<void> setMessVisible(bool value) async {
    showMess = value;
    if (!isLoaded) return;
    if (value) {
      await _addMessEvent();
      _layout(size);
    } else {
      _mess?.removeFromParent();
      _mess = null;
    }
  }

  void celebrate() {
    if (!isLoaded) return;
    _celebrationRemaining = 2.4;
    _bird.playHappy();
    for (var index = 0; index < 34; index++) {
      final sparkle = GardenSparkle(
        seed: index + 41,
        origin: _feeder.position + Vector2(0, _feeder.size.y * .52),
      );
      _sparkles.add(sparkle);
      add(sparkle);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_celebrationRemaining <= 0) return;
    _celebrationRemaining -= dt;
    if (_celebrationRemaining <= 0) {
      _bird.returnToIdle();
      _sparkles.removeWhere((sparkle) => sparkle.isRemoved);
    }
  }
}

class GardenKlaksa extends SpriteAnimationComponent {
  GardenKlaksa({required SpriteSheet sheet})
    : super(
        animation: SpriteAnimation.spriteList(
          [1, 2, 1, 7].map(sheet.getSpriteById).toList(growable: false),
          stepTime: .1,
        ),
        anchor: Anchor.bottomCenter,
        priority: 2,
      );

  bool _placed = false;

  void place(Vector2 canvasSize) {
    if (_placed) return;
    _placed = true;
    size = Vector2.all(math.min(canvasSize.x * .105, 58));
    position = Vector2(canvasSize.x + size.x, canvasSize.y * .72);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_placed) return;
    position.x -= 105 * dt;
    position.y += math.sin(position.x * .13) * 6 * dt;
    if (position.x < -size.x) removeFromParent();
  }
}

class GardenMess extends PositionComponent {
  GardenMess() : super(anchor: Anchor.center, priority: 3);

  int _sweeps = 0;
  double _time = 0;

  bool sweep() {
    _sweeps += 1;
    scale = Vector2.all((1 - _sweeps * .09).clamp(.55, 1).toDouble());
    if (_sweeps < 5) return false;
    removeFromParent();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final fade = (1 - _sweeps * .14).clamp(.25, 1).toDouble();
    final dark = Paint()
      ..color = const Color(0xFF332119).withValues(alpha: fade)
      ..isAntiAlias = false;
    final brown = Paint()
      ..color = const Color(0xFF70472B).withValues(alpha: fade)
      ..isAntiAlias = false;
    final light = Paint()
      ..color = const Color(0xFF9A6740).withValues(alpha: fade)
      ..isAntiAlias = false;
    final w = size.x;
    final h = size.y;
    canvas.drawRect(Rect.fromLTWH(w * .18, h * .58, w * .64, h * .22), dark);
    canvas.drawRect(Rect.fromLTWH(w * .26, h * .42, w * .48, h * .24), brown);
    canvas.drawRect(Rect.fromLTWH(w * .35, h * .29, w * .30, h * .20), brown);
    canvas.drawRect(Rect.fromLTWH(w * .43, h * .18, w * .14, h * .16), light);

    final smoke = Paint()
      ..color = const Color(0xFFC8D0C2).withValues(alpha: fade * .7)
      ..strokeWidth = math.max(1.5, w * .025)
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    for (var index = 0; index < 2; index++) {
      final offset = math.sin(_time * 2.2 + index) * w * .04;
      canvas.drawLine(
        Offset(w * (.42 + index * .16), h * .18),
        Offset(w * (.38 + index * .16) + offset, -h * .12),
        smoke,
      );
    }

    final fly = Paint()
      ..color = const Color(0xFF17131D)
      ..isAntiAlias = false;
    final flies = math.max(1, 4 - _sweeps);
    for (var index = 0; index < flies; index++) {
      final x = w * (.2 + index * .19) + math.sin(_time * 5 + index) * w * .05;
      final y = h * (.12 + (index % 2) * .16) +
          math.cos(_time * 6 + index) * h * .08;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 3, height: 3),
        fly,
      );
    }
  }
}

class GardenBird extends SpriteAnimationComponent {
  GardenBird({required SpriteSheet sheet, required this.compact})
    : _idle = SpriteAnimation.spriteList(
        [
          0,
          1,
          0,
          2,
          0,
          3,
          1,
          0,
        ].map(sheet.getSpriteById).toList(growable: false),
        stepTime: .22,
      ),
      _moving = SpriteAnimation.spriteList(
        [4, 5, 6, 5, 7].map(sheet.getSpriteById).toList(growable: false),
        stepTime: .11,
      ),
      _happy = SpriteAnimation.spriteList(
        [6, 5, 6, 7, 1].map(sheet.getSpriteById).toList(growable: false),
        stepTime: .12,
      ),
      super(
        animation: SpriteAnimation.spriteList(
          [
            0,
            1,
            0,
            2,
            0,
            3,
            1,
            0,
          ].map(sheet.getSpriteById).toList(growable: false),
          stepTime: .22,
        ),
        anchor: Anchor.bottomCenter,
        priority: 5,
      );

  final bool compact;
  final SpriteAnimation _idle;
  final SpriteAnimation _moving;
  final SpriteAnimation _happy;

  Vector2 home = Vector2.zero();
  double groundY = 0;
  Vector2? _target;
  double _happyRemaining = 0;
  bool hasMoved = false;

  void moveTo(Vector2 value) {
    hasMoved = true;
    _target = value;
    animation = _moving;
  }

  void playHappy() {
    _happyRemaining = 2.0;
    animation = _happy;
  }

  void returnToIdle() {
    _happyRemaining = 0;
    if (_target == null) animation = _idle;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_happyRemaining > 0) {
      _happyRemaining -= dt;
      if (_happyRemaining <= 0 && _target == null) animation = _idle;
    }

    final target = _target;
    if (target == null) return;
    final delta = target - position;
    final distance = delta.length;
    if (distance < 2) {
      position = target;
      _target = null;
      if (_happyRemaining <= 0) animation = _idle;
      return;
    }
    final speed = compact ? 110.0 : 185.0;
    final step = math.min(distance, speed * dt);
    position += delta.normalized() * step;
  }
}

class GardenSparkle extends PositionComponent {
  GardenSparkle({required int seed, required Vector2 origin})
    : _random = math.Random(seed),
      super(position: origin.clone(), priority: 20) {
    final angle = -math.pi * (.08 + _random.nextDouble() * .84);
    final force = 62 + _random.nextDouble() * 118;
    _velocity = Vector2(math.cos(angle), math.sin(angle)) * force;
    _life = 1.15 + _random.nextDouble() * 1.05;
    _side = 3 + _random.nextDouble() * 4;
    _color = _colors[seed % _colors.length];
  }

  static const _colors = [
    Color(0xFFFFD65C),
    Color(0xFFFF6E78),
    Color(0xFF7BE5B2),
    Color(0xFFB69CFF),
    Color(0xFFFFFFFF),
  ];

  final math.Random _random;
  late Vector2 _velocity;
  late double _life;
  late double _side;
  late Color _color;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _velocity.y += 105 * dt;
    position += _velocity * dt;
    angle += dt * (_random.nextBool() ? 4 : -4);
    if (_age >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final opacity = (1 - _age / _life).clamp(0.0, 1.0).toDouble();
    final paint = Paint()
      ..color = _color.withValues(alpha: opacity)
      ..isAntiAlias = false;
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: _side, height: _side * 1.7),
      paint,
    );
  }
}
