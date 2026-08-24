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

    // ─── 1. Opening Book for Early Game ─────────────────────────────────────
    if (state.fullMoveNumber <= 3) {
      final bookMove = _getOpeningBookMove(state, moves);
      if (bookMove != null) return bookMove;
    }

    switch (difficulty) {
      case AiDifficulty.beginner:
        return _randomOrGreedy(state, moves);
      case AiDifficulty.intermediate:
        return _minimaxBest(state, moves, 3, maxQuiescence: 2);
      case AiDifficulty.advanced:
        return _minimaxBest(state, moves, 4, maxQuiescence: 3);
      case AiDifficulty.master:
        return _minimaxBest(state, moves, 5, maxQuiescence: 4);
    }
  }

  // ─── Opening Book Implementation ─────────────────────────────────────────

  static ChessMove? _getOpeningBookMove(GameState state, List<ChessMove> moves) {
    final turn = state.currentTurn;

    if (turn == PieceColor.white && state.fullMoveNumber == 1) {
      // White 1st move options: 1.e4 (50%), 1.d4 (35%), 1.Nf3 (15%)
      final roll = _random.nextDouble();
      Square targetSquare;
      if (roll < 0.50) {
        targetSquare = const Square(4, 4); // e4
      } else if (roll < 0.85) {
        targetSquare = const Square(4, 3); // d4
      } else {
        targetSquare = const Square(5, 5); // Nf3
      }
      final candidate = moves.where((m) => m.to == targetSquare).toList();
      if (candidate.isNotEmpty) return candidate[_random.nextInt(candidate.length)];
    }

    if (turn == PieceColor.black && state.fullMoveNumber == 1) {
      // Black 1st move responses vs e4 or d4
      final last = state.lastMove;
      if (last != null) {
        if (last.to == const Square(4, 4)) {
          // Response to 1.e4 -> 1...e5 (40%), 1...c5 (40%), 1...e6 (20%)
          final roll = _random.nextDouble();
          Square target;
          if (roll < 0.40) {
            target = const Square(3, 4); // e5
          } else if (roll < 0.80) {
            target = const Square(3, 2); // c5
          } else {
            target = const Square(2, 4); // e6
          }
          final candidate = moves.where((m) => m.to == target).toList();
          if (candidate.isNotEmpty) return candidate[_random.nextInt(candidate.length)];
        } else if (last.to == const Square(4, 3)) {
          // Response to 1.d4 -> 1...d5 (50%), 1...Nf6 (50%)
          final roll = _random.nextDouble();
          Square target = roll < 0.50 ? const Square(3, 3) : const Square(2, 5);
          final candidate = moves.where((m) => m.to == target).toList();
          if (candidate.isNotEmpty) return candidate[_random.nextInt(candidate.length)];
        }
      }
    }

    return null;
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

  // ─── Minimax with alpha-beta pruning & randomized tie-breaking ─────────

  static ChessMove? _minimaxBest(
    GameState state,
    List<ChessMove> moves,
    int depth, {
    required int maxQuiescence,
  }) {
    final ordered = _orderMoves(moves);
    final maximizing = state.currentTurn == PieceColor.white;

    final moveScores = <(ChessMove, int)>[];

    for (final move in ordered) {
      final newBoard = MoveGenerator.applyMoveToBoard(state.board, move);
      final newState = _quickState(state, newBoard, move);
      final score = _minimax(
        newState,
        depth - 1,
        -999999,
        999999,
        !maximizing,
        maxQuiescence,
      );
      moveScores.add((move, score));
    }

    if (moveScores.isEmpty) return null;

    // Determine best score
    moveScores.sort((a, b) => maximizing
        ? b.$2.compareTo(a.$2)
        : a.$2.compareTo(b.$2));

    final bestScore = moveScores.first.$2;

    // Tie-breaking: Pick randomly from top moves scoring within 12 points of best score
    final topCandidates = moveScores.where((item) {
      final diff = (item.$2 - bestScore).abs();
      return diff <= 12;
    }).map((item) => item.$1).toList();

    return topCandidates[_random.nextInt(topCandidates.length)];
  }

  static int _minimax(
    GameState state,
    int depth,
    int alpha,
    int beta,
    bool maximizing,
    int maxQuiescence,
  ) {
    if (depth == 0) {
      return _quiescenceSearch(state, alpha, beta, maximizing, maxQuiescence);
    }

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
        final eval = _minimax(newState, depth - 1, alpha, beta, false, maxQuiescence);
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
        final eval = _minimax(newState, depth - 1, alpha, beta, true, maxQuiescence);
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  // ─── Quiescence Search (Solves Horizon Effect / Blunders) ────────────────

  static int _quiescenceSearch(
    GameState state,
    int alpha,
    int beta,
    bool maximizing,
    int qDepth,
  ) {
    final standPat = _evaluate(state);

    if (qDepth <= 0) return standPat;

    if (maximizing) {
      if (standPat >= beta) return beta;
      if (standPat > alpha) alpha = standPat;
    } else {
      if (standPat <= alpha) return alpha;
      if (standPat < beta) beta = standPat;
    }

    final moves = MoveGenerator.generateLegalMoves(state, state.currentTurn);
    final captures = _orderMoves(moves.where((m) => m.isCapture).toList());

    if (captures.isEmpty) return standPat;

    if (maximizing) {
      int maxEval = standPat;
      for (final capture in captures) {
        final newBoard = MoveGenerator.applyMoveToBoard(state.board, capture);
        final newState = _quickState(state, newBoard, capture);
        final eval = _quiescenceSearch(newState, alpha, beta, false, qDepth - 1);
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = standPat;
      for (final capture in captures) {
        final newBoard = MoveGenerator.applyMoveToBoard(state.board, capture);
        final newState = _quickState(state, newBoard, capture);
        final eval = _quiescenceSearch(newState, alpha, beta, true, qDepth - 1);
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
        if (a.isCapture) {
          final victimValue = a.capturedPiece?.value ?? 0;
          scoreA += victimValue * 10;
        }
        if (b.isCapture) {
          final victimValue = b.capturedPiece?.value ?? 0;
          scoreB += victimValue * 10;
        }
        if (a.isPromotion) scoreA += 900;
        if (b.isPromotion) scoreB += 900;
        return scoreB.compareTo(scoreA);
      });
  }


  // ─── Advanced Position Evaluation ─────────────────────────────────────────

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

        // Center control bonus for pawns and knights
        if ((r == 3 || r == 4) && (c == 3 || c == 4)) {
          if (piece.type == PieceType.pawn || piece.type == PieceType.knight) {
            pieceScore += 15;
          }
        }

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
      lastMove: move,
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

