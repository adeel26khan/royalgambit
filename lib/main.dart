import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/app.dart';
import 'package:royalgambit/core/utils/ad_service.dart';
import 'package:royalgambit/data/repositories/settings_storage.dart';
import 'package:royalgambit/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsStorage = await SettingsStorage.create();
  await AdService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        settingsStorageProvider.overrideWithValue(settingsStorage),
      ],
      child: const RoyalGambitApp(),
    ),
  );
}
