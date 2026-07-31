import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:royalgambit/domain/models/game_state.dart';
import 'package:royalgambit/domain/models/piece.dart';

/// Draws chess pieces using Flutter Canvas paths.
/// All pieces use a consistent geometric/minimalist Staunton-inspired style.
class ChessPiecePainter extends CustomPainter {
  final PieceType type;
  final PieceColor color;

  ChessPiecePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final isWhite = color == PieceColor.white;

    final fillPaint = Paint()
      ..color = isWhite ? const Color(0xFFF5F0E0) : const Color(0xFF1C1C2E)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isWhite ? const Color(0xFF8B7355) : const Color(0xFFAA9977)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.save();
    // Center and scale
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 100.0;
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-50, -50);

    switch (type) {
      case PieceType.king:
        _drawKing(canvas, fillPaint, strokePaint, shadowPaint);
        break;
      case PieceType.queen:
        _drawQueen(canvas, fillPaint, strokePaint, shadowPaint);
        break;
      case PieceType.rook:
        _drawRook(canvas, fillPaint, strokePaint, shadowPaint);
        break;
      case PieceType.bishop:
        _drawBishop(canvas, fillPaint, strokePaint, shadowPaint);
        break;
      case PieceType.knight:
        _drawKnight(canvas, fillPaint, strokePaint, shadowPaint);
        break;
      case PieceType.pawn:
        _drawPawn(canvas, fillPaint, strokePaint, shadowPaint);
        break;
    }

    canvas.restore();
  }

  void _drawKing(Canvas c, Paint fill, Paint stroke, Paint shadow) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 44, height: 8), shadow);
    _drawBase(c, fill, stroke, 50, 88, 36, 8);
    final bodyPath = Path()
      ..moveTo(26, 88)
      ..lineTo(30, 55)
      ..quadraticBezierTo(50, 50, 70, 55)
      ..lineTo(74, 88)
      ..close();
    c.drawPath(bodyPath, fill);
    c.drawPath(bodyPath, stroke);
    c.drawCircle(const Offset(50, 44), 14, fill);
    c.drawCircle(const Offset(50, 44), 14, stroke);
    final crossPaint = Paint()
      ..color = stroke.color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(50, 22), const Offset(50, 36), crossPaint);
    c.drawLine(const Offset(43, 29), const Offset(57, 29), crossPaint);
  }

  void _drawQueen(Canvas c, Paint fill, Paint stroke, Paint shadow) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 44, height: 8), shadow);
    _drawBase(c, fill, stroke, 50, 88, 36, 8);
    final bodyPath = Path()
      ..moveTo(26, 88)
      ..lineTo(28, 58)
      ..quadraticBezierTo(50, 54, 72, 58)
      ..lineTo(74, 88)
      ..close();
    c.drawPath(bodyPath, fill);
    c.drawPath(bodyPath, stroke);
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + (i - 2) * pi / 4;
      final px = 50 + 22 * cos(angle);
      final py = 48 + 22 * sin(angle);
      c.drawCircle(Offset(px, py), 5, fill);
      c.drawCircle(Offset(px, py), 5, stroke);
    }
    c.drawLine(const Offset(28, 58), const Offset(72, 58),
        stroke..strokeWidth = 3);
    stroke.strokeWidth = 4;
  }

  void _drawRook(Canvas c, Paint fill, Paint stroke, Paint shadow) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 44, height: 8), shadow);
    _drawBase(c, fill, stroke, 50, 88, 34, 7);
    final tower = RRect.fromRectAndRadius(
        const Rect.fromLTWH(33, 52, 34, 38), const Radius.circular(3));
    c.drawRRect(tower, fill);
    c.drawRRect(tower, stroke);
    for (int i = 0; i < 3; i++) {
      final bx = 33 + i * 12.0;
      final b = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + 1, 38, 9, 15), const Radius.circular(2));
      c.drawRRect(b, fill);
      c.drawRRect(b, stroke);
    }
  }

  void _drawBishop(Canvas c, Paint fill, Paint stroke, Paint shadow) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 44, height: 8), shadow);
    _drawBase(c, fill, stroke, 50, 88, 30, 7);
    final body = Path()
      ..moveTo(32, 88)
      ..lineTo(34, 62)
      ..quadraticBezierTo(50, 56, 66, 62)
      ..lineTo(68, 88)
      ..close();
    c.drawPath(body, fill);
    c.drawPath(body, stroke);
    final mitre = Path()
      ..moveTo(50, 20)
      ..quadraticBezierTo(62, 42, 60, 58)
      ..lineTo(40, 58)
      ..quadraticBezierTo(38, 42, 50, 20)
      ..close();
    c.drawPath(mitre, fill);
    c.drawPath(mitre, stroke);
    c.drawCircle(const Offset(50, 20), 5, fill);
    c.drawCircle(const Offset(50, 20), 5, stroke);
    c.drawLine(const Offset(38, 58), const Offset(62, 58),
        stroke..strokeWidth = 3);
    stroke.strokeWidth = 4;
  }

  void _drawKnight(Canvas c, Paint fill, Paint stroke, Paint shadow) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 44, height: 8), shadow);
    _drawBase(c, fill, stroke, 50, 88, 32, 7);
    final horse = Path()
      ..moveTo(32, 88)
      ..lineTo(32, 70)
      ..lineTo(30, 58)
      ..quadraticBezierTo(32, 42, 42, 38)
      ..lineTo(42, 28)
      ..quadraticBezierTo(55, 20, 68, 30)
      ..quadraticBezierTo(70, 42, 60, 50)
      ..quadraticBezierTo(68, 55, 66, 62)
      ..quadraticBezierTo(70, 68, 68, 88)
      ..close();
    c.drawPath(horse, fill);
    c.drawPath(horse, stroke);
    final ear = Path()
      ..moveTo(50, 24)
      ..lineTo(46, 14)
      ..lineTo(54, 20)
      ..close();
    c.drawPath(ear, fill);
    c.drawPath(ear, stroke);
    c.drawCircle(const Offset(61, 36), 3,
        Paint()..color = stroke.color..style = PaintingStyle.fill);
  }

  void _drawPawn(Canvas c, Paint fill, Paint stroke, Paint shadow) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 38, height: 7), shadow);
    _drawBase(c, fill, stroke, 50, 88, 26, 6);
    final stem = RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 60, 14, 26), const Radius.circular(4));
    c.drawRRect(stem, fill);
    c.drawRRect(stem, stroke);
    c.drawCircle(const Offset(50, 48), 14, fill);
    c.drawCircle(const Offset(50, 48), 14, stroke);
  }

  void _drawBase(Canvas c, Paint fill, Paint stroke, double cx, double cy,
      double w, double h) {
    final base = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - h / 2), width: w, height: h),
        const Radius.circular(4));
    c.drawRRect(base, fill);
    c.drawRRect(base, stroke);
  }

  @override
  bool shouldRepaint(ChessPiecePainter old) =>
      old.type != type || old.color != color;
}

/// Widget wrapper for ChessPiecePainter / SVG assets / PNG assets
class PieceWidget extends StatelessWidget {
  final PieceType type;
  final PieceColor color;
  final double size;
  final bool selected;
  final PieceTheme pieceTheme;

  const PieceWidget({
    super.key,
    required this.type,
    required this.color,
    required this.size,
    this.selected = false,
    this.pieceTheme = PieceTheme.alpha,
  });

  String get _svgPath {
    final prefix = color == PieceColor.white ? 'w' : 'b';
    final char = type == PieceType.pawn
        ? 'P'
        : type == PieceType.knight
            ? 'N'
            : type == PieceType.bishop
                ? 'B'
                : type == PieceType.rook
                    ? 'R'
                    : type == PieceType.queen
                        ? 'Q'
                        : 'K';
    final folder = pieceTheme == PieceTheme.alpha
        ? 'alpha/'
        : pieceTheme == PieceTheme.totoy
            ? 'totoy/'
            : pieceTheme == PieceTheme.fantasy
                ? 'fantasy/'
                : '';
    return 'assets/pieces/$folder$prefix$char.svg';
  }

  String get _assetPngPath {
    final prefix = color == PieceColor.white ? 'w' : 'b';
    return 'assets/pieces/${prefix}_${type.name}.png';
  }

  @override
  Widget build(BuildContext context) {
    final customPainterWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ChessPiecePainter(type: type, color: color),
      ),
    );

    final childWidget = SvgPicture.asset(
      _svgPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        _assetPngPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => customPainterWidget,
      ),
    );

    return AnimatedScale(
      scale: selected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: SizedBox(
        width: size,
        height: size,
        child: childWidget,
      ),
    );
  }
}
