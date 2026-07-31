import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
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

    // Sync difficulty from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedDifficulty = ref.read(settingsProvider).difficulty;
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 720;

    return Scaffold(
      body: Stack(
        children: [
          // Dark background gradient
          Container(
            decoration: const BoxDecoration(gradient: AppColors.homeGradient),
          ),

          // Decorative background chess grid
          Positioned.fill(
            child: CustomPaint(painter: _ChessPatternPainter()),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // ── Rotating Gold Crown Logo ──────────────────────────
                      AnimatedBuilder(
                        animation: _logoAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _logoAnim.value,
                          child: const _LogoWidget(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── ShaderMask Title & Tagline ────────────────────────
                      AnimatedBuilder(
                        animation: _fadeAnim,
                        builder: (_, child) =>
                            Opacity(opacity: _fadeAnim.value, child: child!),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => AppColors.goldGradient.createShader(
                                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                              ),
                              child: Text(
                                AppStrings.appName,
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 44,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.tagline,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    letterSpacing: 3,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Game Mode Selector Cards ──────────────────────────
                      AnimatedBuilder(
                        animation: _fadeAnim,
                        builder: (_, child) =>
                            Opacity(opacity: _fadeAnim.value, child: child!),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'GAME MODE',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(letterSpacing: 2, color: AppColors.accent),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            if (isWide)
                              Row(
                                children: [
                                  Expanded(
                                    child: _ModeCard(
                                      mode: GameMode.vsComputer,
                                      selected: _selectedMode == GameMode.vsComputer,
                                      onTap: () => setState(() =>
                                          _selectedMode = GameMode.vsComputer),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _ModeCard(
                                      mode: GameMode.local2Player,
                                      selected: _selectedMode == GameMode.local2Player,
                                      onTap: () => setState(() =>
                                          _selectedMode = GameMode.local2Player),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _ModeCard(
                                    mode: GameMode.vsComputer,
                                    selected: _selectedMode == GameMode.vsComputer,
                                    onTap: () => setState(() =>
                                        _selectedMode = GameMode.vsComputer),
                                  ),
                                  const SizedBox(height: 12),
                                  _ModeCard(
                                    mode: GameMode.local2Player,
                                    selected: _selectedMode == GameMode.local2Player,
                                    onTap: () => setState(() =>
                                        _selectedMode = GameMode.local2Player),
                                  ),
                                ],
                              ),

                            // ── AI Difficulty & Piece Side Selection ────────
                            if (_selectedMode == GameMode.vsComputer) ...[
                              const SizedBox(height: 24),
                              _DifficultySelector(
                                selected: _selectedDifficulty,
                                onChanged: (d) =>
                                    setState(() => _selectedDifficulty = d),
                              ),
                              const SizedBox(height: 16),
                              _ColorSelector(
                                selected: _humanColor,
                                onChanged: (c) =>
                                    setState(() => _humanColor = c),
                              ),
                            ],

                            const SizedBox(height: 32),

                            // ── Single Primary START MATCH Button ──────────
                            SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _startGame,
                                icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Color(0xFF121212)),
                                label: const Text(
                                  'START MATCH',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
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

                            const SizedBox(height: 16),

                            // ── Settings & App Info ────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/settings'),
                                  icon: const Icon(Icons.settings_outlined,
                                      size: 18),
                                  label: const Text(AppStrings.settings),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'v1.0.0',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary.withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
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

    // Initialize timer
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

// ─── Rotating Gold Crown Logo ────────────────────────────────────────────────

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
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accent.withOpacity(0.3),
            AppColors.accent.withOpacity(0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2),
            blurRadius: 36,
            spreadRadius: 4,
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
          padding: const EdgeInsets.all(12.0),
          child: Image.asset(
            'assets/images/logo-transp.webp',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.emoji_events,
              size: 64,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mode Selection Cards ────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final GameMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVsCom = mode == GameMode.vsComputer;
    final title = isVsCom ? AppStrings.vsComputer : AppStrings.local2Player;
    final subtitle = isVsCom
        ? 'Play against Stockfish AI'
        : 'Pass and play on same device';
    final icon = isVsCom ? Icons.smart_toy_outlined : Icons.people_outline;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.surfaceVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.12),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.surfaceVariant,
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Difficulty Selector ──────────────────────────────────────────────────────

class _DifficultySelector extends StatelessWidget {
  final AiDifficulty selected;
  final ValueChanged<AiDifficulty> onChanged;

  const _DifficultySelector({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectDifficulty,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.5,
                color: AppColors.accent,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: difficulties.map((d) {
            final (diff, label, icon) = d;
            final isSelected = selected == diff;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(diff),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.surfaceVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Color selector ───────────────────────────────────────────────────────────

class _ColorSelector extends StatelessWidget {
  final PieceColor selected;
  final ValueChanged<PieceColor> onChanged;

  const _ColorSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLAY AS',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(letterSpacing: 1.5, color: AppColors.accent),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _ColorOption(
              color: PieceColor.white,
              label: 'White',
              selected: selected == PieceColor.white,
              onTap: () => onChanged(PieceColor.white),
            ),
            const SizedBox(width: 12),
            _ColorOption(
              color: PieceColor.black,
              label: 'Black',
              selected: selected == PieceColor.black,
              onTap: () => onChanged(PieceColor.black),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  final PieceColor color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = color == PieceColor.white;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withOpacity(0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.surfaceVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWhite ? Colors.white : Colors.black,
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Background chess pattern painter ────────────────────────────────────────

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
