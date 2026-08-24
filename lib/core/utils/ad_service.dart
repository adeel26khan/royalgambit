import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isInitialized = false;

  // Live Production Ad Unit IDs
  static const String _prodRewardedAdUnitId = 'ca-app-pub-8100492652947511/4144281218';
  static const String _prodBannerAdUnitId = 'ca-app-pub-3801513626761069/6377657301';

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917'; // Android Test Rewarded ID
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test Rewarded ID
      }
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return _prodRewardedAdUnitId;
    }
    return '';
  }

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner ID
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner ID
      }
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return _prodBannerAdUnitId;
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
          debugPrint('RewardedAd loaded successfully ($rewardedAdUnitId).');
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

/// Policy-Compliant Banner Ad Widget
/// Designed to sit cleanly at the bottom of screens with proper padding and background isolation
/// to prevent accidental clicks or UI overlaps.
class BannerAdWidget extends StatefulWidget {
  final EdgeInsetsGeometry padding;

  const BannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    final unitId = AdService.bannerAdUnitId;
    if (unitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS) || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: Center(
        child: Container(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(4),
          ),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}

