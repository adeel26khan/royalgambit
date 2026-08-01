import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isInitialized = false;

  // Test Ad Unit IDs (replace with your real AdMob Ad Unit IDs in production)
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android Test Rewarded ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded ID
    }
    return '';
  }

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdMob Initialization Error: $e');
    }
  }

  void loadRewardedAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_rewardedAd != null || _isAdLoading) return;

    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('RewardedAd loaded successfully.');
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Shows the Rewarded Ad to the user.
  /// If the ad is not ready or platform is unsupported, [onRewardGranted] is called immediately
  /// so the user experience is never blocked.
  void showRewardedAd({
    required VoidCallback onRewardGranted,
    VoidCallback? onAdFailed,
  }) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      // Desktop / Web fallback
      onRewardGranted();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready yet. Triggering reward fallback.');
      loadRewardedAd();
      onRewardGranted();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('RewardedAd showed full screen content.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('RewardedAd dismissed.');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onRewardGranted(); // Fallback reward so user isn't punished
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        onRewardGranted();
      },
    );
  }
}
