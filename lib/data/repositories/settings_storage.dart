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

  static const _keyPlayerXp = 'player_xp';
  static const _keyPlayerCoins = 'player_coins';
  static const _keyUnlockedBoards = 'unlocked_boards';
  static const _keyUnlockedPieceThemes = 'unlocked_piece_themes';
  static const _keyLastDailyReward = 'last_daily_reward';
  static const _keyDailyAdWatchCount = 'daily_ad_watch_count';
  static const _keyLastAdWatchTimestamp = 'last_ad_watch_timestamp';

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

  int get playerXp => _prefs?.getInt(_keyPlayerXp) ??
      (_fallback[_keyPlayerXp] as int?) ?? 0;

  int get playerCoins => _prefs?.getInt(_keyPlayerCoins) ??
      (_fallback[_keyPlayerCoins] as int?) ?? 250;

  Set<BoardTheme> get unlockedBoardThemes {
    final raw = _prefs?.getStringList(_keyUnlockedBoards) ??
        (_fallback[_keyUnlockedBoards] as List<String>?);
    if (raw == null || raw.isEmpty) {
      return {BoardTheme.walnut, BoardTheme.wood2, BoardTheme.maple};
    }
    return raw
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .where((i) => i >= 0 && i < BoardTheme.values.length)
        .map((i) => BoardTheme.values[i])
        .toSet();
  }

  Set<PieceTheme> get unlockedPieceThemes {
    final raw = _prefs?.getStringList(_keyUnlockedPieceThemes) ??
        (_fallback[_keyUnlockedPieceThemes] as List<String>?);
    if (raw == null || raw.isEmpty) {
      return {PieceTheme.alpha, PieceTheme.totoy};
    }
    return raw
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .where((i) => i >= 0 && i < PieceTheme.values.length)
        .map((i) => PieceTheme.values[i])
        .toSet();
  }

  DateTime? get lastDailyReward {
    final str = _prefs?.getString(_keyLastDailyReward) ??
        (_fallback[_keyLastDailyReward] as String?);
    return str != null ? DateTime.tryParse(str) : null;
  }

  int get dailyAdWatchCount => _prefs?.getInt(_keyDailyAdWatchCount) ??
      (_fallback[_keyDailyAdWatchCount] as int?) ?? 0;

  DateTime? get lastAdWatchTimestamp {
    final str = _prefs?.getString(_keyLastAdWatchTimestamp) ??
        (_fallback[_keyLastAdWatchTimestamp] as String?);
    return str != null ? DateTime.tryParse(str) : null;
  }

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

  Future<void> setPlayerXp(int xp) async {
    _fallback[_keyPlayerXp] = xp;
    await _prefs?.setInt(_keyPlayerXp, xp);
  }

  Future<void> setPlayerCoins(int coins) async {
    _fallback[_keyPlayerCoins] = coins;
    await _prefs?.setInt(_keyPlayerCoins, coins);
  }

  Future<void> setUnlockedBoardThemes(Set<BoardTheme> themes) async {
    final list = themes.map((t) => t.index.toString()).toList();
    _fallback[_keyUnlockedBoards] = list;
    await _prefs?.setStringList(_keyUnlockedBoards, list);
  }

  Future<void> setUnlockedPieceThemes(Set<PieceTheme> themes) async {
    final list = themes.map((t) => t.index.toString()).toList();
    _fallback[_keyUnlockedPieceThemes] = list;
    await _prefs?.setStringList(_keyUnlockedPieceThemes, list);
  }

  Future<void> setLastDailyReward(DateTime time) async {
    final str = time.toIso8601String();
    _fallback[_keyLastDailyReward] = str;
    await _prefs?.setString(_keyLastDailyReward, str);
  }

  Future<void> setDailyAdWatchCount(int count) async {
    _fallback[_keyDailyAdWatchCount] = count;
    await _prefs?.setInt(_keyDailyAdWatchCount, count);
  }

  Future<void> setLastAdWatchTimestamp(DateTime time) async {
    final str = time.toIso8601String();
    _fallback[_keyLastAdWatchTimestamp] = str;
    await _prefs?.setString(_keyLastAdWatchTimestamp, str);
  }
}



