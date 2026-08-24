import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/data/repositories/settings_storage.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/player_profile.dart';
import 'package:royalgambit/presentation/providers/settings_provider.dart';

class ProfileNotifier extends StateNotifier<PlayerProfile> {
  final SettingsStorage _storage;

  ProfileNotifier(this._storage)
      : super(PlayerProfile(
          xp: _storage.playerXp,
          coins: _storage.playerCoins,
          unlockedBoardThemes: _storage.unlockedBoardThemes,
          unlockedPieceThemes: _storage.unlockedPieceThemes,
          lastDailyReward: _storage.lastDailyReward,
          dailyAdWatchCount: _storage.dailyAdWatchCount,
          lastAdWatchTimestamp: _storage.lastAdWatchTimestamp,
        ));

  Future<void> addXp(int amount) async {
    final newXp = state.xp + amount;
    await _storage.setPlayerXp(newXp);
    state = state.copyWith(xp: newXp);
  }

  Future<void> addCoins(int amount) async {
    final newCoins = state.coins + amount;
    await _storage.setPlayerCoins(newCoins);
    state = state.copyWith(coins: newCoins);
  }

  Future<bool> recordRewardedAdWatch() async {
    if (!state.canWatchRewardedAd) return false;

    final now = DateTime.now();
    final newCount = state.isDailyAdLimitReset ? 1 : state.dailyAdWatchCount + 1;

    await _storage.setDailyAdWatchCount(newCount);
    await _storage.setLastAdWatchTimestamp(now);
    await addCoins(100);

    state = state.copyWith(
      dailyAdWatchCount: newCount,
      lastAdWatchTimestamp: now,
    );

    return true;
  }

  Future<bool> buyBoardTheme(BoardTheme theme, int cost) async {
    if (state.coins < cost && cost > 0) return false;
    final newCoins = state.coins - cost;
    final updatedBoards = Set<BoardTheme>.from(state.unlockedBoardThemes)..add(theme);
    await _storage.setPlayerCoins(newCoins);
    await _storage.setUnlockedBoardThemes(updatedBoards);
    state = state.copyWith(coins: newCoins, unlockedBoardThemes: updatedBoards);
    return true;
  }

  Future<bool> buyPieceTheme(PieceTheme theme, int cost) async {
    if (state.coins < cost && cost > 0) return false;
    final newCoins = state.coins - cost;
    final updatedPieces = Set<PieceTheme>.from(state.unlockedPieceThemes)..add(theme);
    await _storage.setPlayerCoins(newCoins);
    await _storage.setUnlockedPieceThemes(updatedPieces);
    state = state.copyWith(coins: newCoins, unlockedPieceThemes: updatedPieces);
    return true;
  }

  Future<void> unlockBoardTheme(BoardTheme theme) async {
    final updated = Set<BoardTheme>.from(state.unlockedBoardThemes)..add(theme);
    await _storage.setUnlockedBoardThemes(updated);
    state = state.copyWith(unlockedBoardThemes: updated);
  }

  Future<void> unlockPieceTheme(PieceTheme theme) async {
    final updated = Set<PieceTheme>.from(state.unlockedPieceThemes)..add(theme);
    await _storage.setUnlockedPieceThemes(updated);
    state = state.copyWith(unlockedPieceThemes: updated);
  }

  Future<bool> claimDailyReward() async {
    if (!state.canClaimDailyReward) return false;
    final now = DateTime.now();
    await _storage.setLastDailyReward(now);
    await addCoins(50); // Daily bonus is 50 Coins
    state = state.copyWith(lastDailyReward: now);
    return true;
  }
}



final profileProvider =
    StateNotifierProvider<ProfileNotifier, PlayerProfile>((ref) {
  final storage = ref.watch(settingsStorageProvider);
  return ProfileNotifier(storage);
});
