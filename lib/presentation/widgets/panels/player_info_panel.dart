import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';
import 'package:royalgambit/presentation/providers/timer_provider.dart';
import 'package:royalgambit/presentation/widgets/panels/captured_pieces_panel.dart';

class PlayerInfoPanel extends ConsumerWidget {
  final PieceColor playerColor;
  final bool isTop;

  const PlayerInfoPanel({
    super.key,
    required this.playerColor,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(gameProvider);
    final game = appState.game;
    final timerState = ref.watch(timerProvider);
    final timer = playerColor == PieceColor.white
        ? timerState.whiteTimer
        : timerState.blackTimer;

    final isCurrentTurn = game.currentTurn == playerColor;
    final isAiPlayer = game.mode == GameMode.vsComputer &&
        playerColor != (game.humanColor ?? PieceColor.white);

    String playerName;
    if (isAiPlayer) {
      playerName = AppStrings.computer;
    } else if (game.mode == GameMode.vsComputer) {
      playerName = AppStrings.you;
    } else {
      playerName =
          playerColor == PieceColor.white ? AppStrings.white : AppStrings.black;
    }

    final isLowTime = timer.isWarning || timer.isCritical;
    final timerColor = timer.isCritical
        ? AppColors.danger
        : timer.isWarning
            ? AppColors.accent
            : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentTurn ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTurn
            ? Border.all(color: AppColors.accent.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
        boxShadow: isCurrentTurn
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          // Player Avatar Circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrentTurn
                  ? AppColors.accent.withOpacity(0.2)
                  : const Color(0xFF282828),
              border: Border.all(
                color: isCurrentTurn
                    ? AppColors.accent
                    : AppColors.textSecondary.withOpacity(0.3),
                width: isCurrentTurn ? 2 : 1,
              ),
            ),
            child: ClipOval(
              child: isAiPlayer
                  ? Image.asset(
                      'assets/images/stockfish/icon.webp',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        playerColor == PieceColor.white ? 'W' : 'B',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isCurrentTurn
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + Captured Pieces
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        playerName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: isCurrentTurn
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isCurrentTurn
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ),
                    if (isCurrentTurn) ...[
                      const SizedBox(width: 8),
                      const _TurnIndicator(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                CapturedPiecesPanel(perspectiveColor: playerColor),
              ],
            ),
          ),

          // Timer Widget
          if (timerState.enabled)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLowTime
                    ? AppColors.danger.withOpacity(0.15)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: isLowTime
                    ? Border.all(color: AppColors.danger.withOpacity(0.4), width: 1)
                    : null,
              ),
              child: Text(
                timer.display,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: timerColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TurnIndicator extends StatefulWidget {
  const _TurnIndicator();

  @override
  State<_TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<_TurnIndicator> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
      ),
    );
  }
}
