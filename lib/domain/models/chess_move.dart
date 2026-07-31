import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

enum MoveFlag {
  normal,
  doublePawnPush,
  enPassant,
  kingsideCastle,
  queensideCastle,
  promotion,
}

class ChessMove {
  final Square from;
  final Square to;
  final Piece? capturedPiece;
  final PieceType? promotionPiece; // Queen/Rook/Bishop/Knight
  final MoveFlag flag;
  String? san; // Set after move generation

  ChessMove({
    required this.from,
    required this.to,
    this.capturedPiece,
    this.promotionPiece,
    this.flag = MoveFlag.normal,
    this.san,
  });

  bool get isCapture => capturedPiece != null;
  bool get isCastling =>
      flag == MoveFlag.kingsideCastle || flag == MoveFlag.queensideCastle;
  bool get isEnPassant => flag == MoveFlag.enPassant;
  bool get isPromotion => flag == MoveFlag.promotion;
  bool get isDoublePawnPush => flag == MoveFlag.doublePawnPush;

  ChessMove copyWith({PieceType? promotionPiece, String? san}) {
    return ChessMove(
      from: from,
      to: to,
      capturedPiece: capturedPiece,
      promotionPiece: promotionPiece ?? this.promotionPiece,
      flag: flag,
      san: san ?? this.san,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChessMove &&
      other.from == from &&
      other.to == to &&
      other.promotionPiece == promotionPiece;

  @override
  int get hashCode => Object.hash(from, to, promotionPiece);

  @override
  String toString() => san ?? '${from.notation}${to.notation}';
}
