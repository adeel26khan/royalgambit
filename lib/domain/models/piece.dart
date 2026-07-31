enum PieceType { pawn, knight, bishop, rook, queen, king }

enum PieceColor { white, black }

class Piece {
  final PieceType type;
  final PieceColor color;

  const Piece(this.type, this.color);

  /// Centipawn value for evaluation
  int get value {
    switch (type) {
      case PieceType.pawn:
        return 100;
      case PieceType.knight:
        return 320;
      case PieceType.bishop:
        return 330;
      case PieceType.rook:
        return 500;
      case PieceType.queen:
        return 900;
      case PieceType.king:
        return 20000;
    }
  }

  /// Display value (whole number)
  int get displayValue {
    switch (type) {
      case PieceType.pawn:
        return 1;
      case PieceType.knight:
        return 3;
      case PieceType.bishop:
        return 3;
      case PieceType.rook:
        return 5;
      case PieceType.queen:
        return 9;
      case PieceType.king:
        return 0;
    }
  }

  /// FEN character representation
  String get fenChar {
    final chars = {
      PieceType.pawn: 'p',
      PieceType.knight: 'n',
      PieceType.bishop: 'b',
      PieceType.rook: 'r',
      PieceType.queen: 'q',
      PieceType.king: 'k',
    };
    final c = chars[type]!;
    return color == PieceColor.white ? c.toUpperCase() : c;
  }

  /// Short name for SAN notation
  String get sanChar {
    switch (type) {
      case PieceType.pawn:
        return '';
      case PieceType.knight:
        return 'N';
      case PieceType.bishop:
        return 'B';
      case PieceType.rook:
        return 'R';
      case PieceType.queen:
        return 'Q';
      case PieceType.king:
        return 'K';
    }
  }

  PieceColor get opponent =>
      color == PieceColor.white ? PieceColor.black : PieceColor.white;

  Piece copyWith({PieceType? type, PieceColor? color}) =>
      Piece(type ?? this.type, color ?? this.color);

  @override
  bool operator ==(Object other) =>
      other is Piece && other.type == type && other.color == color;

  @override
  int get hashCode => Object.hash(type, color);

  @override
  String toString() => fenChar;
}
