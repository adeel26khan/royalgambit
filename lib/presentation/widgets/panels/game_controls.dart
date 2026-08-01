import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/core/utils/ad_service.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';

class GameControls extends ConsumerWidget {
  final bool compact;

  const GameControls({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(gameProvider);
    final game = appState.game;
    final canUndo = appState.undoStack.isNotEmpty && !appState.isAiThinking;
    final canRedo = appState.redoStack.isNotEmpty && !appState.isAiThinking;
    final isLocalMode = game.mode == GameMode.local2Player;
    final drawOffered = game.drawOfferedByWhite || game.drawOfferedByBlack;

    void triggerUndoWithAdFallback() {
      if (canUndo) {
        ref.read(gameProvider.notifier).undo();
      } else if (!appState.isAiThinking && game.moveHistory.isNotEmpty) {
        // Offer Rewarded Ad to unlock extra undo
        AdService.instance.showRewardedAd(
          onRewardGranted: () {
            ref.read(gameProvider.notifier).undo();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Extra Undo Granted! 🎬'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      }
    }

    if (compact) {
      return _CompactControls(
        canUndo: canUndo || (!appState.isAiThinking && game.moveHistory.isNotEmpty),
        canRedo: canRedo,
        onUndo: triggerUndoWithAdFallback,
        onRedo: () => ref.read(gameProvider.notifier).redo(),
        onFlip: () => ref.read(gameProvider.notifier).flipBoard(),
        onNew: () => _confirmNewGame(context, ref),
        onResign: () => _confirmResign(context, ref),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Undo / Redo / Flip
          Row(
            children: [
              _ControlButton(
                icon: Icons.undo,
                label: canUndo ? AppStrings.undo : 'Ad Undo',
                onTap: (canUndo || (!appState.isAiThinking && game.moveHistory.isNotEmpty))
                    ? triggerUndoWithAdFallback
                    : null,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.redo,
                label: AppStrings.redo,
                onTap: canRedo ? () => ref.read(gameProvider.notifier).redo() : null,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: Icons.swap_vert,
                label: AppStrings.flipBoard,
                onTap: () => ref.read(gameProvider.notifier).flipBoard(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Draw offer banner
          if (drawOffered)
            _DrawOfferBanner(
              onAccept: () => ref.read(gameProvider.notifier).acceptDraw(),
              onDecline: () => ref.read(gameProvider.notifier).declineDraw(),
            ),

          // Row 2: Offer Draw / Resign
          if (!game.isGameOver)
            Row(
              children: [
                if (isLocalMode && !drawOffered) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(gameProvider.notifier).offerDraw(),
                      icon: const Icon(Icons.handshake_outlined, size: 16),
                      label: const Text(AppStrings.offerDraw),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmResign(context, ref),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text(AppStrings.resign),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withOpacity(0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // New Game button
          ElevatedButton.icon(
            onPressed: () => _confirmNewGame(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(AppStrings.newGame),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResign(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Resign Game?',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20),
        ),
        content: Text(
          'Your opponent will win by resignation.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameProvider.notifier).resign();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  void _confirmNewGame(BuildContext context, WidgetRef ref) {
    final game = ref.read(gameProvider).game;
    if (game.moveHistory.isEmpty || game.isGameOver) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'New Game?',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 20),
        ),
        content: Text(
          'The current match progress will be lost.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }
}

class _CompactControls extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onFlip;
  final VoidCallback onNew;
  final VoidCallback onResign;

  const _CompactControls({
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onFlip,
    required this.onNew,
    required this.onResign,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: canUndo ? onUndo : null,
          icon: const Icon(Icons.undo),
          tooltip: AppStrings.undo,
          color: canUndo ? AppColors.accent : AppColors.textSecondary,
        ),
        IconButton(
          onPressed: canRedo ? onRedo : null,
          icon: const Icon(Icons.redo),
          tooltip: AppStrings.redo,
          color: canRedo ? AppColors.accent : AppColors.textSecondary,
        ),
        IconButton(
          onPressed: onFlip,
          icon: const Icon(Icons.swap_vert),
          tooltip: AppStrings.flipBoard,
          color: AppColors.textPrimary,
        ),
        IconButton(
          onPressed: onResign,
          icon: const Icon(Icons.flag_outlined),
          tooltip: AppStrings.resign,
          color: AppColors.danger,
        ),
        IconButton(
          onPressed: onNew,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: AppStrings.newGame,
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Expanded(
      child: Material(
        color: enabled ? AppColors.surfaceVariant : AppColors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: enabled ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawOfferBanner extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _DrawOfferBanner({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            'Draw offered',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: const Color(0xFF121212),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text(AppStrings.acceptDraw,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text(AppStrings.declineDraw,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
