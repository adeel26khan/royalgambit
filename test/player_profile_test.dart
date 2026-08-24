import 'package:flutter_test/flutter_test.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/player_profile.dart';

void main() {
  group('PlayerProfile', () {
    test('Calculates rank levels correctly based on XP', () {
      const p1 = PlayerProfile(xp: 150);
      expect(p1.rankLevel, equals(1));
      expect(p1.rankTitle, equals('Novice'));

      const p2 = PlayerProfile(xp: 500);
      expect(p2.rankLevel, equals(2));
      expect(p2.rankTitle, equals('Apprentice'));

      const p3 = PlayerProfile(xp: 12000);
      expect(p3.rankLevel, equals(7));
      expect(p3.rankTitle, equals('Royal Champion'));
    });

    test('Tracks unlocked skin themes correctly', () {
      const p = PlayerProfile();
      expect(p.isBoardThemeUnlocked(BoardTheme.walnut), isTrue);
      expect(p.isBoardThemeUnlocked(BoardTheme.purpleDiag), isFalse);

      final updated = p.copyWith(
        unlockedBoardThemes: {...p.unlockedBoardThemes, BoardTheme.purpleDiag},
      );
      expect(updated.isBoardThemeUnlocked(BoardTheme.purpleDiag), isTrue);
    });
  });
}
