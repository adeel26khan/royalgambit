import 'package:royalgambit/domain/models/game_state.dart';

class PlayerProfile {
  final int xp;
  final int coins;
  final Set<BoardTheme> unlockedBoardThemes;
  final Set<PieceTheme> unlockedPieceThemes;
  final DateTime? lastDailyReward;
  final int dailyAdWatchCount;
  final DateTime? lastAdWatchTimestamp;

  static const int maxDailyRewardedAds = 3;

  const PlayerProfile({
    this.xp = 0,
    this.coins = 250,
    this.unlockedBoardThemes = const {
      BoardTheme.walnut,
      BoardTheme.wood2,
      BoardTheme.maple,
    },
    this.unlockedPieceThemes = const {
      PieceTheme.alpha,
      PieceTheme.totoy,
    },
    this.lastDailyReward,
    this.dailyAdWatchCount = 0,
    this.lastAdWatchTimestamp,
  });

  /// Current Rank Level (1 to 7)
  int get rankLevel {
    if (xp < 300) return 1;
    if (xp < 800) return 2;
    if (xp < 1500) return 3;
    if (xp < 3000) return 4;
    if (xp < 6000) return 5;
    if (xp < 10000) return 6;
    return 7;
  }

  /// Current Rank Title
  String get rankTitle {
    switch (rankLevel) {
      case 1:
        return 'Novice';
      case 2:
        return 'Apprentice';
      case 3:
        return 'Club Player';
      case 4:
        return 'Tactician';
      case 5:
        return 'Candidate Master';
      case 6:
        return 'Grandmaster';
      case 7:
        return 'Royal Champion';
      default:
        return 'Novice';
    }
  }

  /// Target XP needed for the next rank
  int get nextRankXp {
    switch (rankLevel) {
      case 1:
        return 300;
      case 2:
        return 800;
      case 3:
        return 1500;
      case 4:
        return 3000;
      case 5:
        return 6000;
      case 6:
        return 10000;
      case 7:
        return 10000;
      default:
        return 300;
    }
  }

  /// XP threshold at start of current rank
  int get currentRankBaseXp {
    switch (rankLevel) {
      case 1:
        return 0;
      case 2:
        return 300;
      case 3:
        return 800;
      case 4:
        return 1500;
      case 5:
        return 3000;
      case 6:
        return 6000;
      case 7:
        return 10000;
      default:
        return 0;
    }
  }

  /// Progress from 0.0 to 1.0 towards next rank
  double get rankProgress {
    if (rankLevel >= 7) return 1.0;
    final range = nextRankXp - currentRankBaseXp;
    final current = xp - currentRankBaseXp;
    return (current / range).clamp(0.0, 1.0);
  }

  bool isBoardThemeUnlocked(BoardTheme theme) =>
      unlockedBoardThemes.contains(theme);

  bool isPieceThemeUnlocked(PieceTheme theme) =>
      unlockedPieceThemes.contains(theme);

  /// Balanced Game Economy Pricing: Skins require gameplay progression!
  static int boardSkinCost(BoardTheme theme) {
    switch (theme) {
      case BoardTheme.walnut:
      case BoardTheme.wood2:
      case BoardTheme.maple:
        return 0;
      case BoardTheme.wood3:
      case BoardTheme.wood4:
      case BoardTheme.brown:
      case BoardTheme.blue:
      case BoardTheme.green:
        return 1200;
      case BoardTheme.blueMarble:
      case BoardTheme.grey:
      case BoardTheme.canvas:
      case BoardTheme.leather:
        return 2500;
      case BoardTheme.marble:
      case BoardTheme.metal:
      case BoardTheme.purpleDiag:
        return 5000;
    }
  }

  static int pieceSkinCost(PieceTheme theme) {
    switch (theme) {
      case PieceTheme.alpha:
      case PieceTheme.totoy:
        return 0;
      case PieceTheme.fantasy:
        return 3500;
      case PieceTheme.customSvg:
        return 6000;
    }
  }

  bool get canClaimDailyReward {
    if (lastDailyReward == null) return true;
    final now = DateTime.now();
    return now.difference(lastDailyReward!).inHours >= 20;
  }

  /// AdMob Frequency Policy: Max 3 Rewarded Ads per 24h period
  bool get isDailyAdLimitReset {
    if (lastAdWatchTimestamp == null) return true;
    final now = DateTime.now();
    return now.difference(lastAdWatchTimestamp!).inHours >= 24;
  }

  int get effectiveDailyAdCount {
    return isDailyAdLimitReset ? 0 : dailyAdWatchCount;
  }

  bool get canWatchRewardedAd {
    return effectiveDailyAdCount < maxDailyRewardedAds;
  }

  int get remainingDailyAds {
    return (maxDailyRewardedAds - effectiveDailyAdCount).clamp(0, maxDailyRewardedAds);
  }

  PlayerProfile copyWith({
    int? xp,
    int? coins,
    Set<BoardTheme>? unlockedBoardThemes,
    Set<PieceTheme>? unlockedPieceThemes,
    DateTime? lastDailyReward,
    int? dailyAdWatchCount,
    DateTime? lastAdWatchTimestamp,
  }) {
    return PlayerProfile(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      unlockedBoardThemes: unlockedBoardThemes ?? this.unlockedBoardThemes,
      unlockedPieceThemes: unlockedPieceThemes ?? this.unlockedPieceThemes,
      lastDailyReward: lastDailyReward ?? this.lastDailyReward,
      dailyAdWatchCount: dailyAdWatchCount ?? this.dailyAdWatchCount,
      lastAdWatchTimestamp: lastAdWatchTimestamp ?? this.lastAdWatchTimestamp,
    );
  }
}


