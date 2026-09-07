import 'package:audioplayers/audioplayers.dart';

enum AppSound {
  uiTap('sounds/ui_tap.wav'),
  actionConfirm('sounds/action_confirm.wav'),
  taskComplete('sounds/task_complete.wav'),
  rewardUnlock('sounds/reward_unlock.wav'),
  morningSun('sounds/morning_sun.wav'),
  softError('sounds/soft_error.wav'),
  broomSweep('sounds/broom_sweep.wav');

  const AppSound(this.assetPath);

  final String assetPath;
}

class SoundService {
  SoundService._();

  static final instance = SoundService._();

  final Map<AppSound, AudioPlayer> _players = {};
  bool _enabled = false;

  void configure({required bool enabled}) => _enabled = enabled;

  Future<void> play(AppSound sound) async {
    if (!_enabled) return;
    try {
      final player = _players.putIfAbsent(sound, AudioPlayer.new);
      if (player.state != PlayerState.stopped) await player.stop();
      await player.play(
        AssetSource(sound.assetPath),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Звук доповнює дію, але ніколи не повинен блокувати її.
    }
  }
}
