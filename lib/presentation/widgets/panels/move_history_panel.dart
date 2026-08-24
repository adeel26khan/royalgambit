import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';

class MoveHistoryPanel extends ConsumerWidget {
  final bool showHeader;

  const MoveHistoryPanel({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider).game;
    final moves = game.moveHistory;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.moveHistory,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy PGN',
                  onPressed: moves.isEmpty
                      ? null
                      : () {
                          final pgn = generatePgn(moves);
                          Clipboard.setData(ClipboardData(text: pgn));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PGN copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: moves.isEmpty
                ? Center(
                    child: Opacity(
                      opacity: 0.5,
                      child: Text(
                        'Game started. Make your first move.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  )
                : _MoveList(moves: moves),
          ),
        ],
      ),
    );
  }

  static String generatePgn(List<dynamic> moves) {
    final buffer = StringBuffer();
    for (int i = 0; i < moves.length; i += 2) {
      final moveNum = i ~/ 2 + 1;
      final white = moves[i].san ?? moves[i].toString();
      buffer.write('$moveNum. $white ');
      if (i + 1 < moves.length) {
        final black = moves[i + 1].san ?? moves[i + 1].toString();
        buffer.write('$black ');
      }
    }
    return buffer.toString().trim();
  }
}

class _MoveList extends StatefulWidget {
  final List<dynamic> moves;
  const _MoveList({required this.moves});

  @override
  State<_MoveList> createState() => _MoveListState();
}

class _MoveListState extends State<_MoveList> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_MoveList old) {
    super.didUpdateWidget(old);
    if (widget.moves.length != old.moves.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(int, String, String?)>[];
    for (int i = 0; i < widget.moves.length; i += 2) {
      final white = widget.moves[i].san ?? widget.moves[i].toString();
      final black = (i + 1 < widget.moves.length)
          ? (widget.moves[i + 1].san ?? widget.moves[i + 1].toString())
          : null;
      rows.add((i ~/ 2 + 1, white, black));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final (moveNum, white, black) = rows[i];
        final isLast = i == rows.length - 1;
        return _MoveRow(
          moveNumber: moveNum,
          whiteMove: white,
          blackMove: black,
          isHighlighted: isLast,
        );
      },
    );
  }
}

class _MoveRow extends StatelessWidget {
  final int moveNumber;
  final String whiteMove;
  final String? blackMove;
  final bool isHighlighted;

  const _MoveRow({
    required this.moveNumber,
    required this.whiteMove,
    this.blackMove,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '$moveNumber.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _MoveText(
              text: whiteMove,
              isHighlighted: isHighlighted && blackMove == null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: blackMove != null
                ? _MoveText(
                    text: blackMove!,
                    isHighlighted: isHighlighted,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MoveText extends StatelessWidget {
  final String text;
  final bool isHighlighted;

  const _MoveText({required this.text, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          color: isHighlighted ? const Color(0xFF121212) : AppColors.textPrimary,
        ),
      ),
    );
  }
}
