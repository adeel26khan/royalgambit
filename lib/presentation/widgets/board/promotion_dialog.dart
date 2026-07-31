import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';
import 'package:royalgambit/presentation/widgets/board/piece_painter.dart';

class PromotionDialog extends ConsumerWidget {
  const PromotionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(gameProvider);
    final pending = appState.pendingPromotion;
    if (pending == null) return const SizedBox.shrink();

    final color = appState.game.currentTurn;

    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.promotePawn,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a piece to promote to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PieceType.queen,
                    PieceType.rook,
                    PieceType.bishop,
                    PieceType.knight,
                  ].map((type) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _PromotionChoice(
                          type: type,
                          color: color,
                          onTap: () {
                            ref
                                .read(gameProvider.notifier)
                                .confirmPromotion(type);
                          },
                        ),
                      )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionChoice extends StatefulWidget {
  final PieceType type;
  final PieceColor color;
  final VoidCallback onTap;

  const _PromotionChoice({
    required this.type,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PromotionChoice> createState() => _PromotionChoiceState();
}

class _PromotionChoiceState extends State<_PromotionChoice> {
  bool _hovered = false;

  String get _label {
    switch (widget.type) {
      case PieceType.queen:
        return AppStrings.queen;
      case PieceType.rook:
        return AppStrings.rook;
      case PieceType.bishop:
        return AppStrings.bishop;
      case PieceType.knight:
        return AppStrings.knight;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent.withOpacity(0.15)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PieceWidget(
                type: widget.type,
                color: widget.color,
                size: 48,
              ),
              const SizedBox(height: 6),
              Text(
                _label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _hovered ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
