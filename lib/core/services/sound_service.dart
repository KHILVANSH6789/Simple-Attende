// ============================================================
// lib/core/services/sound_service.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const int _clickPoolSize = 6;
  final List<AudioPlayer> _clickPlayers = [];
  int _currentClickIndex = 0;

  final AudioPlayer _savePlayer = AudioPlayer();
  final AudioPlayer _introPlayer = AudioPlayer();
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    // High fidelity audio configuration
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ),
    );

    // Pre-initialize pool of click players for concurrent/polyphonic sounds
    for (int i = 0; i < _clickPoolSize; i++) {
      final p = AudioPlayer();
      p.setPlayerMode(PlayerMode.lowLatency);
      p.setVolume(1.0);
      _clickPlayers.add(p);
    }

    _savePlayer.setPlayerMode(PlayerMode.lowLatency);
    _savePlayer.setVolume(1.0);
    _introPlayer.setVolume(1.0);
  }

  /// Plays click sound using next available player in the pool for seamless overlapping
  Future<void> playClick() async {
    init();
    try {
      final player = _clickPlayers[_currentClickIndex];
      _currentClickIndex = (_currentClickIndex + 1) % _clickPoolSize;
      await player.stop();
      await player.play(
        AssetSource('audio/Button_Click.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (_) {}
  }

  /// Plays save button sound
  Future<void> playSave() async {
    init();
    try {
      await _savePlayer.stop();
      await _savePlayer.play(
        AssetSource('audio/Save_Button.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (_) {}
  }

  /// Plays intro sound
  Future<void> playIntro() async {
    init();
    try {
      await _introPlayer.stop();
      await _introPlayer.play(
        AssetSource('audio/Intro_Sound.mp3'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  void stopIntro() {
    try {
      _introPlayer.stop();
    } catch (_) {}
  }
}

/// Unified helper for sounds and haptics across the app
class FeedbackService {
  FeedbackService._();

  /// Standard button/tile tap feedback (sound + light haptic)
  static void tap(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    if (settings.soundEnabled) {
      SoundService.instance.playClick();
    }
  }

  /// Save / submit action feedback (save sound + medium haptic)
  static void save(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (settings.soundEnabled) {
      SoundService.instance.playSave();
    }
  }

  /// Light haptic only (e.g. for sliders, segmented buttons, pull-to-refresh)
  static void haptic(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }
}
