import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme/app_theme.dart';

/// 테스트에서는 false로 덮어써 광고 플러그인을 부르지 않는다.
final adsEnabledProvider = Provider<bool>((_) => true);

/// 동의(UMP, EU 등) 확인 → SDK 초기화. 광고를 요청해도 되면 true.
final adsReadyProvider = FutureProvider<bool>((ref) async {
  final done = Completer<void>();
  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () => ConsentForm.loadAndShowConsentFormIfRequired((_) => done.complete()),
    (_) => done.complete(),
  );
  await done.future;
  if (!await ConsentInformation.instance.canRequestAds()) return false;
  await MobileAds.instance.initialize();
  return true;
});

/// 빌드할 때 --dart-define=ADMOB_BANNER_ID=... 로 넣는다. 없으면 Google 테스트 배너.
const _bannerIdFromBuild = String.fromEnvironment('ADMOB_BANNER_ID');

String get _bannerId => _bannerIdFromBuild.isNotEmpty
    ? _bannerIdFromBuild
    : Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/9214589741'
    : 'ca-app-pub-3940256099942544/2435281174';

/// [child] 아래에 창 폭 앵커 적응형 배너를 붙인다.
/// 광고가 없거나 키보드가 올라와 있으면 자리를 차지하지 않는다.
class AdBannerFrame extends ConsumerStatefulWidget {
  const AdBannerFrame({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdBannerFrame> createState() => _AdBannerFrameState();
}

class _AdBannerFrameState extends ConsumerState<AdBannerFrame> {
  BannerAd? _ad;
  int? _width;

  Future<void> _load(int width) async {
    _width = width;
    // 폭이 바뀌면(회전, 폴더블) 예전 크기 광고를 내리고 새로 받는다.
    final old = _ad;
    _ad = null;
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted || width != _width) return;
    await BannerAd(
      adUnitId: _bannerId,
      // 추적 동의(ATT)를 받지 않으므로 비개인화 광고만 요청한다.
      request: const AdRequest(nonPersonalizedAds: true),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || width != _width) {
            ad.dispose();
            return;
          }
          setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    ).load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(adsEnabledProvider)) return widget.child;

    final ready = ref.watch(adsReadyProvider).valueOrNull ?? false;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (ready && width != _width) _load(width);

    final ad = _ad;
    final show = ad != null && MediaQuery.viewInsetsOf(context).bottom == 0;
    final c = context.mm;
    // 트리 모양을 바꾸지 않아야 아래 Navigator와 입력 상태가 유지된다.
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: show,
            child: widget.child,
          ),
        ),
        if (show)
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(top: BorderSide(color: c.line, width: 2)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: ad.size.height.toDouble(),
                child: Center(
                  child: SizedBox(
                    width: ad.size.width.toDouble(),
                    child: AdWidget(ad: ad),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
