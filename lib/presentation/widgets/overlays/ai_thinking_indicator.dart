import 'package:flutter/material.dart';
import 'package:royalgambit/core/constants/app_colors.dart';

class AiThinkingIndicator extends StatefulWidget {
  const AiThinkingIndicator({super.key});

  @override
  State<AiThinkingIndicator> createState() => _AiThinkingIndicatorState();
}

class _AiThinkingIndicatorState extends State<AiThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accent.withOpacity((_anim.value * 0.6).clamp(0.0, 1.0)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity((_anim.value * 0.15).clamp(0.0, 1.0)),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              size: 18,
              color: AppColors.accent.withOpacity(_anim.value.clamp(0.0, 1.0)),
            ),
            const SizedBox(width: 8),
            Text(
              'AI thinking...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.accent.withOpacity(_anim.value.clamp(0.0, 1.0)),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            _DotsIndicator(anim: _anim),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final Animation<double> anim;
  const _DotsIndicator({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: anim,
          builder: (_, __) {
            final delay = i * 0.33;
            final t = ((anim.value + delay) % 1.0).clamp(0.0, 1.0);
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(t),
              ),
            );
          },
        );
      }),
    );
  }
}
