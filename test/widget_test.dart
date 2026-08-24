import 'package:flutter_test/flutter_test.dart';
import 'package:royalgambit/domain/models/player_profile.dart';

void main() {
  test('App initial state test', () {
    const profile = PlayerProfile();
    expect(profile.coins, equals(250));
    expect(profile.rankLevel, equals(1));
  });
}



