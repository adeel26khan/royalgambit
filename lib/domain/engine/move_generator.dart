import 'package:royalgambit/domain/engine/board.dart';
import 'package:royalgambit/domain/engine/validator.dart';
import 'package:royalgambit/domain/models/chess_move.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

class MoveGenerator {
  MoveGenerator._();

  /// Generate all pseudo-legal moves (may leave king in check).
  static List<ChessMove> generatePseudoLegalMoves(
    List<List<Piece?>> board,
    PieceColor color,
    bool wKingside,
    bool wQueenside,
    bool bKingside,
    bool bQueenside,
    Square? enPassantTarget,
  ) {
    final moves = <ChessMove>[];

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece == null || piece.color != color) continue;

        final from = Square(r, c);
        switch (piece.type) {
          case PieceType.pawn:
            moves.addAll(
              _pawnMoves(board, from, color, enPassantTarget),
            );
            break;
          case PieceType.knight:
            moves.addAll(_knightMoves(board, from, color));
            break;
          case PieceType.bishop:
            moves.addAll(_slidingMoves(board, from, color, true, false));
            break;
          case PieceType.rook:
            moves.addAll(_slidingMoves(board, from, color, false, true));
            break;
          case PieceType.queen:
            moves.addAll(_slidingMoves(board, from, color, true, true));
            break;
          case PieceType.king:
            moves.addAll(
              _kingMoves(
                board,
                from,
                color,
                wKingside,
                wQueenside,
                bKingside,
                bQueenside,
              ),
            );
            break;
        }
      }
    }

    return moves;
  }

  /// Generate all LEGAL moves for a color (filters out self-check).
  static List<ChessMove> generateLegalMoves(GameState state, PieceColor color) {
    final pseudo = generatePseudoLegalMoves(
      state.board,
      color,
      state.whiteKingsideCastle,
      state.whiteQueensideCastle,
      state.blackKingsideCastle,
      state.blackQueensideCastle,
      state.enPassantTarget,
    );

    return pseudo.where((move) {
      final testBoard = Board.copyBoard(state.board);
      _applyMoveOnBoard(testBoard, move);
      return !ChessValidator.isInCheck(testBoard, color);
    }).toList();
  }

  // ─── Pawn moves ───────────────────────────────────────────────────────────

  static List<ChessMove> _pawnMoves(
    List<List<Piece?>> board,
    Square from,
    PieceColor color,
    Square? enPassantTarget,
  ) {
    final moves = <ChessMove>[];
    final direction = color == PieceColor.white ? -1 : 1;
    final startRow = color == PieceColor.white ? 6 : 1;
    final promotionRow = color == PieceColor.white ? 0 : 7;

    // Single push
    final singleTo = Square(from.row + direction, from.col);
    if (Board.inBounds(singleTo.row, singleTo.col) &&
        board[singleTo.row][singleTo.col] == null) {
      if (singleTo.row == promotionRow) {
        moves.addAll(_promotionMoves(from, singleTo, null));
      } else {
        moves.add(ChessMove(from: from, to: singleTo));
      }

      // Double push from starting rank
      if (from.row == startRow) {
        final doubleTo = Square(from.row + 2 * direction, from.col);
        if (Board.inBounds(doubleTo.row, doubleTo.col) &&
            board[doubleTo.row][doubleTo.col] == null) {
          moves.add(ChessMove(
            from: from,
            to: doubleTo,
            flag: MoveFlag.doublePawnPush,
          ));
        }
      }
    }

    // Captures
    for (final dc in [-1, 1]) {
      final capTo = Square(from.row + direction, from.col + dc);
      if (!Board.inBounds(capTo.row, capTo.col)) continue;

      final target = board[capTo.row][capTo.col];
      if (target != null && target.color != color) {
        if (capTo.row == promotionRow) {
          moves.addAll(_promotionMoves(from, capTo, target));
        } else {
          moves.add(ChessMove(from: from, to: capTo, capturedPiece: target));
        }
      }

      // En passant
      if (enPassantTarget != null && capTo == enPassantTarget) {
        final capturedPawnSquare = Square(from.row, from.col + dc);
        final capturedPawn = board[capturedPawnSquare.row][capturedPawnSquare.col];
        moves.add(ChessMove(
          from: from,
          to: capTo,
          capturedPiece: capturedPawn,
          flag: MoveFlag.enPassant,
        ));
      }
    }

    return moves;
  }

  static List<ChessMove> _promotionMoves(
    Square from,
    Square to,
    Piece? captured,
  ) {
    return [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ].map((pt) => ChessMove(
          from: from,
          to: to,
          capturedPiece: captured,
          promotionPiece: pt,
          flag: MoveFlag.promotion,
        )).toList();
  }

  // ─── Knight moves ─────────────────────────────────────────────────────────

  static List<ChessMove> _knightMoves(
    List<List<Piece?>> board,
    Square from,
    PieceColor color,
  ) {
    const offsets = [
      (-2, -1), (-2, 1), (-1, -2), (-1, 2),
      (1, -2), (1, 2), (2, -1), (2, 1),
    ];
    final moves = <ChessMove>[];
    for (final (dr, dc) in offsets) {
      final to = Square(from.row + dr, from.col + dc);
      if (!Board.inBounds(to.row, to.col)) continue;
      final target = board[to.row][to.col];
      if (target == null) {
        moves.add(ChessMove(from: from, to: to));
      } else if (target.color != color) {
        moves.add(ChessMove(from: from, to: to, capturedPiece: target));
      }
    }
    return moves;
  }

  // ─── Sliding piece moves ──────────────────────────────────────────────────

  static List<ChessMove> _slidingMoves(
    List<List<Piece?>> board,
    Square from,
    PieceColor color,
    bool diagonal,
    bool straight,
  ) {
    final moves = <ChessMove>[];
    final dirs = <(int, int)>[];
    if (diagonal) dirs.addAll([(-1, -1), (-1, 1), (1, -1), (1, 1)]);
    if (straight) dirs.addAll([(-1, 0), (1, 0), (0, -1), (0, 1)]);

    for (final (dr, dc) in dirs) {
      int r = from.row + dr;
      int c = from.col + dc;
      while (Board.inBounds(r, c)) {
        final target = board[r][c];
        if (target == null) {
          moves.add(ChessMove(from: from, to: Square(r, c)));
        } else {
          if (target.color != color) {
            moves.add(ChessMove(
              from: from,
              to: Square(r, c),
              capturedPiece: target,
            ));
          }
          break; // Blocked
        }
        r += dr;
        c += dc;
      }
    }
    return moves;
  }

  // ─── King moves ───────────────────────────────────────────────────────────

  static List<ChessMove> _kingMoves(
    List<List<Piece?>> board,
    Square from,
    PieceColor color,
    bool wKingside,
    bool wQueenside,
    bool bKingside,
    bool bQueenside,
  ) {
    const offsets = [
      (-1, -1), (-1, 0), (-1, 1),
      (0, -1),           (0, 1),
      (1, -1),  (1, 0),  (1, 1),
    ];
    final moves = <ChessMove>[];

    // Normal king moves
    for (final (dr, dc) in offsets) {
      final to = Square(from.row + dr, from.col + dc);
      if (!Board.inBounds(to.row, to.col)) continue;
      final target = board[to.row][to.col];
      if (target == null) {
        moves.add(ChessMove(from: from, to: to));
      } else if (target.color != color) {
        moves.add(ChessMove(from: from, to: to, capturedPiece: target));
      }
    }

    // Castling
    if (color == PieceColor.white) {
      // Kingside: squares f1 (7,5) and g1 (7,6) must be empty
      if (wKingside &&
          board[7][5] == null &&
          board[7][6] == null) {
        moves.add(ChessMove(
          from: from,
          to: const Square(7, 6),
          flag: MoveFlag.kingsideCastle,
        ));
      }
      // Queenside: squares b1 (7,1), c1 (7,2), d1 (7,3) must be empty
      if (wQueenside &&
          board[7][1] == null &&
          board[7][2] == null &&
          board[7][3] == null) {
        moves.add(ChessMove(
          from: from,
          to: const Square(7, 2),
          flag: MoveFlag.queensideCastle,
        ));
      }
    } else {
      // Black kingside: squares f8 (0,5) and g8 (0,6)
      if (bKingside &&
          board[0][5] == null &&
          board[0][6] == null) {
        moves.add(ChessMove(
          from: from,
          to: const Square(0, 6),
          flag: MoveFlag.kingsideCastle,
        ));
      }
      // Black queenside: squares b8 (0,1), c8 (0,2), d8 (0,3)
      if (bQueenside &&
          board[0][1] == null &&
          board[0][2] == null &&
          board[0][3] == null) {
        moves.add(ChessMove(
          from: from,
          to: const Square(0, 2),
          flag: MoveFlag.queensideCastle,
        ));
      }
    }

    return moves;
  }

  // ─── Apply move on a board copy (for check detection) ────────────────────

  static void _applyMoveOnBoard(List<List<Piece?>> board, ChessMove move) {
    final piece = board[move.from.row][move.from.col];
    if (piece == null) return;

    // Handle special flags
    if (move.flag == MoveFlag.enPassant) {
      // Remove captured pawn (same row as from, same col as to)
      board[move.from.row][move.to.col] = null;
    } else if (move.flag == MoveFlag.kingsideCastle) {
      // Move rook
      final rookRow = move.from.row;
      board[rookRow][5] = board[rookRow][7];
      board[rookRow][7] = null;
    } else if (move.flag == MoveFlag.queensideCastle) {
      final rookRow = move.from.row;
      board[rookRow][3] = board[rookRow][0];
      board[rookRow][0] = null;
    }

    // Move piece
    board[move.to.row][move.to.col] =
        move.isPromotion ? Piece(move.promotionPiece!, piece.color) : piece;
    board[move.from.row][move.from.col] = null;
  }

  /// Apply a move to a board and return the new board (non-destructive).
  static List<List<Piece?>> applyMoveToBoard(
    List<List<Piece?>> board,
    ChessMove move,
  ) {
    final copy = Board.copyBoard(board);
    _applyMoveOnBoard(copy, move);
    return copy;
  }
}
