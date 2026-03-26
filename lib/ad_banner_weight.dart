import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BottomBannerAd extends StatefulWidget {
  const BottomBannerAd({super.key});

  @override
  State<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends State<BottomBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int? _currentWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final width = MediaQuery.of(context).size.width.truncate();

    if (_currentWidth == width && _bannerAd != null) return;
    _currentWidth = width;

    final oldAd = _bannerAd;
    _bannerAd = null;
    _isLoaded = false;
    if (mounted) setState(() {});
    await oldAd?.dispose();

    final adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted || adSize == null) return;

    final banner = BannerAd(
      size: adSize,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android test
          : 'ca-app-pub-3940256099942544/2934735716', // iOS test
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed to load: $error');
        },
      ),
    );

    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}