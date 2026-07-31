import 'package:shared_preferences/shared_preferences.dart';
import 'package:royalgambit/domain/models/game_state.dart';

/// Settings storage backed by SharedPreferences with a graceful in-memory
/// fallback. This ensures the app works on all platforms (including web
/// configurations where SharedPreferences may not be available at startup).
class SettingsStorage {
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyHapticsEnabled = 'haptics_enabled';
  static const _keyBoardTheme = 'board_theme';
  static const _keyDifficulty = 'difficulty';
  static const _keyShowCoordinates = 'show_coordinates';
  static const _keyTimerEnabled = 'timer_enabled';
  static const _keyTimerSeconds = 'timer_seconds';
  static const _keyPieceTheme = 'piece_theme';

  final SharedPreferences? _prefs;
  final Map<String, dynamic> _fallback = {};

  SettingsStorage._(this._prefs);

  /// Creates a [SettingsStorage]. Falls back to in-memory defaults
  /// if SharedPreferences is unavailable (e.g., on some web builds).
  static Future<SettingsStorage> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return SettingsStorage._(prefs);
    } catch (_) {
      // MissingPluginException or similar — use in-memory fallback
      return SettingsStorage._(null);
    }
  }

  // ─── Getters ─────────────────────────────────────────────────────────────

  bool get soundEnabled => _prefs?.getBool(_keySoundEnabled) ??
      (_fallback[_keySoundEnabled] as bool?) ?? true;
  bool get hapticsEnabled => _prefs?.getBool(_keyHapticsEnabled) ??
      (_fallback[_keyHapticsEnabled] as bool?) ?? true;
  BoardTheme get boardTheme => BoardTheme.values[
      _prefs?.getInt(_keyBoardTheme) ??
          (_fallback[_keyBoardTheme] as int?) ?? 0];
  PieceTheme get pieceTheme => PieceTheme.values[
      _prefs?.getInt(_keyPieceTheme) ??
          (_fallback[_keyPieceTheme] as int?) ?? 0];
  AiDifficulty get difficulty => AiDifficulty.values[
      _prefs?.getInt(_keyDifficulty) ??
          (_fallback[_keyDifficulty] as int?) ?? 1];
  bool get showCoordinates => _prefs?.getBool(_keyShowCoordinates) ??
      (_fallback[_keyShowCoordinates] as bool?) ?? true;
  bool get timerEnabled => _prefs?.getBool(_keyTimerEnabled) ??
      (_fallback[_keyTimerEnabled] as bool?) ?? false;
  int get timerSeconds => _prefs?.getInt(_keyTimerSeconds) ??
      (_fallback[_keyTimerSeconds] as int?) ?? 600;

  // ─── Setters ─────────────────────────────────────────────────────────────

  Future<void> setSoundEnabled(bool v) async {
    _fallback[_keySoundEnabled] = v;
    await _prefs?.setBool(_keySoundEnabled, v);
  }

  Future<void> setHapticsEnabled(bool v) async {
    _fallback[_keyHapticsEnabled] = v;
    await _prefs?.setBool(_keyHapticsEnabled, v);
  }

  Future<void> setBoardTheme(BoardTheme v) async {
    _fallback[_keyBoardTheme] = v.index;
    await _prefs?.setInt(_keyBoardTheme, v.index);
  }

  Future<void> setPieceTheme(PieceTheme v) async {
    _fallback[_keyPieceTheme] = v.index;
    await _prefs?.setInt(_keyPieceTheme, v.index);
  }

  Future<void> setDifficulty(AiDifficulty v) async {
    _fallback[_keyDifficulty] = v.index;
    await _prefs?.setInt(_keyDifficulty, v.index);
  }

  Future<void> setShowCoordinates(bool v) async {
    _fallback[_keyShowCoordinates] = v;
    await _prefs?.setBool(_keyShowCoordinates, v);
  }

  Future<void> setTimerEnabled(bool v) async {
    _fallback[_keyTimerEnabled] = v;
    await _prefs?.setBool(_keyTimerEnabled, v);
  }

  Future<void> setTimerSeconds(int v) async {
    _fallback[_keyTimerSeconds] = v;
    await _prefs?.setInt(_keyTimerSeconds, v);
  }
}
