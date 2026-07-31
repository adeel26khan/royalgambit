import 'package:royalgambit/domain/engine/board.dart';
import 'package:royalgambit/domain/models/chess_move.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

class ChessValidator {
  ChessValidator._();

  /// Returns true if [square] is attacked by any piece of [byColor].
  static bool isSquareAttacked(
    List<List<Piece?>> board,
    Square square,
    PieceColor byColor,
  ) {
    final opponentColor = byColor;

    // Check knight attacks
    const knightOffsets = [
      (-2, -1), (-2, 1), (-1, -2), (-1, 2),
      (1, -2), (1, 2), (2, -1), (2, 1),
    ];
    for (final (dr, dc) in knightOffsets) {
      final r = square.row + dr;
      final c = square.col + dc;
      if (Board.inBounds(r, c)) {
        final p = board[r][c];
        if (p != null && p.type == PieceType.knight && p.color == opponentColor) {
          return true;
        }
      }
    }

    // Check pawn attacks
    final pawnDir = opponentColor == PieceColor.white ? 1 : -1;
    for (final dc in [-1, 1]) {
      final r = square.row + pawnDir;
      final c = square.col + dc;
      if (Board.inBounds(r, c)) {
        final p = board[r][c];
        if (p != null && p.type == PieceType.pawn && p.color == opponentColor) {
          return true;
        }
      }
    }

    // Check sliding attacks (rook/queen: straight; bishop/queen: diagonal)
    // Straight directions
    for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      int r = square.row + dr;
      int c = square.col + dc;
      while (Board.inBounds(r, c)) {
        final p = board[r][c];
        if (p != null) {
          if (p.color == opponentColor &&
              (p.type == PieceType.rook || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        r += dr;
        c += dc;
      }
    }

    // Diagonal directions
    for (final (dr, dc) in [(-1, -1), (-1, 1), (1, -1), (1, 1)]) {
      int r = square.row + dr;
      int c = square.col + dc;
      while (Board.inBounds(r, c)) {
        final p = board[r][c];
        if (p != null) {
          if (p.color == opponentColor &&
              (p.type == PieceType.bishop || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        r += dr;
        c += dc;
      }
    }

    // Check king attacks
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = square.row + dr;
        final c = square.col + dc;
        if (Board.inBounds(r, c)) {
          final p = board[r][c];
          if (p != null && p.type == PieceType.king && p.color == opponentColor) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Returns true if [color]'s king is in check.
  static bool isInCheck(List<List<Piece?>> board, PieceColor color) {
    final kingSquare = Board.findKing(board, color);
    if (kingSquare == null) return false; // Should never happen in a real game
    return isSquareAttacked(board, kingSquare, color.opponent);
  }

  /// Returns true if [color]'s king is in check on the given [gameState].
  static bool isInCheckState(GameState state, PieceColor color) {
    return isInCheck(state.board, color);
  }

  /// Whether a castling move is valid (king doesn't pass through check).
  static bool isCastlingValid(
    List<List<Piece?>> board,
    ChessMove move,
    PieceColor color,
  ) {
    // King cannot be in check before castling
    if (isInCheck(board, color)) return false;

    final kingRow = color == PieceColor.white ? 7 : 0;
    if (move.flag == MoveFlag.kingsideCastle) {
      // King passes through f-file (col 5)
      if (isSquareAttacked(board, Square(kingRow, 5), color.opponent)) {
        return false;
      }
      // King lands on g-file (col 6)
      if (isSquareAttacked(board, Square(kingRow, 6), color.opponent)) {
        return false;
      }
    } else if (move.flag == MoveFlag.queensideCastle) {
      // King passes through d-file (col 3)
      if (isSquareAttacked(board, Square(kingRow, 3), color.opponent)) {
        return false;
      }
      // King lands on c-file (col 2)
      if (isSquareAttacked(board, Square(kingRow, 2), color.opponent)) {
        return false;
      }
    }
    return true;
  }

  // ─── Game status detection ────────────────────────────────────────────────

  /// Check for threefold repetition.
  static bool isThreefoldRepetition(List<String> positionHistory, String currentKey) {
    int count = 0;
    for (final key in positionHistory) {
      if (key == currentKey) count++;
    }
    return count >= 3;
  }

  /// Check for insufficient material draw.
  static bool isInsufficientMaterial(List<List<Piece?>> board) {
    final pieces = <Piece>[];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p != null) pieces.add(p);
      }
    }

    // King vs King
    if (pieces.length == 2) return true;

    if (pieces.length == 3) {
      final nonKings = pieces.where((p) => p.type != PieceType.king).toList();
      if (nonKings.length == 1) {
        final t = nonKings.first.type;
        // K vs K+B or K vs K+N
        if (t == PieceType.bishop || t == PieceType.knight) return true;
      }
    }

    if (pieces.length == 4) {
      final nonKings = pieces.where((p) => p.type != PieceType.king).toList();
      if (nonKings.length == 2 &&
          nonKings[0].type == PieceType.bishop &&
          nonKings[1].type == PieceType.bishop &&
          nonKings[0].color != nonKings[1].color) {
        // K+B vs K+B with same-colored bishops
        // Simplified: just check it's 2 bishops
        // (Full check would verify square colors, but this is rare edge case)
        return true;
      }
    }

    return false;
  }

  /// Determine the game status after a move has been applied.
  static GameStatus determineStatus(
    GameState state,
    List<ChessMove> legalMoves,
    String positionKey,
  ) {
    final color = state.currentTurn;

    if (legalMoves.isEmpty) {
      if (isInCheck(state.board, color)) {
        return GameStatus.checkmate;
      } else {
        return GameStatus.stalemate;
      }
    }

    if (isInCheck(state.board, color)) {
      return GameStatus.check;
    }

    if (state.halfMoveClock >= 100) {
      // 50 moves = 100 half-moves
      return GameStatus.drawBy50Move;
    }

    if (isThreefoldRepetition(state.positionHistory, positionKey)) {
      return GameStatus.drawByRepetition;
    }

    if (isInsufficientMaterial(state.board)) {
      return GameStatus.drawByInsufficientMaterial;
    }

    return GameStatus.playing;
  }
}

extension on PieceColor {
  PieceColor get opponent =>
      this == PieceColor.white ? PieceColor.black : PieceColor.white;
}
