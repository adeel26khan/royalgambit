import 'package:flutter_test/flutter_test.dart';
import 'package:royalgambit/domain/engine/ai_engine.dart';
import 'package:royalgambit/domain/engine/board.dart';
import 'package:royalgambit/domain/engine/move_generator.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';

void main() {
  group('AiEngine', () {
    test('findBestMove returns opening move on turn 1', () {
      final initialBoard = Board.initialBoard();
      final state = GameState(
        board: initialBoard,
        currentTurn: PieceColor.white,
      );

      final move = AiEngine.findBestMove(state, AiDifficulty.intermediate);
      expect(move, isNotNull);
      expect(move!.from.row, greaterThanOrEqualTo(6)); // White pieces row (pawns or knights)
    });

    test('findBestMove evaluates and returns legal move for black', () {
      final initialBoard = Board.initialBoard();
      final state = GameState(
        board: initialBoard,
        currentTurn: PieceColor.black,
        fullMoveNumber: 1,
        lastMove: MoveGenerator.generateLegalMoves(
          GameState(board: initialBoard, currentTurn: PieceColor.white),
          PieceColor.white,
        ).firstWhere((m) => m.to == const Square(4, 4)),
      );

      final move = AiEngine.findBestMove(state, AiDifficulty.advanced);
      expect(move, isNotNull);
      expect(move!.from.row, equals(1)); // Black pawn row
    });
  });
}

