import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/domain/engine/board.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';
import 'package:royalgambit/presentation/providers/settings_provider.dart';
import 'package:royalgambit/presentation/widgets/board/board_square.dart';

class ChessBoard extends ConsumerWidget {
  final double size;

  const ChessBoard({super.key, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(gameProvider);
    final settings = ref.watch(settingsProvider);
    final game = appState.game;
    final isFlipped = game.boardFlipped;
    final squareSize = size / 8;

    final checkKingSquare = _findCheckKing(game);
    final boardTexturePath = _getBoardTexturePath(settings.boardTheme);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.accent.withOpacity(0.4),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            // Full Board Background Image rendered ONCE for the whole board
            Positioned.fill(
              child: Image.asset(
                boardTexturePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // 8x8 Grid of Squares
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
              ),
              itemCount: 64,
              itemBuilder: (ctx, index) {
                // Map grid index to board square based on flip state
                final displayRow = index ~/ 8;
                final displayCol = index % 8;
                final boardRow = isFlipped ? (7 - displayRow) : displayRow;
                final boardCol = isFlipped ? (7 - displayCol) : displayCol;
                final square = Square(boardRow, boardCol);

                final piece = Board.pieceAt(game.board, square);
                final isSelected = appState.selectedSquare == square;
                final isLegalMove = appState.legalMovesForSelected
                    .any((m) => m.to == square);
                final isLastMoveFrom = game.lastMove?.from == square;
                final isLastMoveTo = game.lastMove?.to == square;
                final isCheck = checkKingSquare == square;

                return BoardSquare(
                  key: ValueKey('$boardRow$boardCol'),
                  square: square,
                  isFlipped: isFlipped,
                  isSelected: isSelected,
                  isLegalMove: isLegalMove,
                  isLastMoveFrom: isLastMoveFrom,
                  isLastMoveTo: isLastMoveTo,
                  isCheck: isCheck,
                  piece: piece,
                  game: game,
                  squareSize: squareSize,
                  boardTheme: settings.boardTheme,
                  pieceTheme: settings.pieceTheme,
                  showCoordinates: settings.showCoordinates,
                  onTap: (sq) =>
                      ref.read(gameProvider.notifier).selectSquare(sq),
                  onDragStart: (sq) =>
                      ref.read(gameProvider.notifier).startDrag(sq),
                  onDrop: (sq) =>
                      ref.read(gameProvider.notifier).dropOnSquare(sq),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getBoardTexturePath(BoardTheme theme) {
    switch (theme) {
      case BoardTheme.walnut:
        return 'assets/board/wood.jpg';
      case BoardTheme.wood2:
        return 'assets/board/wood2.jpg';
      case BoardTheme.wood3:
        return 'assets/board/wood3.jpg';
      case BoardTheme.wood4:
        return 'assets/board/wood4.jpg';
      case BoardTheme.maple:
        return 'assets/board/maple.jpg';
      case BoardTheme.blue:
        return 'assets/board/blue.png';
      case BoardTheme.blueMarble:
        return 'assets/board/blue-marble.jpg';
      case BoardTheme.brown:
        return 'assets/board/brown.png';
      case BoardTheme.green:
        return 'assets/board/green.png';
      case BoardTheme.grey:
        return 'assets/board/grey.jpg';
      case BoardTheme.canvas:
        return 'assets/board/canvas2.jpg';
      case BoardTheme.leather:
        return 'assets/board/leather.jpg';
      case BoardTheme.marble:
        return 'assets/board/marble.jpg';
      case BoardTheme.metal:
        return 'assets/board/metal.jpg';
      case BoardTheme.purpleDiag:
        return 'assets/board/purple-diag.png';
    }
  }

  Square? _findCheckKing(GameState game) {
    if (game.status != GameStatus.check) return null;
    // Find the king of the current turn color
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = game.board[r][c];
        if (p != null &&
            p.type == PieceType.king &&
            p.color == game.currentTurn) {
          return Square(r, c);
        }
      }
    }
    return null;
  }
}
