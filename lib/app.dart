import 'package:flutter/material.dart';
import 'package:royalgambit/core/theme/app_theme.dart';
import 'package:royalgambit/presentation/screens/game_screen.dart';
import 'package:royalgambit/presentation/screens/home_screen.dart';
import 'package:royalgambit/presentation/screens/settings_screen.dart';

class RoyalGambitApp extends StatelessWidget {
  const RoyalGambitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Royal Gambit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/game': (_) => const GameScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
