import 'dart:math';

import 'package:royalgambit/domain/engine/move_generator.dart';
import 'package:royalgambit/domain/engine/validator.dart';
import 'package:royalgambit/domain/models/chess_move.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

// ─── Piece-Square Tables (white perspective; negate rows for black) ───────────

const _pawnTable = [
  [0, 0, 0, 0, 0, 0, 0, 0],
  [50, 50, 50, 50, 50, 50, 50, 50],
  [10, 10, 20, 30, 30, 20, 10, 10],
  [5, 5, 10, 25, 25, 10, 5, 5],
  [0, 0, 0, 20, 20, 0, 0, 0],
  [5, -5, -10, 0, 0, -10, -5, 5],
  [5, 10, 10, -20, -20, 10, 10, 5],
  [0, 0, 0, 0, 0, 0, 0, 0],
];

const _knightTable = [
  [-50, -40, -30, -30, -30, -30, -40, -50],
  [-40, -20, 0, 0, 0, 0, -20, -40],
  [-30, 0, 10, 15, 15, 10, 0, -30],
  [-30, 5, 15, 20, 20, 15, 5, -30],
  [-30, 0, 15, 20, 20, 15, 0, -30],
  [-30, 5, 10, 15, 15, 10, 5, -30],
  [-40, -20, 0, 5, 5, 0, -20, -40],
  [-50, -40, -30, -30, -30, -30, -40, -50],
];

const _bishopTable = [
  [-20, -10, -10, -10, -10, -10, -10, -20],
  [-10, 0, 0, 0, 0, 0, 0, -10],
  [-10, 0, 5, 10, 10, 5, 0, -10],
  [-10, 5, 5, 10, 10, 5, 5, -10],
  [-10, 0, 10, 10, 10, 10, 0, -10],
  [-10, 10, 10, 10, 10, 10, 10, -10],
  [-10, 5, 0, 0, 0, 0, 5, -10],
  [-20, -10, -10, -10, -10, -10, -10, -20],
];

const _rookTable = [
  [0, 0, 0, 0, 0, 0, 0, 0],
  [5, 10, 10, 10, 10, 10, 10, 5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [-5, 0, 0, 0, 0, 0, 0, -5],
  [0, 0, 0, 5, 5, 0, 0, 0],
];

const _queenTable = [
  [-20, -10, -10, -5, -5, -10, -10, -20],
  [-10, 0, 0, 0, 0, 0, 0, -10],
  [-10, 0, 5, 5, 5, 5, 0, -10],
  [-5, 0, 5, 5, 5, 5, 0, -5],
  [0, 0, 5, 5, 5, 5, 0, -5],
  [-10, 5, 5, 5, 5, 5, 0, -10],
  [-10, 0, 5, 0, 0, 0, 0, -10],
  [-20, -10, -10, -5, -5, -10, -10, -20],
];

const _kingMiddleTable = [
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-30, -40, -40, -50, -50, -40, -40, -30],
  [-20, -30, -30, -40, -40, -30, -30, -20],
  [-10, -20, -20, -20, -20, -20, -20, -10],
  [20, 20, 0, 0, 0, 0, 20, 20],
  [20, 30, 10, 0, 0, 10, 30, 20],
];

// ─── AI Engine ────────────────────────────────────────────────────────────────

class AiEngine {
  AiEngine._();

  static final _random = Random();

  /// Entry point for compute() — takes a serialized game state map.
  static ChessMove? findBestMoveFromMap(Map<String, dynamic> args) {
    final state = _deserializeState(args['state'] as Map<String, dynamic>);
    final difficulty = AiDifficulty.values[args['difficulty'] as int];
    return findBestMove(state, difficulty);
  }

  static ChessMove? findBestMove(GameState state, AiDifficulty difficulty) {
    final moves = MoveGenerator.generateLegalMoves(state, state.currentTurn);
    if (moves.isEmpty) return null;

    switch (difficulty) {
      case AiDifficulty.beginner:
        return _randomOrGreedy(state, moves);
      case AiDifficulty.intermediate:
        return _minimaxBest(state, moves, 3);
      case AiDifficulty.advanced:
        return _minimaxBest(state, moves, 4);
      case AiDifficulty.master:
        return _minimaxBest(state, moves, 5);
    }
  }

  // ─── Beginner: random move or greedy capture ─────────────────────────────

  static ChessMove _randomOrGreedy(GameState state, List<ChessMove> moves) {
    // 50% chance to play a greedy capture if available
    final captures = moves.where((m) => m.isCapture).toList();
    if (captures.isNotEmpty && _random.nextDouble() > 0.5) {
      captures.sort((a, b) =>
          (b.capturedPiece?.value ?? 0).compareTo(a.capturedPiece?.value ?? 0));
      return captures.first;
    }
    return moves[_random.nextInt(moves.length)];
  }

  // ─── Minimax with alpha-beta pruning ─────────────────────────────────────

  static ChessMove? _minimaxBest(
    GameState state,
    List<ChessMove> moves,
    int depth,
  ) {
    ChessMove? bestMove;
    int bestScore = state.currentTurn == PieceColor.white ? -999999 : 999999;
    final maximizing = state.currentTurn == PieceColor.white;

    // Order moves for better pruning (captures first)
    moves = _orderMoves(moves);

    for (final move in moves) {
      final newBoard = MoveGenerator.applyMoveToBoard(state.board, move);
      final newState = _quickState(state, newBoard, move);
      final score = _minimax(newState, depth - 1, -999999, 999999, !maximizing);
      if (maximizing ? score > bestScore : score < bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove;
  }

  static int _minimax(
    GameState state,
    int depth,
    int alpha,
    int beta,
    bool maximizing,
  ) {
    if (depth == 0) return _evaluate(state);

    final moves = MoveGenerator.generateLegalMoves(state, state.currentTurn);
    if (moves.isEmpty) {
      if (ChessValidator.isInCheck(state.board, state.currentTurn)) {
        return maximizing ? -50000 : 50000; // Checkmate
      }
      return 0; // Stalemate
    }

    final ordered = _orderMoves(moves);

    if (maximizing) {
      int maxEval = -999999;
      for (final move in ordered) {
        final newBoard = MoveGenerator.applyMoveToBoard(state.board, move);
        final newState = _quickState(state, newBoard, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, false);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999;
      for (final move in ordered) {
        final newBoard = MoveGenerator.applyMoveToBoard(state.board, move);
        final newState = _quickState(state, newBoard, move);
        final eval = _minimax(newState, depth - 1, alpha, beta, true);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  // ─── Move ordering for better alpha-beta pruning ──────────────────────────

  static List<ChessMove> _orderMoves(List<ChessMove> moves) {
    return [...moves]..sort((a, b) {
        int scoreA = 0, scoreB = 0;
        if (a.isCapture) scoreA += (a.capturedPiece?.value ?? 0) * 10;
        if (b.isCapture) scoreB += (b.capturedPiece?.value ?? 0) * 10;
        if (a.isPromotion) scoreA += 900;
        if (b.isPromotion) scoreB += 900;
        return scoreB.compareTo(scoreA);
      });
  }

  // ─── Position evaluation ──────────────────────────────────────────────────

  static int _evaluate(GameState state) {
    int score = 0;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = state.board[r][c];
        if (piece == null) continue;

        final isWhite = piece.color == PieceColor.white;
        final sign = isWhite ? 1 : -1;
        final tableRow = isWhite ? r : (7 - r);

        int pieceScore = piece.value;
        pieceScore += _getPieceSquareBonus(piece.type, tableRow, c);

        score += sign * pieceScore;
      }
    }

    return score;
  }

  static int _getPieceSquareBonus(PieceType type, int row, int col) {
    switch (type) {
      case PieceType.pawn:
        return _pawnTable[row][col];
      case PieceType.knight:
        return _knightTable[row][col];
      case PieceType.bishop:
        return _bishopTable[row][col];
      case PieceType.rook:
        return _rookTable[row][col];
      case PieceType.queen:
        return _queenTable[row][col];
      case PieceType.king:
        return _kingMiddleTable[row][col];
    }
  }

  // ─── Lightweight state for minimax (no full game tracking) ───────────────

  static GameState _quickState(
    GameState prev,
    List<List<Piece?>> board,
    ChessMove move,
  ) {
    final nextTurn = prev.currentTurn == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    // Update castling rights
    bool wk = prev.whiteKingsideCastle;
    bool wq = prev.whiteQueensideCastle;
    bool bk = prev.blackKingsideCastle;
    bool bq = prev.blackQueensideCastle;

    final movedPiece = prev.board[move.from.row][move.from.col];
    if (movedPiece?.type == PieceType.king) {
      if (movedPiece!.color == PieceColor.white) {
        wk = false;
        wq = false;
      } else {
        bk = false;
        bq = false;
      }
    }
    if (movedPiece?.type == PieceType.rook) {
      if (move.from == const Square(7, 7)) wk = false;
      if (move.from == const Square(7, 0)) wq = false;
      if (move.from == const Square(0, 7)) bk = false;
      if (move.from == const Square(0, 0)) bq = false;
    }

    // En passant target
    Square? ep;
    if (move.isDoublePawnPush) {
      ep = Square(
        (move.from.row + move.to.row) ~/ 2,
        move.from.col,
      );
    }

    return GameState(
      board: board,
      currentTurn: nextTurn,
      whiteKingsideCastle: wk,
      whiteQueensideCastle: wq,
      blackKingsideCastle: bk,
      blackQueensideCastle: bq,
      enPassantTarget: ep,
      halfMoveClock: (movedPiece?.type == PieceType.pawn || move.isCapture)
          ? 0
          : prev.halfMoveClock + 1,
      fullMoveNumber: prev.fullMoveNumber + (nextTurn == PieceColor.white ? 1 : 0),
    );
  }

  // ─── Serialization for compute() ─────────────────────────────────────────

  static Map<String, dynamic> serializeState(GameState state) {
    return {
      'board': List.generate(
        8,
        (r) => List.generate(8, (c) {
          final p = state.board[r][c];
          return p == null ? null : {'t': p.type.index, 'c': p.color.index};
        }),
      ),
      'turn': state.currentTurn.index,
      'wk': state.whiteKingsideCastle,
      'wq': state.whiteQueensideCastle,
      'bk': state.blackKingsideCastle,
      'bq': state.blackQueensideCastle,
      'ep': state.enPassantTarget == null
          ? null
          : [state.enPassantTarget!.row, state.enPassantTarget!.col],
      'hmc': state.halfMoveClock,
      'fmn': state.fullMoveNumber,
    };
  }

  static GameState _deserializeState(Map<String, dynamic> data) {
    final rawBoard = data['board'] as List;
    final board = List.generate(8, (r) {
      final row = rawBoard[r] as List;
      return List<Piece?>.generate(8, (c) {
        final p = row[c];
        if (p == null) return null;
        return Piece(
          PieceType.values[(p['t'] as int)],
          PieceColor.values[(p['c'] as int)],
        );
      });
    });

    final ep = data['ep'] as List?;
    return GameState(
      board: board,
      currentTurn: PieceColor.values[data['turn'] as int],
      whiteKingsideCastle: data['wk'] as bool,
      whiteQueensideCastle: data['wq'] as bool,
      blackKingsideCastle: data['bk'] as bool,
      blackQueensideCastle: data['bq'] as bool,
      enPassantTarget: ep == null ? null : Square(ep[0] as int, ep[1] as int),
      halfMoveClock: data['hmc'] as int,
      fullMoveNumber: data['fmn'] as int,
    );
  }
}

/// Top-level function for Flutter's compute() — must be a top-level function.
ChessMove? aiWorkerFindBestMove(Map<String, dynamic> args) {
  return AiEngine.findBestMoveFromMap(args);
}
