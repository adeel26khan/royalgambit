import 'package:royalgambit/domain/models/chess_move.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';

/// Converts chess moves to Standard Algebraic Notation (SAN).
class ChessNotation {
  ChessNotation._();

  static String moveToSan(
    List<List<Piece?>> boardBefore,
    ChessMove move,
    List<ChessMove> allLegalMoves,
    bool isCheck,
    bool isCheckmate,
  ) {
    final piece = boardBefore[move.from.row][move.from.col];
    if (piece == null) return '??';

    // Castling
    if (move.flag == MoveFlag.kingsideCastle) {
      return isCheckmate ? 'O-O#' : isCheck ? 'O-O+' : 'O-O';
    }
    if (move.flag == MoveFlag.queensideCastle) {
      return isCheckmate ? 'O-O-O#' : isCheck ? 'O-O-O+' : 'O-O-O';
    }

    final sb = StringBuffer();

    // Piece letter (not for pawns)
    if (piece.type != PieceType.pawn) {
      sb.write(piece.sanChar);
    }

    // Disambiguation
    if (piece.type != PieceType.pawn && piece.type != PieceType.king) {
      final ambiguous = allLegalMoves
          .where((m) =>
              m != move &&
              boardBefore[m.from.row][m.from.col]?.type == piece.type &&
              boardBefore[m.from.row][m.from.col]?.color == piece.color &&
              m.to == move.to)
          .toList();

      if (ambiguous.isNotEmpty) {
        final sameFile = ambiguous
            .any((m) => m.from.col == move.from.col);
        final sameRank = ambiguous
            .any((m) => m.from.row == move.from.row);
        if (!sameFile) {
          sb.write(move.from.file);
        } else if (!sameRank) {
          sb.write(move.from.rank);
        } else {
          sb.write(move.from.file);
          sb.write(move.from.rank);
        }
      }
    }

    // Pawn file on capture
    if (piece.type == PieceType.pawn && move.isCapture) {
      sb.write(move.from.file);
    }

    // Capture symbol
    if (move.isCapture) {
      sb.write('x');
    }

    // Destination square
    sb.write(move.to.notation);

    // En passant note
    if (move.flag == MoveFlag.enPassant) {
      sb.write(' e.p.');
    }

    // Promotion
    if (move.isPromotion && move.promotionPiece != null) {
      sb.write('=');
      sb.write(_pieceTypeSan(move.promotionPiece!));
    }

    // Check / Checkmate
    if (isCheckmate) {
      sb.write('#');
    } else if (isCheck) {
      sb.write('+');
    }

    return sb.toString();
  }

  static String _pieceTypeSan(PieceType type) {
    switch (type) {
      case PieceType.queen:
        return 'Q';
      case PieceType.rook:
        return 'R';
      case PieceType.bishop:
        return 'B';
      case PieceType.knight:
        return 'N';
      default:
        return '';
    }
  }

  /// Format move history as PGN string.
  static String toPgn(List<ChessMove> moves, {GameStatus? result}) {
    final sb = StringBuffer();
    for (int i = 0; i < moves.length; i++) {
      if (i % 2 == 0) {
        sb.write('${(i ~/ 2) + 1}. ');
      }
      sb.write(moves[i].san ?? moves[i].toString());
      sb.write(' ');
    }

    // Result
    if (result != null) {
      switch (result) {
        case GameStatus.checkmate:
          // depends on who moved last
          break;
        case GameStatus.drawByAgreement:
        case GameStatus.drawBy50Move:
        case GameStatus.drawByRepetition:
        case GameStatus.drawByInsufficientMaterial:
        case GameStatus.stalemate:
          sb.write('1/2-1/2');
          break;
        case GameStatus.whiteResigned:
          sb.write('0-1');
          break;
        case GameStatus.blackResigned:
          sb.write('1-0');
          break;
        default:
          sb.write('*');
      }
    }

    return sb.toString().trim();
  }
}
