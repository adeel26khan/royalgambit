import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/utils/sound_service.dart';
import 'package:royalgambit/data/repositories/settings_storage.dart';
import 'package:royalgambit/domain/models/game_state.dart';

class AppSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final BoardTheme boardTheme;
  final PieceTheme pieceTheme;
  final AiDifficulty difficulty;
  final bool showCoordinates;
  final bool timerEnabled;
  final int timerSeconds;

  const AppSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.boardTheme = BoardTheme.walnut,
    this.pieceTheme = PieceTheme.alpha,
    this.difficulty = AiDifficulty.intermediate,
    this.showCoordinates = true,
    this.timerEnabled = false,
    this.timerSeconds = 600,
  });

  AppSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    BoardTheme? boardTheme,
    PieceTheme? pieceTheme,
    AiDifficulty? difficulty,
    bool? showCoordinates,
    bool? timerEnabled,
    int? timerSeconds,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      boardTheme: boardTheme ?? this.boardTheme,
      pieceTheme: pieceTheme ?? this.pieceTheme,
      difficulty: difficulty ?? this.difficulty,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsStorage _storage;

  SettingsNotifier(this._storage)
      : super(AppSettings(
          soundEnabled: _storage.soundEnabled,
          hapticsEnabled: _storage.hapticsEnabled,
          boardTheme: _storage.boardTheme,
          pieceTheme: _storage.pieceTheme,
          difficulty: _storage.difficulty,
          showCoordinates: _storage.showCoordinates,
          timerEnabled: _storage.timerEnabled,
          timerSeconds: _storage.timerSeconds,
        )) {
    SoundService().enabled = _storage.soundEnabled;
  }

  Future<void> setSoundEnabled(bool v) async {
    await _storage.setSoundEnabled(v);
    SoundService().enabled = v;
    state = state.copyWith(soundEnabled: v);
  }

  Future<void> setHapticsEnabled(bool v) async {
    await _storage.setHapticsEnabled(v);
    state = state.copyWith(hapticsEnabled: v);
  }

  Future<void> setBoardTheme(BoardTheme v) async {
    await _storage.setBoardTheme(v);
    state = state.copyWith(boardTheme: v);
  }

  Future<void> setPieceTheme(PieceTheme v) async {
    await _storage.setPieceTheme(v);
    state = state.copyWith(pieceTheme: v);
  }

  Future<void> setDifficulty(AiDifficulty v) async {
    await _storage.setDifficulty(v);
    state = state.copyWith(difficulty: v);
  }

  Future<void> setShowCoordinates(bool v) async {
    await _storage.setShowCoordinates(v);
    state = state.copyWith(showCoordinates: v);
  }

  Future<void> setTimerEnabled(bool v) async {
    await _storage.setTimerEnabled(v);
    state = state.copyWith(timerEnabled: v);
  }

  Future<void> setTimerSeconds(int v) async {
    await _storage.setTimerSeconds(v);
    state = state.copyWith(timerSeconds: v);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final settingsStorageProvider = Provider<SettingsStorage>((ref) {
  throw UnimplementedError('Override in ProviderScope overrides');
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  return SettingsNotifier(storage);
});
