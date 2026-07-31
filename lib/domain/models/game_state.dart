import 'package:royalgambit/domain/models/chess_move.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

enum GameStatus {
  playing,
  check,
  checkmate,
  stalemate,
  drawByRepetition,
  drawBy50Move,
  drawByInsufficientMaterial,
  drawByAgreement,
  whiteResigned,
  blackResigned,
}

enum GameMode { local2Player, vsComputer }

enum AiDifficulty { beginner, intermediate, advanced, master }

enum BoardTheme {
  walnut,
  wood2,
  wood3,
  wood4,
  maple,
  blue,
  blueMarble,
  brown,
  green,
  grey,
  canvas,
  leather,
  marble,
  metal,
  purpleDiag,
}

enum PieceTheme { alpha, totoy, fantasy, customSvg }

class GameState {
  final List<List<Piece?>> board;
  final PieceColor currentTurn;
  final bool whiteKingsideCastle;
  final bool whiteQueensideCastle;
  final bool blackKingsideCastle;
  final bool blackQueensideCastle;
  final Square? enPassantTarget;
  final int halfMoveClock; // 50-move rule
  final int fullMoveNumber;
  final GameStatus status;
  final List<ChessMove> moveHistory;
  final List<Piece> whiteCaptured;
  final List<Piece> blackCaptured;
  final List<String> positionHistory; // For threefold repetition
  final GameMode mode;
  final AiDifficulty difficulty;
  final bool boardFlipped;
  final bool drawOfferedByWhite;
  final bool drawOfferedByBlack;
  final ChessMove? lastMove;
  final PieceColor? humanColor; // In vsComputer mode

  const GameState({
    required this.board,
    required this.currentTurn,
    this.whiteKingsideCastle = true,
    this.whiteQueensideCastle = true,
    this.blackKingsideCastle = true,
    this.blackQueensideCastle = true,
    this.enPassantTarget,
    this.halfMoveClock = 0,
    this.fullMoveNumber = 1,
    this.status = GameStatus.playing,
    this.moveHistory = const [],
    this.whiteCaptured = const [],
    this.blackCaptured = const [],
    this.positionHistory = const [],
    this.mode = GameMode.local2Player,
    this.difficulty = AiDifficulty.intermediate,
    this.boardFlipped = false,
    this.drawOfferedByWhite = false,
    this.drawOfferedByBlack = false,
    this.lastMove,
    this.humanColor,
  });

  bool get isGameOver =>
      status != GameStatus.playing && status != GameStatus.check;

  bool get isWhiteTurn => currentTurn == PieceColor.white;

  /// Material advantage from white's perspective (display value)
  int get materialAdvantage {
    int white = whiteCaptured.fold(0, (sum, p) => sum + p.displayValue);
    int black = blackCaptured.fold(0, (sum, p) => sum + p.displayValue);
    return white - black;
  }

  /// Return the board position key for threefold repetition detection
  String positionKey() {
    final sb = StringBuffer();
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final p = board[r][c];
        sb.write(p?.fenChar ?? '.');
      }
    }
    sb.write(currentTurn == PieceColor.white ? 'w' : 'b');
    sb.write(whiteKingsideCastle ? 'K' : '-');
    sb.write(whiteQueensideCastle ? 'Q' : '-');
    sb.write(blackKingsideCastle ? 'k' : '-');
    sb.write(blackQueensideCastle ? 'q' : '-');
    sb.write(enPassantTarget?.notation ?? '-');
    return sb.toString();
  }

  GameState copyWith({
    List<List<Piece?>>? board,
    PieceColor? currentTurn,
    bool? whiteKingsideCastle,
    bool? whiteQueensideCastle,
    bool? blackKingsideCastle,
    bool? blackQueensideCastle,
    Square? enPassantTarget,
    bool clearEnPassant = false,
    int? halfMoveClock,
    int? fullMoveNumber,
    GameStatus? status,
    List<ChessMove>? moveHistory,
    List<Piece>? whiteCaptured,
    List<Piece>? blackCaptured,
    List<String>? positionHistory,
    GameMode? mode,
    AiDifficulty? difficulty,
    bool? boardFlipped,
    bool? drawOfferedByWhite,
    bool? drawOfferedByBlack,
    ChessMove? lastMove,
    bool clearLastMove = false,
    PieceColor? humanColor,
  }) {
    return GameState(
      board: board ?? this.board,
      currentTurn: currentTurn ?? this.currentTurn,
      whiteKingsideCastle: whiteKingsideCastle ?? this.whiteKingsideCastle,
      whiteQueensideCastle:
          whiteQueensideCastle ?? this.whiteQueensideCastle,
      blackKingsideCastle: blackKingsideCastle ?? this.blackKingsideCastle,
      blackQueensideCastle:
          blackQueensideCastle ?? this.blackQueensideCastle,
      enPassantTarget: clearEnPassant
          ? null
          : (enPassantTarget ?? this.enPassantTarget),
      halfMoveClock: halfMoveClock ?? this.halfMoveClock,
      fullMoveNumber: fullMoveNumber ?? this.fullMoveNumber,
      status: status ?? this.status,
      moveHistory: moveHistory ?? this.moveHistory,
      whiteCaptured: whiteCaptured ?? this.whiteCaptured,
      blackCaptured: blackCaptured ?? this.blackCaptured,
      positionHistory: positionHistory ?? this.positionHistory,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      boardFlipped: boardFlipped ?? this.boardFlipped,
      drawOfferedByWhite: drawOfferedByWhite ?? this.drawOfferedByWhite,
      drawOfferedByBlack: drawOfferedByBlack ?? this.drawOfferedByBlack,
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
      humanColor: humanColor ?? this.humanColor,
    );
  }
}
