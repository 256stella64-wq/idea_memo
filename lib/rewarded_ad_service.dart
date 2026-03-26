import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  bool get isReady => _rewardedAd != null;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android test
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS test
    }
    throw UnsupportedError('Unsupported platform');
  }

  Future<void> load() async {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              load(); // 次回用を先読み
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              load();
              debugPrint('Rewarded failed to show: $error');
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
          debugPrint('Rewarded failed to load: $error');
        },
      ),
    );
  }

  Future<bool> show({
    required VoidCallback onUserEarnedReward,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      await load();
      return false;
    }

    _rewardedAd = null;

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward();
      },
    );

    return true;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}