import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/utils/sound_service.dart';
import 'package:royalgambit/domain/engine/ai_engine.dart';
import 'package:royalgambit/domain/engine/board.dart';
import 'package:royalgambit/domain/engine/move_generator.dart';
import 'package:royalgambit/domain/engine/notation.dart';
import 'package:royalgambit/domain/engine/validator.dart';
import 'package:royalgambit/domain/models/chess_move.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

// ─── App-level state that the UI sees ────────────────────────────────────────

class AppGameState {
  final GameState game;
  final Square? selectedSquare;
  final List<ChessMove> legalMovesForSelected;
  final bool isAiThinking;
  final List<GameState> undoStack; // full states for undo
  final List<GameState> redoStack;
  final ChessMove? pendingPromotion; // awaiting user choice

  const AppGameState({
    required this.game,
    this.selectedSquare,
    this.legalMovesForSelected = const [],
    this.isAiThinking = false,
    this.undoStack = const [],
    this.redoStack = const [],
    this.pendingPromotion,
  });

  AppGameState copyWith({
    GameState? game,
    Square? selectedSquare,
    bool clearSelection = false,
    List<ChessMove>? legalMovesForSelected,
    bool? isAiThinking,
    List<GameState>? undoStack,
    List<GameState>? redoStack,
    ChessMove? pendingPromotion,
    bool clearPendingPromotion = false,
  }) {
    return AppGameState(
      game: game ?? this.game,
      selectedSquare: clearSelection ? null : (selectedSquare ?? this.selectedSquare),
      legalMovesForSelected: clearSelection
          ? const []
          : (legalMovesForSelected ?? this.legalMovesForSelected),
      isAiThinking: isAiThinking ?? this.isAiThinking,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      pendingPromotion: clearPendingPromotion
          ? null
          : (pendingPromotion ?? this.pendingPromotion),
    );
  }
}

// ─── Game Notifier ───────────────────────────────────────────────────────────

class GameNotifier extends StateNotifier<AppGameState> {
  GameNotifier()
      : super(AppGameState(
          game: _buildInitialState(GameMode.local2Player, AiDifficulty.intermediate),
        ));

  // ─── Start new game ───────────────────────────────────────────────────────

  void startNewGame({
    required GameMode mode,
    required AiDifficulty difficulty,
    PieceColor humanColor = PieceColor.white,
  }) {
    final initial = _buildInitialState(mode, difficulty).copyWith(
      humanColor: humanColor,
    );
    state = AppGameState(game: initial);

    // If AI plays white, trigger AI first move
    if (mode == GameMode.vsComputer && humanColor == PieceColor.black) {
      _triggerAi(initial);
    }
  }

  static GameState _buildInitialState(GameMode mode, AiDifficulty difficulty) {
    final board = Board.initialBoard();
    return GameState(
      board: board,
      currentTurn: PieceColor.white,
      mode: mode,
      difficulty: difficulty,
      positionHistory: [],
      moveHistory: [],
      whiteCaptured: [],
      blackCaptured: [],
    );
  }

  // ─── Square selection / click-to-move ────────────────────────────────────

  void selectSquare(Square square) {
    final game = state.game;

    if (game.isGameOver || state.isAiThinking) return;

    // In vs computer, ignore clicks when it's AI's turn
    if (game.mode == GameMode.vsComputer) {
      final humanColor = game.humanColor ?? PieceColor.white;
      if (game.currentTurn != humanColor) return;
    }

    final piece = Board.pieceAt(game.board, square);

    // If a piece is already selected
    if (state.selectedSquare != null) {
      final legalMoves = state.legalMovesForSelected;

      // Find if the tapped square is a legal destination
      final matchingMoves = legalMoves
          .where((m) => m.to == square)
          .toList();

      if (matchingMoves.isNotEmpty) {
        // Check if it's a promotion
        final isPromotion = matchingMoves.any((m) => m.isPromotion);
        if (isPromotion) {
          // Show promotion dialog — store pending promotion with queen default
          state = state.copyWith(
            pendingPromotion: matchingMoves.first,
          );
          return;
        }
        // Execute the move
        _executeMove(matchingMoves.first);
        return;
      }

      // Clicked on own piece: switch selection
      if (piece != null && piece.color == game.currentTurn) {
        _selectPiece(square, piece);
        return;
      }

      // Clicked elsewhere: deselect
      state = state.copyWith(clearSelection: true);
      return;
    }

    // No piece selected yet — select if it's current player's piece
    if (piece != null && piece.color == game.currentTurn) {
      _selectPiece(square, piece);
    }
  }

  void _selectPiece(Square square, Piece piece) {
    final legalMoves = MoveGenerator.generateLegalMoves(
      state.game,
      state.game.currentTurn,
    ).where((m) => m.from == square).toList();

    state = state.copyWith(
      selectedSquare: square,
      legalMovesForSelected: legalMoves,
    );
  }

  // ─── Confirm promotion piece ──────────────────────────────────────────────

  void confirmPromotion(PieceType promotionPiece) {
    final pending = state.pendingPromotion;
    if (pending == null) return;

    final allLegalPromos = MoveGenerator.generateLegalMoves(
      state.game,
      state.game.currentTurn,
    ).where((m) => m.from == pending.from && m.to == pending.to).toList();

    final chosen = allLegalPromos.firstWhere(
      (m) => m.promotionPiece == promotionPiece,
      orElse: () => allLegalPromos.first,
    );

    state = state.copyWith(clearPendingPromotion: true);
    _executeMove(chosen);
  }

  // ─── Execute a move ───────────────────────────────────────────────────────

  void _executeMove(ChessMove move) {
    final prevGame = state.game;
    final newGame = _applyMove(prevGame, move);

    // Push to undo stack
    final newUndoStack = [...state.undoStack, prevGame];
    final newRedoStack = <GameState>[];

    state = state.copyWith(
      game: newGame,
      clearSelection: true,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );

    // Play sound effect
    if (newGame.status == GameStatus.check ||
        newGame.status == GameStatus.checkmate) {
      SoundService().play(SoundEffect.check);
    } else if (move.isCapture) {
      SoundService().play(SoundEffect.capture);
    } else {
      SoundService().play(SoundEffect.move);
    }

    // Trigger AI if needed
    if (!newGame.isGameOver &&
        newGame.mode == GameMode.vsComputer &&
        newGame.currentTurn != (newGame.humanColor ?? PieceColor.white)) {
      _triggerAi(newGame);
    }
  }

  static GameState _applyMove(GameState prev, ChessMove move) {
    final newBoard = MoveGenerator.applyMoveToBoard(prev.board, move);
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
    // If rook is captured
    if (move.to == const Square(7, 7)) wk = false;
    if (move.to == const Square(7, 0)) wq = false;
    if (move.to == const Square(0, 7)) bk = false;
    if (move.to == const Square(0, 0)) bq = false;

    // En passant target
    Square? ep;
    if (move.isDoublePawnPush) {
      ep = Square(
        (move.from.row + move.to.row) ~/ 2,
        move.from.col,
      );
    }

    // Update captured pieces
    List<Piece> whiteCaptured = [...prev.whiteCaptured];
    List<Piece> blackCaptured = [...prev.blackCaptured];
    if (move.capturedPiece != null) {
      if (prev.currentTurn == PieceColor.white) {
        whiteCaptured = [...whiteCaptured, move.capturedPiece!];
      } else {
        blackCaptured = [...blackCaptured, move.capturedPiece!];
      }
    }

    // Half-move clock
    final newHalfMove =
        (movedPiece?.type == PieceType.pawn || move.isCapture)
            ? 0
            : prev.halfMoveClock + 1;

    // Full move number
    final newFullMove = prev.fullMoveNumber +
        (nextTurn == PieceColor.white ? 1 : 0);

    // Provisional state (without status)
    final provisional = GameState(
      board: newBoard,
      currentTurn: nextTurn,
      whiteKingsideCastle: wk,
      whiteQueensideCastle: wq,
      blackKingsideCastle: bk,
      blackQueensideCastle: bq,
      enPassantTarget: ep,
      halfMoveClock: newHalfMove,
      fullMoveNumber: newFullMove,
      moveHistory: [...prev.moveHistory, move],
      whiteCaptured: whiteCaptured,
      blackCaptured: blackCaptured,
      positionHistory: [...prev.positionHistory],
      mode: prev.mode,
      difficulty: prev.difficulty,
      boardFlipped: prev.boardFlipped,
      humanColor: prev.humanColor,
      lastMove: move,
    );

    // Generate legal moves for next player to determine game status
    final legalMoves = MoveGenerator.generateLegalMoves(provisional, nextTurn);
    final posKey = provisional.positionKey();
    final updatedPositionHistory = [...provisional.positionHistory, posKey];
    final status = ChessValidator.determineStatus(
      provisional.copyWith(positionHistory: updatedPositionHistory),
      legalMoves,
      posKey,
    );

    // Generate SAN for the move that was made
    final allPrevLegal = MoveGenerator.generateLegalMoves(prev, prev.currentTurn);
    final isCheck = status == GameStatus.check;
    final isCheckmate = status == GameStatus.checkmate;
    final san = ChessNotation.moveToSan(
      prev.board,
      move,
      allPrevLegal,
      isCheck,
      isCheckmate,
    );
    move.san = san;

    return provisional.copyWith(
      status: status,
      positionHistory: updatedPositionHistory,
    );
  }

  // ─── AI trigger ───────────────────────────────────────────────────────────

  void _triggerAi(GameState game) {
    state = state.copyWith(isAiThinking: true);

    final serialized = AiEngine.serializeState(game);
    compute(aiWorkerFindBestMove, {
      'state': serialized,
      'difficulty': game.difficulty.index,
    }).then((bestMove) {
      if (!mounted) return;

      state = state.copyWith(isAiThinking: false);

      if (bestMove != null && !state.game.isGameOver) {
        _executeMove(bestMove);
      }
    }).catchError((_) {
      if (mounted) {
        state = state.copyWith(isAiThinking: false);
      }
    });
  }

  // ─── Undo ─────────────────────────────────────────────────────────────────

  void undo() {
    if (state.undoStack.isEmpty) return;
    if (state.game.mode == GameMode.vsComputer) {
      // Undo 2 half-moves in vs computer (player move + AI move)
      _undoOnce();
      if (state.undoStack.isNotEmpty) _undoOnce();
      return;
    }
    _undoOnce();
  }

  void _undoOnce() {
    if (state.undoStack.isEmpty) return;
    final prevGame = state.undoStack.last;
    final newUndoStack = state.undoStack.sublist(0, state.undoStack.length - 1);
    final newRedoStack = [state.game, ...state.redoStack];
    state = state.copyWith(
      game: prevGame,
      clearSelection: true,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final nextGame = state.redoStack.first;
    final newRedoStack = state.redoStack.sublist(1);
    final newUndoStack = [...state.undoStack, state.game];
    state = state.copyWith(
      game: nextGame,
      clearSelection: true,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );
  }

  // ─── Game actions ─────────────────────────────────────────────────────────

  void resign() {
    final resigner = state.game.currentTurn;
    final newStatus = resigner == PieceColor.white
        ? GameStatus.whiteResigned
        : GameStatus.blackResigned;
    state = state.copyWith(
      game: state.game.copyWith(status: newStatus),
      clearSelection: true,
    );
  }

  void offerDraw() {
    final offerer = state.game.currentTurn;
    if (offerer == PieceColor.white) {
      state = state.copyWith(
        game: state.game.copyWith(drawOfferedByWhite: true),
      );
    } else {
      state = state.copyWith(
        game: state.game.copyWith(drawOfferedByBlack: true),
      );
    }

    // In vs computer mode, AI always accepts draws ≥ depth 0 if position is equal
    if (state.game.mode == GameMode.vsComputer) {
      acceptDraw();
    }
  }

  void acceptDraw() {
    state = state.copyWith(
      game: state.game.copyWith(status: GameStatus.drawByAgreement),
      clearSelection: true,
    );
  }

  void declineDraw() {
    state = state.copyWith(
      game: state.game.copyWith(
        drawOfferedByWhite: false,
        drawOfferedByBlack: false,
      ),
    );
  }

  void flipBoard() {
    state = state.copyWith(
      game: state.game.copyWith(boardFlipped: !state.game.boardFlipped),
    );
  }

  void onTimeOut(PieceColor color) {
    final newStatus = color == PieceColor.white
        ? GameStatus.blackResigned // white ran out of time, black wins
        : GameStatus.whiteResigned;
    state = state.copyWith(
      game: state.game.copyWith(status: newStatus),
      clearSelection: true,
    );
  }

  // ─── Drag-and-drop support ────────────────────────────────────────────────

  void startDrag(Square from) {
    final game = state.game;
    if (game.isGameOver || state.isAiThinking) return;

    if (game.mode == GameMode.vsComputer) {
      final humanColor = game.humanColor ?? PieceColor.white;
      if (game.currentTurn != humanColor) return;
    }

    final piece = Board.pieceAt(game.board, from);
    if (piece == null || piece.color != game.currentTurn) return;

    _selectPiece(from, piece);
  }

  void dropOnSquare(Square to) {
    if (state.selectedSquare == null) return;

    final legalMoves = state.legalMovesForSelected;
    final matchingMoves = legalMoves.where((m) => m.to == to).toList();

    if (matchingMoves.isNotEmpty) {
      final isPromotion = matchingMoves.any((m) => m.isPromotion);
      if (isPromotion) {
        state = state.copyWith(pendingPromotion: matchingMoves.first);
        return;
      }
      _executeMove(matchingMoves.first);
    } else {
      state = state.copyWith(clearSelection: true);
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final gameProvider = StateNotifierProvider<GameNotifier, AppGameState>((ref) {
  return GameNotifier();
});
