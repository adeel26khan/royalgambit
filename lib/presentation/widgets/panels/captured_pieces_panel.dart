import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';
import 'package:royalgambit/presentation/widgets/board/piece_painter.dart';

class CapturedPiecesPanel extends ConsumerWidget {
  final PieceColor perspectiveColor; // Which player's captures to show

  const CapturedPiecesPanel({super.key, required this.perspectiveColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider).game;

    // The pieces captured by perspectiveColor (their opponent's pieces)
    final captured = perspectiveColor == PieceColor.white
        ? game.whiteCaptured
        : game.blackCaptured;

    // Sort by value (highest first)
    final sorted = [...captured]
      ..sort((a, b) => b.value.compareTo(a.value));

    final advantage = perspectiveColor == PieceColor.white
        ? game.materialAdvantage
        : -game.materialAdvantage;

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          // Mini piece icons
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sorted.map((p) {
                  return PieceWidget(
                    type: p.type,
                    color: p.color,
                    size: 22,
                  );
                }).toList(),
              ),
            ),
          ),

          // Material advantage
          if (advantage > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+$advantage',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
