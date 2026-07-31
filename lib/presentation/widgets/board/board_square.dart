import 'package:flutter/material.dart';
import 'package:royalgambit/core/constants/app_colors.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/domain/models/square.dart';
import 'package:royalgambit/presentation/widgets/board/piece_painter.dart';

class BoardSquare extends StatefulWidget {
  final Square square;
  final bool isFlipped;
  final bool isSelected;
  final bool isLegalMove;
  final bool isLastMoveFrom;
  final bool isLastMoveTo;
  final bool isCheck;
  final Piece? piece;
  final GameState game;
  final double squareSize;
  final void Function(Square) onTap;
  final void Function(Square) onDragStart;
  final void Function(Square) onDrop;
  final BoardTheme boardTheme;
  final PieceTheme pieceTheme;
  final bool showCoordinates;

  const BoardSquare({
    super.key,
    required this.square,
    required this.isFlipped,
    required this.isSelected,
    required this.isLegalMove,
    required this.isLastMoveFrom,
    required this.isLastMoveTo,
    required this.isCheck,
    required this.piece,
    required this.game,
    required this.squareSize,
    required this.onTap,
    required this.onDragStart,
    required this.onDrop,
    required this.boardTheme,
    this.pieceTheme = PieceTheme.alpha,
    required this.showCoordinates,
  });

  @override
  State<BoardSquare> createState() => _BoardSquareState();
}

class _BoardSquareState extends State<BoardSquare>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _checkController;
  late Animation<double> _pulseAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseAnim = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(BoardSquare old) {
    super.didUpdateWidget(old);
    if (widget.isCheck && !old.isCheck) {
      _checkController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }



  Color get _lightColor {
    switch (widget.boardTheme) {
      case BoardTheme.walnut:
      case BoardTheme.wood2:
      case BoardTheme.wood3:
      case BoardTheme.wood4:
      case BoardTheme.maple:
        return const Color(0xFFE8D5B7);
      case BoardTheme.grey:
        return const Color(0xFFD0D0D0);
      case BoardTheme.green:
        return const Color(0xFFD4E8C4);
      case BoardTheme.blue:
      case BoardTheme.blueMarble:
        return const Color(0xFFD6E4F0);
      default:
        return const Color(0xFFEEEEEE);
    }
  }

  Color get _darkColor {
    switch (widget.boardTheme) {
      case BoardTheme.walnut:
      case BoardTheme.wood2:
      case BoardTheme.wood3:
      case BoardTheme.wood4:
      case BoardTheme.brown:
        return const Color(0xFF8B5E3C);
      case BoardTheme.grey:
        return const Color(0xFF2B2B2B);
      case BoardTheme.green:
        return const Color(0xFF3B6B3B);
      case BoardTheme.blue:
      case BoardTheme.blueMarble:
        return const Color(0xFF2B4C7E);
      default:
        return const Color(0xFF6B8CA0);
    }
  }

  bool get _isLight {
    return (widget.square.row + widget.square.col) % 2 == 0;
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = widget.squareSize;
    final pieceSize = squareSize * 0.85;

    // Show coordinates
    final showFile = widget.showCoordinates &&
        (widget.isFlipped ? widget.square.row == 0 : widget.square.row == 7);
    final showRank = widget.showCoordinates &&
        (widget.isFlipped ? widget.square.col == 7 : widget.square.col == 0);
    final coordColor = _isLight
        ? _darkColor.withOpacity(0.7)
        : _lightColor.withOpacity(0.7);

    Widget squareContent = DragTarget<Square>(
      onWillAcceptWithDetails: (_) => widget.isLegalMove || widget.isSelected,
      onAcceptWithDetails: (details) => widget.onDrop(details.data),
      builder: (ctx, candidateData, rejectedData) {
        final isDragOver = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => widget.onTap(widget.square),
          child: Stack(
            children: [
              // Square container / drag highlight
              Positioned.fill(
                child: Container(
                  color: isDragOver
                      ? AppColors.selectedOverlay
                      : Colors.transparent,
                ),
              ),

              // Last move overlays
              if (widget.isLastMoveFrom || widget.isLastMoveTo)
                Container(
                  width: squareSize,
                  height: squareSize,
                  color: widget.isLastMoveTo
                      ? AppColors.lastMoveTo
                      : AppColors.lastMoveFrom,
                ),

              // Selected square glow
              if (widget.isSelected)
                Container(
                  width: squareSize,
                  height: squareSize,
                  decoration: BoxDecoration(
                    color: AppColors.selectedOverlay,
                    border: Border.all(
                      color: AppColors.selectedGlow,
                      width: 3,
                    ),
                  ),
                ),

              // Check highlight
              if (widget.isCheck)
                AnimatedBuilder(
                  animation: _checkAnim,
                  builder: (_, __) => Container(
                    width: squareSize,
                    height: squareSize,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.checkHighlight
                              .withOpacity(_checkAnim.value.clamp(0.0, 1.0)),
                          AppColors.checkHighlight.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),

              // Legal move indicator
              if (widget.isLegalMove)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Center(
                    child: widget.piece != null
                        ? Container(
                            width: squareSize,
                            height: squareSize,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.legalMoveDot
                                    .withOpacity((_pulseAnim.value + 0.2).clamp(0.0, 1.0)),
                                width: 3,
                              ),
                            ),
                          )
                        : Container(
                            width: squareSize * 0.3,
                            height: squareSize * 0.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.legalMoveDot
                                  .withOpacity(_pulseAnim.value.clamp(0.0, 1.0)),
                            ),
                          ),
                  ),
                ),

              // Piece
              if (widget.piece != null)
                Center(
                  child: widget.piece!.type == PieceType.king &&
                          widget.isCheck
                      ? _buildDraggablePiece(pieceSize)
                      : _buildDraggablePiece(pieceSize),
                ),

              // Coordinates
              if (showFile)
                Positioned(
                  right: 2,
                  bottom: 1,
                  child: Text(
                    widget.square.file,
                    style: TextStyle(
                      fontSize: squareSize * 0.2,
                      fontWeight: FontWeight.w700,
                      color: coordColor,
                    ),
                  ),
                ),
              if (showRank)
                Positioned(
                  left: 2,
                  top: 1,
                  child: Text(
                    widget.square.rank,
                    style: TextStyle(
                      fontSize: squareSize * 0.2,
                      fontWeight: FontWeight.w700,
                      color: coordColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    return squareContent;
  }

  Widget _buildDraggablePiece(double pieceSize) {
    final piece = widget.piece;
    if (piece == null) return const SizedBox.shrink();

    final isCurrentPlayer = piece.color == widget.game.currentTurn;
    final canDrag = isCurrentPlayer && !widget.game.isGameOver;

    if (canDrag) {
      return Draggable<Square>(
        data: widget.square,
        onDragStarted: () => widget.onDragStart(widget.square),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: PieceWidget(
              type: piece.type,
              color: piece.color,
              size: pieceSize * 1.3,
              selected: true,
              pieceTheme: widget.pieceTheme,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: PieceWidget(
            type: piece.type,
            color: piece.color,
            size: pieceSize,
            selected: false,
            pieceTheme: widget.pieceTheme,
          ),
        ),
        child: PieceWidget(
          type: piece.type,
          color: piece.color,
          size: pieceSize,
          selected: widget.isSelected,
          pieceTheme: widget.pieceTheme,
        ),
      );
    }

    return PieceWidget(
      type: piece.type,
      color: piece.color,
      size: pieceSize,
      selected: false,
      pieceTheme: widget.pieceTheme,
    );
  }
}
