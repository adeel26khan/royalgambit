/// Represents a square on the chess board.
/// [row] 0 = rank 8 (black's back rank), [row] 7 = rank 1 (white's back rank).
/// [col] 0 = file 'a', [col] 7 = file 'h'.
class Square {
  final int row;
  final int col;

  const Square(this.row, this.col);

  bool get isValid => row >= 0 && row < 8 && col >= 0 && col < 8;

  /// Algebraic file letter: 'a' – 'h'
  String get file => String.fromCharCode('a'.codeUnitAt(0) + col);

  /// Algebraic rank number: '1' – '8'
  String get rank => (8 - row).toString();

  /// Algebraic notation: e.g. 'e4', 'a1'
  String get notation => '$file$rank';

  /// Parse algebraic notation to Square
  static Square fromNotation(String notation) {
    assert(notation.length == 2);
    final col = notation.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(notation[1]);
    return Square(row, col);
  }

  Square operator +(Square other) => Square(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      other is Square && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => notation;
}
