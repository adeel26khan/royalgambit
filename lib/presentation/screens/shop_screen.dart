import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/utils/ad_service.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/player_profile.dart';
import 'package:royalgambit/presentation/providers/profile_provider.dart';
import 'package:royalgambit/presentation/providers/settings_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final profileNotifier = ref.read(profileProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ROYAL SHOP 🛒',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        actions: [
          // Coins Balance Badge
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '${profile.coins}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner Ad (Policy Compliant)
            const BannerAdWidget(padding: EdgeInsets.only(bottom: 12)),

            // ── Free Coins Station with AdMob Daily Frequency Cap ────────────
            _FreeCoinsCard(
              profile: profile,
              onWatchAd: () {
                if (!profile.canWatchRewardedAd) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Daily Rewarded Ad Limit Reached (3/3). Resets in 24 hours! ⏳'),
                    ),
                  );
                  return;
                }
                AdService.instance.showRewardedAd(
                  onRewardGranted: () async {
                    final success = await profileNotifier.recordRewardedAdWatch();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Awesome! +100 Gold Coins Added! 🪙'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Board Skins Catalog ─────────────────────────────────────────
            const _SectionHeader(
              title: 'BOARD SKINS',
              subtitle: 'Purchase exclusive board skins with your Gold Coins',
            ),
            const SizedBox(height: 12),
            _BoardSkinsGrid(
              profile: profile,
              currentTheme: settings.boardTheme,
              onEquip: (theme) => settingsNotifier.setBoardTheme(theme),
              onBuy: (theme, cost) async {
                final success = await profileNotifier.buyBoardTheme(theme, cost);
                if (success) {
                  settingsNotifier.setBoardTheme(theme);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Skin Purchased & Equipped! 🎉'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Not enough coins! Play matches to earn more 🪙'),
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 28),

            // ── Piece Sets Catalog ──────────────────────────────────────────
            const _SectionHeader(
              title: 'PIECE SET SKINS',
              subtitle: 'Purchase vector & artwork piece sets with Gold Coins',
            ),
            const SizedBox(height: 12),
            _PieceSetsGrid(
              profile: profile,
              currentTheme: settings.pieceTheme,
              onEquip: (theme) => settingsNotifier.setPieceTheme(theme),
              onBuy: (theme, cost) async {
                final success = await profileNotifier.buyPieceTheme(theme, cost);
                if (success) {
                  settingsNotifier.setPieceTheme(theme);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Piece Set Purchased & Equipped! 🎉'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Not enough coins! Play matches to earn more 🪙'),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ─── Free Coins Card (With Daily Limit Compliance) ────────────────────────────

class _FreeCoinsCard extends StatelessWidget {
  final PlayerProfile profile;
  final VoidCallback onWatchAd;

  const _FreeCoinsCard({required this.profile, required this.onWatchAd});

  @override
  Widget build(BuildContext context) {
    final canWatch = profile.canWatchRewardedAd;
    final remaining = profile.remainingDailyAds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canWatch ? AppColors.accent.withOpacity(0.3) : Colors.white10,
          width: 1,
        ),
        boxShadow: [
          if (canWatch)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.1),
              blurRadius: 12,
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: canWatch
                  ? AppColors.accent.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
            ),
            child: const Center(
              child: Text('🪙', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FREE COINS STATION',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canWatch
                      ? 'Watch video ad for +100 Gold Coins ($remaining/3 left today)'
                      : 'Daily Ad Limit Reached (3/3 watched). Resets tomorrow!',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: canWatch ? onWatchAd : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canWatch ? AppColors.accent : Colors.white12,
              foregroundColor: canWatch ? const Color(0xFF121212) : AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              canWatch ? Icons.ondemand_video : Icons.lock_clock,
              size: 16,
            ),
            label: Text(
              canWatch ? '+100 🪙' : '3/3 DONE',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Board Skins Grid ─────────────────────────────────────────────────────────

class _BoardSkinsGrid extends StatelessWidget {
  final PlayerProfile profile;
  final BoardTheme currentTheme;
  final ValueChanged<BoardTheme> onEquip;
  final void Function(BoardTheme theme, int cost) onBuy;

  const _BoardSkinsGrid({
    required this.profile,
    required this.currentTheme,
    required this.onEquip,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final boards = [
      (BoardTheme.walnut, 'Walnut Classic', 'assets/board-thumbnails/wood.jpg'),
      (BoardTheme.wood2, 'Mahogany Wood', 'assets/board-thumbnails/wood2.jpg'),
      (BoardTheme.maple, 'Light Maple', 'assets/board-thumbnails/maple.jpg'),
      (BoardTheme.wood3, 'Vintage Oak', 'assets/board-thumbnails/wood3.jpg'),
      (BoardTheme.wood4, 'Rustic Birch', 'assets/board-thumbnails/wood4.jpg'),
      (BoardTheme.blue, 'Royal Blue', 'assets/board-thumbnails/blue.jpg'),
      (BoardTheme.brown, 'Deep Brown', 'assets/board-thumbnails/brown.jpg'),
      (BoardTheme.green, 'Forest Green', 'assets/board-thumbnails/green.jpg'),
      (BoardTheme.grey, 'Obsidian Slate', 'assets/board-thumbnails/grey.jpg'),
      (BoardTheme.blueMarble, 'Blue Marble', 'assets/board-thumbnails/blueMarble.jpg'),
      (BoardTheme.canvas, 'Artist Canvas', 'assets/board-thumbnails/canvas.jpg'),
      (BoardTheme.leather, 'Premium Leather', 'assets/board-thumbnails/leather.jpg'),
      (BoardTheme.marble, 'White Marble', 'assets/board-thumbnails/marble.jpg'),
      (BoardTheme.metal, 'Titanium Metal', 'assets/board-thumbnails/metal.jpg'),
      (BoardTheme.purpleDiag, 'Cyber Purple', 'assets/board-thumbnails/purpleDiag.jpg'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 185,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: boards.length,
      itemBuilder: (ctx, idx) {
        final (theme, name, assetPath) = boards[idx];
        final isUnlocked = profile.isBoardThemeUnlocked(theme);
        final isEquipped = currentTheme == theme;
        final cost = PlayerProfile.boardSkinCost(theme);

        return _SkinCard(
          name: name,
          assetPath: assetPath,
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          cost: cost,
          onEquip: () => onEquip(theme),
          onBuy: () => onBuy(theme, cost),
        );
      },
    );
  }
}

// ─── Piece Sets Grid ──────────────────────────────────────────────────────────

class _PieceSetsGrid extends StatelessWidget {
  final PlayerProfile profile;
  final PieceTheme currentTheme;
  final ValueChanged<PieceTheme> onEquip;
  final void Function(PieceTheme theme, int cost) onBuy;

  const _PieceSetsGrid({
    required this.profile,
    required this.currentTheme,
    required this.onEquip,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final sets = [
      (PieceTheme.alpha, 'Alpha Set (Default)', 'assets/pieces/alpha/wK.svg'),
      (PieceTheme.totoy, 'Totoy Inkscape Set', 'assets/pieces/totoy/wK.svg'),
      (PieceTheme.fantasy, 'Fantasy Set', 'assets/pieces/fantasy/wK.png'),
      (PieceTheme.customSvg, 'Custom Vector SVG', 'assets/pieces/wK.svg'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 130,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sets.length,
      itemBuilder: (ctx, idx) {
        final (theme, name, iconPath) = sets[idx];
        final isUnlocked = profile.isPieceThemeUnlocked(theme);
        final isEquipped = currentTheme == theme;
        final cost = PlayerProfile.pieceSkinCost(theme);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEquipped ? AppColors.accent : Colors.white10,
              width: isEquipped ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.extension_outlined, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              _buildActionButton(
                isUnlocked: isUnlocked,
                isEquipped: isEquipped,
                cost: cost,
                onEquip: () => onEquip(theme),
                onBuy: () => onBuy(theme, cost),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required bool isUnlocked,
    required bool isEquipped,
    required int cost,
    required VoidCallback onEquip,
    required VoidCallback onBuy,
  }) {
    if (isEquipped) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'EQUIPPED ✓',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    if (isUnlocked) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onEquip,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('EQUIP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onBuy,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '$cost 🪙 BUY',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        ),
      ),
    );
  }
}

// ─── Individual Skin Card ─────────────────────────────────────────────────────

class _SkinCard extends StatelessWidget {
  final String name;
  final String assetPath;
  final bool isUnlocked;
  final bool isEquipped;
  final int cost;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  const _SkinCard({
    required this.name,
    required this.assetPath,
    required this.isUnlocked,
    required this.isEquipped,
    required this.cost,
    required this.onEquip,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEquipped ? AppColors.accent : Colors.white10,
          width: isEquipped ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (isEquipped) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'EQUIPPED ✓',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    if (isUnlocked) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onEquip,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: const Color(0xFF121212),
            padding: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('EQUIP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onBuy,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '$cost 🪙 BUY',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
        ),
      ),
    );
  }
}
