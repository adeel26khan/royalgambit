import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

/// Board utility functions and initial board setup.
/// Board[0][0] = a8 (black's queenside rook), Board[7][7] = h1 (white's kingside rook).
class Board {
  Board._();

  /// Create the standard initial chess position.
  static List<List<Piece?>> initialBoard() {
    final board = List.generate(8, (_) => List<Piece?>.filled(8, null));

    // Black pieces (top)
    board[0][0] = const Piece(PieceType.rook, PieceColor.black);
    board[0][1] = const Piece(PieceType.knight, PieceColor.black);
    board[0][2] = const Piece(PieceType.bishop, PieceColor.black);
    board[0][3] = const Piece(PieceType.queen, PieceColor.black);
    board[0][4] = const Piece(PieceType.king, PieceColor.black);
    board[0][5] = const Piece(PieceType.bishop, PieceColor.black);
    board[0][6] = const Piece(PieceType.knight, PieceColor.black);
    board[0][7] = const Piece(PieceType.rook, PieceColor.black);
    for (int c = 0; c < 8; c++) {
      board[1][c] = const Piece(PieceType.pawn, PieceColor.black);
    }

    // White pieces (bottom)
    board[7][0] = const Piece(PieceType.rook, PieceColor.white);
    board[7][1] = const Piece(PieceType.knight, PieceColor.white);
    board[7][2] = const Piece(PieceType.bishop, PieceColor.white);
    board[7][3] = const Piece(PieceType.queen, PieceColor.white);
    board[7][4] = const Piece(PieceType.king, PieceColor.white);
    board[7][5] = const Piece(PieceType.bishop, PieceColor.white);
    board[7][6] = const Piece(PieceType.knight, PieceColor.white);
    board[7][7] = const Piece(PieceType.rook, PieceColor.white);
    for (int c = 0; c < 8; c++) {
      board[6][c] = const Piece(PieceType.pawn, PieceColor.white);
    }

    return board;
  }

  /// Deep copy of a board
  static List<List<Piece?>> copyBoard(List<List<Piece?>> board) {
    return List.generate(8, (r) => List<Piece?>.from(board[r]));
  }

  /// Get piece at square
  static Piece? pieceAt(List<List<Piece?>> board, Square square) {
    return board[square.row][square.col];
  }

  /// Set piece at square
  static void setPiece(List<List<Piece?>> board, Square square, Piece? piece) {
    board[square.row][square.col] = piece;
  }

  /// Find the king's square for a given color
  static Square? findKing(List<List<Piece?>> board, PieceColor color) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = board[r][c];
        if (p != null && p.type == PieceType.king && p.color == color) {
          return Square(r, c);
        }
      }
    }
    return null;
  }

  /// Check if a square is within board bounds
  static bool inBounds(int row, int col) =>
      row >= 0 && row < 8 && col >= 0 && col < 8;
}
