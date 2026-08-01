import 'package:flutter/material.dart';
import 'package:royalgambit/core/constants/app_colors.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final VoidCallback onUpdate;

  const ForceUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(28),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container with Soft Gold Aura
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.15),
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Update Required',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 10),

          // Message Body
          Text(
            'A new version of Royal Gambit is available. Please update to the latest version to continue playing.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 24),

          // Update Now Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onUpdate,
              icon: const Icon(Icons.download_rounded, size: 22, color: Color(0xFF121212)),
              label: const Text(
                'UPDATE NOW',
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
