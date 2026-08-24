import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/core/constants/app_strings.dart';
import 'package:royalgambit/core/utils/ad_service.dart';
import 'package:royalgambit/core/utils/responsive.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';
import 'package:royalgambit/presentation/widgets/board/chess_board.dart';
import 'package:royalgambit/presentation/widgets/board/promotion_dialog.dart';
import 'package:royalgambit/presentation/widgets/overlays/ai_thinking_indicator.dart';
import 'package:royalgambit/presentation/widgets/overlays/game_end_overlay.dart';
import 'package:royalgambit/presentation/widgets/panels/game_controls.dart';
import 'package:royalgambit/presentation/widgets/panels/move_history_panel.dart';
import 'package:royalgambit/presentation/widgets/panels/player_info_panel.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard shortcuts
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyZ &&
              HardwareKeyboard.instance.isControlPressed) {
            ref.read(gameProvider.notifier).undo();
          } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, ref),
        body: LayoutBuilder(
          builder: (ctx, constraints) {
            if (Responsive.isStacked(context)) {
              return _buildPortraitLayout(context, constraints);
            } else {
              return _buildLandscapeLayout(context, constraints);
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(gameProvider);
    final game = appState.game;
    final isThinking = appState.isAiThinking;

    String modeLabel;
    if (game.mode == GameMode.vsComputer) {
      modeLabel = 'vs Computer · ${game.difficulty.name.toUpperCase()}';
    } else {
      modeLabel = '2 Player Local';
    }

    return AppBar(
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Text(
                modeLabel,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isThinking) ...[
              const SizedBox(width: 12),
              const AiThinkingIndicator(),
            ],
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () =>
            Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          tooltip: AppStrings.settings,
        ),
      ],
    );
  }

  // ─── Portrait (mobile) layout ─────────────────────────────────────────────

  Widget _buildPortraitLayout(
      BuildContext context, BoxConstraints constraints) {
    final appState = ref.watch(gameProvider);
    final game = appState.game;
    final isFlipped = game.boardFlipped;
    final boardSize = Responsive.boardSize(context);

    // Top player = opponent's perspective; bottom = current player
    final topColor = isFlipped ? PieceColor.white : PieceColor.black;
    final bottomColor = isFlipped ? PieceColor.black : PieceColor.white;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Policy-Compliant Top Banner Ad (Completely isolated from game action controls)
                    const BannerAdWidget(
                      padding: EdgeInsets.symmetric(vertical: 4),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            // Opponent (top)
                            PlayerInfoPanel(
                              playerColor: topColor,
                              isTop: true,
                            ),
                            const SizedBox(height: 10),

                            // Board
                            Center(
                              child: ChessBoard(size: boardSize),
                            ),
                            const SizedBox(height: 10),

                            // Player (bottom)
                            PlayerInfoPanel(
                              playerColor: bottomColor,
                              isTop: false,
                            ),
                            const SizedBox(height: 12),

                            // Move history collapsible ExpansionTile (Wrapped in Material for Flutter assertion safety)
                            Material(
                              color: AppColors.surface,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.accent.withOpacity(0.12),
                                ),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  dense: true,
                                  title: Row(
                                    children: [
                                      const Icon(Icons.format_list_numbered, size: 16, color: AppColors.accent),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Move History',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 16, color: AppColors.accent),
                                        tooltip: 'Copy PGN',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: game.moveHistory.isEmpty
                                            ? null
                                            : () {
                                                final pgn = MoveHistoryPanel.generatePgn(game.moveHistory);
                                                Clipboard.setData(ClipboardData(text: pgn));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('PGN copied to clipboard! 📋'),
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              },
                                      ),
                                    ],
                                  ),
                                  children: const [
                                    SizedBox(
                                      height: 160,
                                      child: MoveHistoryPanel(showHeader: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar with edge-to-edge background surface and safe button insets
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: Color(0xFF282828))),
              ),
              child: const SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: GameControls(compact: true),
                ),
              ),
            ),
          ],
        ),


        // Overlays
        if (appState.pendingPromotion != null) const PromotionDialog(),
        if (game.isGameOver) const GameEndOverlay(),
      ],
    );
  }

  // ─── Landscape / Tablet / Desktop layout ─────────────────────────────────

  Widget _buildLandscapeLayout(
      BuildContext context, BoxConstraints constraints) {
    final appState = ref.watch(gameProvider);
    final game = appState.game;
    final isFlipped = game.boardFlipped;
    final boardSize = Responsive.boardSize(context);
    final isDesktop = Responsive.isDesktop(context);

    final topColor = isFlipped ? PieceColor.white : PieceColor.black;
    final bottomColor = isFlipped ? PieceColor.black : PieceColor.white;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Desktop Left Sidebar (320px) ──────────────────────────────────
            if (isDesktop)
              Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    PlayerInfoPanel(
                      playerColor: topColor,
                      isTop: true,
                    ),
                    const SizedBox(height: 12),
                    const Expanded(child: MoveHistoryPanel()),
                    const SizedBox(height: 12),
                    PlayerInfoPanel(
                      playerColor: bottomColor,
                      isTop: false,
                    ),
                    const SizedBox(height: 12),
                    const GameControls(),
                  ],
                ),
              )
            else ...[
              // Tablet / Mobile Landscape Left Panel (Move History)
              Container(
                width: 220,
                padding: const EdgeInsets.all(12),
                child: const Column(
                  children: [
                    Expanded(child: MoveHistoryPanel()),
                  ],
                ),
              ),
            ],

            // ── Hero Chess Board (Centered) ───────────────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isDesktop) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PlayerInfoPanel(
                            playerColor: topColor,
                            isTop: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      AspectRatio(
                        aspectRatio: 1,
                        child: Center(child: ChessBoard(size: boardSize)),
                      ),
                      if (!isDesktop) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PlayerInfoPanel(
                            playerColor: bottomColor,
                            isTop: false,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Tablet / Mobile Landscape Right Panel (Controls) ──────────────
            if (!isDesktop)
              Container(
                width: 220,
                padding: const EdgeInsets.all(12),
                child: const Column(
                  children: [
                    GameControls(),
                  ],
                ),
              ),
          ],
        ),

        // Overlays
        if (appState.pendingPromotion != null) const PromotionDialog(),
        if (game.isGameOver) const GameEndOverlay(),
      ],
    );
  }
}
