import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/old_garden_game.dart';

/// Small bridge between Flutter's application UI and the Flame garden.
class RpgGardenController {
  OldGardenGame? _game;

  void _attach(OldGardenGame game) => _game = game;

  void _detach(OldGardenGame game) {
    if (identical(_game, game)) _game = null;
  }

  void celebrate() => _game?.celebrate();

  void setFeederLevel(int level, {bool celebrate = false}) =>
      _game?.setFeederLevel(level, withCelebration: celebrate);
}

class RpgGardenView extends StatefulWidget {
  const RpgGardenView({
    required this.feederLevel,
    this.compact = false,
    this.controller,
    this.onFirstMove,
    this.onFeederTap,
    super.key,
  });

  final int feederLevel;
  final bool compact;
  final RpgGardenController? controller;
  final VoidCallback? onFirstMove;
  final VoidCallback? onFeederTap;

  @override
  State<RpgGardenView> createState() => _RpgGardenViewState();
}

class _RpgGardenViewState extends State<RpgGardenView> {
  late final OldGardenGame game;

  @override
  void initState() {
    super.initState();
    game = OldGardenGame(
      compact: widget.compact,
      initialFeederLevel: widget.feederLevel,
      onFirstMove: widget.onFirstMove,
      onFeederTap: widget.onFeederTap,
    );
    widget.controller?._attach(game);
  }

  @override
  void didUpdateWidget(covariant RpgGardenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(game);
      widget.controller?._attach(game);
    }
    if (oldWidget.feederLevel != widget.feederLevel) {
      game.setFeederLevel(widget.feederLevel, withCelebration: true);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(game);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(child: GameWidget<OldGardenGame>(game: game));
}
