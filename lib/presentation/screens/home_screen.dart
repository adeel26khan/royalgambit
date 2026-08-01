import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/core/utils/update_service.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';
import 'package:royalgambit/presentation/providers/settings_provider.dart';
import 'package:royalgambit/presentation/providers/timer_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnim;
  late Animation<double> _fadeAnim;

  GameMode _selectedMode = GameMode.vsComputer;
  AiDifficulty _selectedDifficulty = AiDifficulty.intermediate;
  PieceColor _humanColor = PieceColor.white;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _logoController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedDifficulty = ref.read(settingsProvider).difficulty;
      UpdateService.instance.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(gradient: AppColors.homeGradient),
          ),

          // Chess pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _ChessPatternPainter()),
          ),

          // Content Layout
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      // Top Row: App Icon & Title
                      AnimatedBuilder(
                        animation: _fadeAnim,
                        builder: (_, child) => Opacity(
                          opacity: _fadeAnim.value,
                          child: child!,
                        ),
                        child: _HeaderWidget(
                          logoAnim: _logoAnim,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Main Form Options (Fit within available height)
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mode Selector Tabs (Horizontal Segmented Bar)
                              _ModeSegmentedControl(
                                selectedMode: _selectedMode,
                                onChanged: (mode) =>
                                    setState(() => _selectedMode = mode),
                              ),

                              const SizedBox(height: 16),

                              // AI Options Container
                              AnimatedCrossFade(
                                firstChild: _AiSettingsCard(
                                  selectedDifficulty: _selectedDifficulty,
                                  selectedColor: _humanColor,
                                  onDifficultyChanged: (d) =>
                                      setState(() => _selectedDifficulty = d),
                                  onColorChanged: (c) =>
                                      setState(() => _humanColor = c),
                                ),
                                secondChild: _LocalModeCard(),
                                crossFadeState: _selectedMode == GameMode.vsComputer
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 250),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Bottom Action Bar: START MATCH + Settings
                      _BottomActionBar(
                        onStart: _startGame,
                        onOpenSettings: () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final settings = ref.read(settingsProvider);

    ref.read(gameProvider.notifier).startNewGame(
          mode: _selectedMode,
          difficulty: _selectedDifficulty,
          humanColor: _humanColor,
        );

    ref.read(timerProvider.notifier).initialize(
          seconds: settings.timerSeconds,
          enabled: settings.timerEnabled,
        );
    if (settings.timerEnabled) {
      ref.read(timerProvider.notifier).start(PieceColor.white);
    }

    Navigator.pushNamed(context, '/game');
  }
}

// ─── Header Widget (Compact & Hero) ──────────────────────────────────────────

class _HeaderWidget extends StatelessWidget {
  final Animation<double> logoAnim;

  const _HeaderWidget({required this.logoAnim});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: logoAnim,
          builder: (_, __) => Transform.scale(
            scale: logoAnim.value,
            child: const _LogoWidget(),
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.goldGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        Text(
          AppStrings.tagline,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 2.5,
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}

// ─── Logo Widget ─────────────────────────────────────────────────────────────

class _LogoWidget extends StatefulWidget {
  const _LogoWidget();

  @override
  State<_LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<_LogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accent.withOpacity(0.35),
            AppColors.accent.withOpacity(0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (_, child) => Transform.rotate(
          angle: _rotationController.value * 2 * 3.141592653589793,
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo-transp.webp',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.emoji_events,
              size: 44,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Horizontal Segmented Control for Game Mode ───────────────────────────────

class _ModeSegmentedControl extends StatelessWidget {
  final GameMode selectedMode;
  final ValueChanged<GameMode> onChanged;

  const _ModeSegmentedControl({
    required this.selectedMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              title: 'vs Computer',
              icon: Icons.smart_toy_outlined,
              selected: selectedMode == GameMode.vsComputer,
              onTap: () => onChanged(GameMode.vsComputer),
            ),
          ),
          Expanded(
            child: _SegmentTab(
              title: '2 Player Local',
              icon: Icons.people_outline,
              selected: selectedMode == GameMode.local2Player,
              onTap: () => onChanged(GameMode.local2Player),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.25),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? const Color(0xFF121212) : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF121212) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Unified AI Settings Card ────────────────────────────────────────────────

class _AiSettingsCard extends StatelessWidget {
  final AiDifficulty selectedDifficulty;
  final PieceColor selectedColor;
  final ValueChanged<AiDifficulty> onDifficultyChanged;
  final ValueChanged<PieceColor> onColorChanged;

  const _AiSettingsCard({
    required this.selectedDifficulty,
    required this.selectedColor,
    required this.onDifficultyChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty Section
          Text(
            'SELECT DIFFICULTY',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          _DifficultyGrid(
            selected: selectedDifficulty,
            onChanged: onDifficultyChanged,
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Play As Side Section
          Row(
            children: [
              Text(
                'PLAY AS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              _ColorSelectorCompact(
                selected: selectedColor,
                onChanged: onColorChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Local 2 Player Card ─────────────────────────────────────────────────────

class _LocalModeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 36,
            color: AppColors.accent,
          ),
          const SizedBox(height: 10),
          Text(
            'Pass & Play Mode',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Play face-to-face with a friend on this device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Compact Difficulty Grid ────────────────────────────────────────────────

class _DifficultyGrid extends StatelessWidget {
  final AiDifficulty selected;
  final ValueChanged<AiDifficulty> onChanged;

  const _DifficultyGrid({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final difficulties = [
      (AiDifficulty.beginner, AppStrings.beginner, Icons.sentiment_satisfied),
      (AiDifficulty.intermediate, AppStrings.intermediate, Icons.psychology),
      (AiDifficulty.advanced, AppStrings.advanced, Icons.auto_awesome),
      (AiDifficulty.master, AppStrings.master, Icons.emoji_events),
    ];

    return Row(
      children: difficulties.map((d) {
        final (diff, label, icon) = d;
        final isSelected = selected == diff;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(diff),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? const Color(0xFF121212) : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF121212) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Compact Color Selector Toggle ──────────────────────────────────────────

class _ColorSelectorCompact extends StatelessWidget {
  final PieceColor selected;
  final ValueChanged<PieceColor> onChanged;

  const _ColorSelectorCompact({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorChip(
            color: PieceColor.white,
            label: 'White',
            selected: selected == PieceColor.white,
            onTap: () => onChanged(PieceColor.white),
          ),
          _ColorChip(
            color: PieceColor.black,
            label: 'Black',
            selected: selected == PieceColor.black,
            onTap: () => onChanged(PieceColor.black),
          ),
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final PieceColor color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = color == PieceColor.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWhite ? Colors.white : Colors.black,
                border: Border.all(
                  color: selected
                      ? Colors.black.withOpacity(0.4)
                      : AppColors.textSecondary.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF121212) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Action Bar (Fixed, Non-Scrollable) ───────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onOpenSettings;

  const _BottomActionBar({
    required this.onStart,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 26, color: Color(0xFF121212)),
              label: const Text(
                'START MATCH',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF121212),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.2),
            ),
          ),
          child: IconButton(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            tooltip: AppStrings.settings,
          ),
        ),
      ],
    );
  }
}

// ─── Chess Pattern Painter ────────────────────────────────────────────────────

class _ChessPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..style = PaintingStyle.fill;

    final tileSize = size.width / 14;
    for (int r = 0; r < 20; r++) {
      for (int c = 0; c < 16; c++) {
        if ((r + c) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
