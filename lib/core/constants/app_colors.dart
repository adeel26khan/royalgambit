import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Quiet Luxury Theme Tokens
  static const Color background = Color(0xFF121212); // Near-black, reduces eye strain
  static const Color surface = Color(0xFF1E1E1E); // Cards, panels, sidebars
  static const Color surfaceVariant = Color(0xFF252525); // Hover states, active panels
  static const Color surfaceElevated = Color(0xFF252525); // Active turn, elevated cards
  static const Color card = Color(0xFF1E1E1E);

  // Accents & Status
  static const Color accent = Color(0xFFD4A853); // Muted gold — active player, glow, primary buttons
  static const Color primaryAccent = Color(0xFFD4A853);
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color success = Color(0xFF81C784); // Win indicator
  static const Color danger = Color(0xFFE57373); // Check, resign, loss, critical timer

  // Board Highlights
  static const Color selectedGlow = Color(0xFFD4A853);
  static const Color selectedOverlay = Color(0x66D4A853);
  static const Color legalMoveDot = Color(0x99D4A853);
  static const Color lastMoveFrom = Color(0x44D4A853);
  static const Color lastMoveTo = Color(0x77D4A853);
  static const Color checkHighlight = Color(0xBBE57373);

  // Pieces
  static const Color whitePieceFill = Color(0xFFF5F0E0);
  static const Color whitePieceStroke = Color(0xFF8B7355);
  static const Color blackPieceFill = Color(0xFF1A1A2E);
  static const Color blackPieceStroke = Color(0xFF4A3728);

  // Text aliases for backwards compatibility
  static const Color primary = Color(0xFFF0F0F0);
  static const Color secondary = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFF0F0F0);

  // Gradients
  static const LinearGradient homeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121212), Color(0xFF0A0A0A)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A853), Color(0xFFF3D694), Color(0xFFD4A853)],
  );

  // Status aliases
  static const Color winColor = Color(0xFF81C784);
  static const Color lossColor = Color(0xFFE57373);
  static const Color drawColor = Color(0xFF9E9E9E);

  // Timers
  static const Color timerNormal = Color(0xFFF0F0F0);
  static const Color timerWarning = Color(0xFFD4A853);
  static const Color timerCritical = Color(0xFFE57373);

  // Buttons
  static const Color buttonPrimary = Color(0xFFD4A853);
  static const Color buttonSecondary = Color(0xFF252525);

  // Players
  static const Color whitePlayer = Color(0xFFF5F0E0);
  static const Color blackPlayer = Color(0xFF1E1E1E);
}
