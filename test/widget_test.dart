import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:royalgambit/app.dart';
import 'package:royalgambit/data/repositories/settings_storage.dart';
import 'package:royalgambit/presentation/providers/settings_provider.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final storage = await SettingsStorage.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStorageProvider.overrideWithValue(storage),
        ],
        child: const RoyalGambitApp(),
      ),
    );
    expect(find.text('Royal Gambit'), findsWidgets);
  });
}
