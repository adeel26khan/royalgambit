import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundEffect {
  move,
  capture,
  check,
  error,
  lowTime,
  dong,
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  final Map<SoundEffect, AudioPlayer> _players = {};
  bool enabled = true;

  SoundService._internal() {
    _init();
  }

  void _init() {
    for (final effect in SoundEffect.values) {
      try {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.stop);
        _players[effect] = player;
      } catch (e) {
        debugPrint('AudioPlayer init error for $effect: $e');
      }
    }
  }

  Future<void> play(SoundEffect effect) async {
    if (!enabled) return;

    String path;
    switch (effect) {
      case SoundEffect.move:
        path = 'sounds/standard/move.mp3';
        break;
      case SoundEffect.capture:
        path = 'sounds/standard/capture.mp3';
        break;
      case SoundEffect.check:
      case SoundEffect.dong:
        path = 'sounds/standard/dong.mp3';
        break;
      case SoundEffect.error:
        path = 'sounds/standard/error.mp3';
        break;
      case SoundEffect.lowTime:
        path = 'sounds/standard/lowTime.mp3';
        break;
    }

    try {
      final player = _players[effect] ?? AudioPlayer();
      await player.stop();
      await player.play(AssetSource(path));
    } catch (e) {
      debugPrint('Error playing sound asset $path: $e');
    }
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
  }
}
