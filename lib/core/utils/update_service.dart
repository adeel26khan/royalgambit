import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:royalgambit/presentation/widgets/overlays/force_update_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  // Package / App Store Links
  static const String _androidPackageName = 'com.azmi.royalgambit';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_androidPackageName';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/id6400000000'; // Replace with actual iOS App Store link when published

  String _currentVersion = '1.0.0';
  int _currentBuildNumber = 1;

  String get currentVersion => _currentVersion;
  int get currentBuildNumber => _currentBuildNumber;

  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
      _currentBuildNumber = int.tryParse(info.buildNumber) ?? 1;
      debugPrint('App Version: $_currentVersion+$_currentBuildNumber');
    } catch (e) {
      debugPrint('Error getting PackageInfo: $e');
    }
  }

  /// Checks if a force update is required on app startup.
  /// Set [minRequiredVersion] or [minRequiredBuild] when deploying mandatory updates.
  Future<void> checkForUpdate(
    BuildContext context, {
    String? minRequiredVersion,
    int? minRequiredBuild,
    bool forceUpdateTest = false,
  }) async {
    if (kIsWeb) return; // Skip web platforms

    await init();

    bool needsUpdate = forceUpdateTest;

    if (minRequiredBuild != null && _currentBuildNumber < minRequiredBuild) {
      needsUpdate = true;
    } else if (minRequiredVersion != null &&
        _isVersionOlder(_currentVersion, minRequiredVersion)) {
      needsUpdate = true;
    }

    if (needsUpdate && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // Non-dismissible Force Update
        builder: (ctx) => PopScope(
          canPop: false, // Prevent back button pop
          child: ForceUpdateDialog(
            currentVersion: _currentVersion,
            onUpdate: openStore,
          ),
        ),
      );
    }
  }

  /// Opens Google Play Store (Android) or App Store (iOS)
  Future<void> openStore() async {
    final Uri uri;
    if (!kIsWeb && Platform.isAndroid) {
      uri = Uri.parse('market://details?id=$_androidPackageName');
    } else if (!kIsWeb && Platform.isIOS) {
      uri = Uri.parse(_appStoreUrl);
    } else {
      uri = Uri.parse(_playStoreUrl);
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse(_playStoreUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening store URL: $e');
    }
  }

  bool _isVersionOlder(String current, String required) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final requiredParts = required.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final cur = i < currentParts.length ? currentParts[i] : 0;
        final req = i < requiredParts.length ? requiredParts[i] : 0;
        if (cur < req) return true;
        if (cur > req) return false;
      }
    } catch (_) {}
    return false;
  }
}
