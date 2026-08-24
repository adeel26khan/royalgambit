import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/core/utils/ad_service.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';
import 'package:royalgambit/presentation/providers/profile_provider.dart';

class GameEndOverlay extends ConsumerStatefulWidget {
  const GameEndOverlay({super.key});

  @override
  ConsumerState<GameEndOverlay> createState() => _GameEndOverlayState();
}

class _GameEndOverlayState extends ConsumerState<GameEndOverlay> {
  bool _rewardsAwarded = false;
  bool _doubleRewardsClaimed = false;
  int _earnedXp = 0;
  int _earnedCoins = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateAndAwardRewards();
    });
  }

  void _calculateAndAwardRewards() {
    if (_rewardsAwarded) return;
    final game = ref.read(gameProvider).game;
    if (!game.isGameOver) return;

    final humanColor = game.humanColor ?? PieceColor.white;
    final isHumanWinner = (game.status == GameStatus.checkmate && game.currentTurn != humanColor) ||
        (humanColor == PieceColor.white && game.status == GameStatus.blackResigned) ||
        (humanColor == PieceColor.black && game.status == GameStatus.whiteResigned);

    final isDraw = game.status == GameStatus.stalemate ||
        game.status == GameStatus.drawByRepetition ||
        game.status == GameStatus.drawBy50Move ||
        game.status == GameStatus.drawByInsufficientMaterial ||
        game.status == GameStatus.drawByAgreement;

    int xp = 25; // Participation minimum
    int coins = 15;

    if (isHumanWinner) {
      coins = 100;
      switch (game.difficulty) {
        case AiDifficulty.beginner:
          xp = 100;
          break;
        case AiDifficulty.intermediate:
          xp = 200;
          break;
        case AiDifficulty.advanced:
          xp = 350;
          break;
        case AiDifficulty.master:
          xp = 500;
          break;
      }
    } else if (isDraw) {
      xp = 50;
      coins = 40;
    }

    _earnedXp = xp;
    _earnedCoins = coins;

    final notifier = ref.read(profileProvider.notifier);
    notifier.addXp(xp);
    notifier.addCoins(coins);

    setState(() {
      _rewardsAwarded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider).game;

    if (!game.isGameOver) return const SizedBox.shrink();

    final (title, subtitle, titleColor) = _getResult(game);
    final currentXp = _doubleRewardsClaimed ? _earnedXp * 2 : _earnedXp;
    final currentCoins = _doubleRewardsClaimed ? _earnedCoins * 2 : _earnedCoins;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (ctx, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.85 + 0.15 * value, child: child),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: titleColor.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: titleColor.withOpacity(0.25),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy / result icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: titleColor.withOpacity(0.15),
                    border: Border.all(color: titleColor, width: 2),
                  ),
                  child: Icon(
                    _getIcon(game.status),
                    color: titleColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondary,
                      ),
                ),
                const SizedBox(height: 14),

                // Stats row including XP and Coins earned
                _StatsRow(
                  game: game,
                  earnedXp: currentXp,
                  earnedCoins: currentCoins,
                ),
                const SizedBox(height: 18),

                // 2x Rewards Rewarded Ad Button
                if (!_doubleRewardsClaimed && _earnedXp > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AdService.instance.showRewardedAd(
                          onRewardGranted: () {
                            final notifier = ref.read(profileProvider.notifier);
                            notifier.addXp(_earnedXp);
                            notifier.addCoins(_earnedCoins);
                            setState(() {
                              _doubleRewardsClaimed = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Double Rewards! +${_earnedXp * 2} XP & +${_earnedCoins * 2} 🪙 Total!'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.rocket_launch, size: 20, color: Color(0xFF121212)),
                      label: Text(
                        'DOUBLE REWARDS (2x XP & 2x 🪙) 🚀',
                        style: const TextStyle(
                          color: Color(0xFF121212),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (r) => false);
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text(AppStrings.mainMenu),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(gameProvider.notifier).startNewGame(
                              mode: game.mode,
                              difficulty: game.difficulty,
                              humanColor:
                                  game.humanColor ?? PieceColor.white,
                            );
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text(AppStrings.playAgain),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, String, Color) _getResult(GameState game) {
    switch (game.status) {
      case GameStatus.checkmate:
        final winner = game.currentTurn == PieceColor.white
            ? AppStrings.black
            : AppStrings.white;
        return (AppStrings.checkmate, '$winner Wins!', AppColors.winColor);
      case GameStatus.stalemate:
        return (
          AppStrings.stalemate,
          'The game is a draw',
          AppColors.drawColor
        );
      case GameStatus.drawByRepetition:
        return (
          AppStrings.drawByRepetition,
          'Position repeated 3 times',
          AppColors.drawColor
        );
      case GameStatus.drawBy50Move:
        return (
          AppStrings.drawBy50Move,
          '50 moves without pawn or capture',
          AppColors.drawColor
        );
      case GameStatus.drawByInsufficientMaterial:
        return (
          AppStrings.drawByInsufficientMaterial,
          'Neither side can force checkmate',
          AppColors.drawColor
        );
      case GameStatus.drawByAgreement:
        return (
          AppStrings.drawByAgreement,
          'Both players agreed to draw',
          AppColors.drawColor
        );
      case GameStatus.whiteResigned:
        return (
          AppStrings.resignedWhite,
          '${AppStrings.black} Wins!',
          AppColors.lossColor
        );
      case GameStatus.blackResigned:
        return (
          AppStrings.resignedBlack,
          '${AppStrings.white} Wins!',
          AppColors.winColor
        );
      default:
        return ('Game Over', '', AppColors.drawColor);
    }
  }

  IconData _getIcon(GameStatus status) {
    switch (status) {
      case GameStatus.checkmate:
        return Icons.emoji_events;
      case GameStatus.stalemate:
      case GameStatus.drawByRepetition:
      case GameStatus.drawBy50Move:
      case GameStatus.drawByInsufficientMaterial:
      case GameStatus.drawByAgreement:
        return Icons.handshake_outlined;
      case GameStatus.whiteResigned:
      case GameStatus.blackResigned:
        return Icons.flag;
      default:
        return Icons.sports_esports;
    }
  }
}

class _StatsRow extends StatelessWidget {
  final GameState game;
  final int earnedXp;
  final int earnedCoins;

  const _StatsRow({
    required this.game,
    required this.earnedXp,
    required this.earnedCoins,
  });

  @override
  Widget build(BuildContext context) {
    final moveCount = game.moveHistory.length;
    final fullMoves = (moveCount / 2).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Moves', value: '$fullMoves'),
          Container(width: 1, height: 24, color: AppColors.secondary.withOpacity(0.3)),
          _Stat(label: 'XP', value: '+$earnedXp XP'),
          Container(width: 1, height: 24, color: AppColors.secondary.withOpacity(0.3)),
          _Stat(label: 'Coins', value: '+$earnedCoins 🪙'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

