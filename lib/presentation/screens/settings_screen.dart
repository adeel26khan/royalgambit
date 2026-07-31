import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Game ─────────────────────────────────────────────────────
            _SectionHeader('GAME'),
            _SettingsTile(
              icon: Icons.speed,
              title: AppStrings.selectDifficulty,
              subtitle: settings.difficulty.name.toUpperCase(),
              trailing: _DifficultyDropdown(
                value: settings.difficulty,
                onChanged: notifier.setDifficulty,
              ),
            ),
            const Divider(),
            _SwitchTile(
              icon: Icons.timer_outlined,
              title: AppStrings.timerEnabled,
              subtitle: 'Enable chess clock',
              value: settings.timerEnabled,
              onChanged: notifier.setTimerEnabled,
            ),
            if (settings.timerEnabled) ...[
              const Divider(),
              _SettingsTile(
                icon: Icons.hourglass_empty,
                title: AppStrings.timerControl,
                subtitle: _timerLabel(settings.timerSeconds),
                trailing: _TimerDropdown(
                  value: settings.timerSeconds,
                  onChanged: notifier.setTimerSeconds,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Display ───────────────────────────────────────────────────
            _SectionHeader('DISPLAY'),
            _SettingsTile(
              icon: Icons.grid_on,
              title: AppStrings.boardTheme,
              subtitle: settings.boardTheme.name.toUpperCase(),
              trailing: _BoardThemeSelector(
                value: settings.boardTheme,
                onChanged: notifier.setBoardTheme,
              ),
            ),
            const Divider(),
            _SettingsTile(
              icon: Icons.extension_outlined,
              title: AppStrings.pieceTheme,
              subtitle: settings.pieceTheme == PieceTheme.alpha
                  ? 'Alpha Set (Default)'
                  : settings.pieceTheme == PieceTheme.totoy
                      ? 'Totoy Inkscape Set'
                      : settings.pieceTheme == PieceTheme.fantasy
                          ? 'Fantasy Set'
                          : 'Custom SVG Vector',
              trailing: _PieceThemeSelector(
                value: settings.pieceTheme,
                onChanged: notifier.setPieceTheme,
              ),
            ),
            const Divider(),
            _SwitchTile(
              icon: Icons.format_list_numbered,
              title: AppStrings.showCoordinates,
              subtitle: 'Show file/rank labels on the board',
              value: settings.showCoordinates,
              onChanged: notifier.setShowCoordinates,
            ),

            const SizedBox(height: 24),

            // ── Audio & Haptics ───────────────────────────────────────────
            _SectionHeader('AUDIO & HAPTICS'),
            _SwitchTile(
              icon: Icons.volume_up_outlined,
              title: AppStrings.soundEnabled,
              subtitle: 'Move, capture, and check sounds',
              value: settings.soundEnabled,
              onChanged: notifier.setSoundEnabled,
            ),
            const Divider(),
            _SwitchTile(
              icon: Icons.vibration,
              title: AppStrings.hapticsEnabled,
              subtitle: 'Vibration on piece selection and capture',
              value: settings.hapticsEnabled,
              onChanged: notifier.setHapticsEnabled,
            ),

            const SizedBox(height: 32),

            // About
            Center(
              child: Text(
                '${AppStrings.appName} v1.0.0\nBuilt with Flutter ❤️',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary.withOpacity(0.6),
                      height: 1.6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timerLabel(int seconds) {
    switch (seconds) {
      case 180:
        return AppStrings.blitz3;
      case 300:
        return AppStrings.blitz5;
      case 600:
        return AppStrings.rapid10;
      case 900:
        return AppStrings.rapid15;
      default:
        return '${seconds ~/ 60} min';
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.accent,
              letterSpacing: 2,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DifficultyDropdown extends StatelessWidget {
  final AiDifficulty value;
  final ValueChanged<AiDifficulty> onChanged;

  const _DifficultyDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<AiDifficulty>(
      value: value,
      dropdownColor: AppColors.surface,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
            value: AiDifficulty.beginner, child: Text(AppStrings.beginner)),
        DropdownMenuItem(
            value: AiDifficulty.intermediate,
            child: Text(AppStrings.intermediate)),
        DropdownMenuItem(
            value: AiDifficulty.advanced, child: Text(AppStrings.advanced)),
        DropdownMenuItem(
            value: AiDifficulty.master, child: Text(AppStrings.master)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _BoardThemeSelector extends StatelessWidget {
  final BoardTheme value;
  final ValueChanged<BoardTheme> onChanged;

  const _BoardThemeSelector({required this.value, required this.onChanged});

  Widget _buildThemeItem(BoardTheme theme, String name, String assetPath) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            assetPath,
            width: 20,
            height: 20,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        Text(name),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<BoardTheme>(
      value: value,
      dropdownColor: AppColors.surface,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(
          value: BoardTheme.walnut,
          child: _buildThemeItem(BoardTheme.walnut, 'Walnut Classic', 'assets/board-thumbnails/wood.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.wood2,
          child: _buildThemeItem(BoardTheme.wood2, 'Mahogany Wood', 'assets/board-thumbnails/wood2.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.wood3,
          child: _buildThemeItem(BoardTheme.wood3, 'Vintage Oak', 'assets/board-thumbnails/wood3.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.wood4,
          child: _buildThemeItem(BoardTheme.wood4, 'Rustic Birch', 'assets/board-thumbnails/wood4.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.maple,
          child: _buildThemeItem(BoardTheme.maple, 'Light Maple', 'assets/board-thumbnails/maple.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.blue,
          child: _buildThemeItem(BoardTheme.blue, 'Royal Blue', 'assets/board-thumbnails/blue.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.blueMarble,
          child: _buildThemeItem(BoardTheme.blueMarble, 'Blue Marble', 'assets/board-thumbnails/blueMarble.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.brown,
          child: _buildThemeItem(BoardTheme.brown, 'Deep Brown', 'assets/board-thumbnails/brown.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.green,
          child: _buildThemeItem(BoardTheme.green, 'Forest Green', 'assets/board-thumbnails/green.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.grey,
          child: _buildThemeItem(BoardTheme.grey, 'Obsidian Slate', 'assets/board-thumbnails/grey.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.canvas,
          child: _buildThemeItem(BoardTheme.canvas, 'Artist Canvas', 'assets/board-thumbnails/canvas.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.leather,
          child: _buildThemeItem(BoardTheme.leather, 'Premium Leather', 'assets/board-thumbnails/leather.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.marble,
          child: _buildThemeItem(BoardTheme.marble, 'White Marble', 'assets/board-thumbnails/marble.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.metal,
          child: _buildThemeItem(BoardTheme.metal, 'Titanium Metal', 'assets/board-thumbnails/metal.jpg'),
        ),
        DropdownMenuItem(
          value: BoardTheme.purpleDiag,
          child: _buildThemeItem(BoardTheme.purpleDiag, 'Cyber Purple', 'assets/board-thumbnails/purpleDiag.jpg'),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _PieceThemeSelector extends StatelessWidget {
  final PieceTheme value;
  final ValueChanged<PieceTheme> onChanged;

  const _PieceThemeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<PieceTheme>(
      value: value,
      dropdownColor: AppColors.surface,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
          value: PieceTheme.alpha,
          child: Text('Alpha Set (Default)'),
        ),
        DropdownMenuItem(
          value: PieceTheme.totoy,
          child: Text('Totoy Set'),
        ),
        DropdownMenuItem(
          value: PieceTheme.fantasy,
          child: Text('Fantasy Set'),
        ),
        DropdownMenuItem(
          value: PieceTheme.customSvg,
          child: Text('Custom SVG'),
        ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _TimerDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _TimerDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      dropdownColor: AppColors.surface,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 180, child: Text(AppStrings.blitz3)),
        DropdownMenuItem(value: 300, child: Text(AppStrings.blitz5)),
        DropdownMenuItem(value: 600, child: Text(AppStrings.rapid10)),
        DropdownMenuItem(value: 900, child: Text(AppStrings.rapid15)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
