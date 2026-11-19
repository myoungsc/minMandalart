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

/// 광고 단위. 실제 ID는 빌드할 때 --dart-define 으로 넣고, 없으면 Google 테스트 ID를 쓴다.
enum AdUnit {
  homeBanner(
    String.fromEnvironment('ADMOB_HOME_BANNER_ID'),
    'ca-app-pub-3940256099942544/9214589741',
    'ca-app-pub-3940256099942544/2435281174',
  ),
  boardBanner(
    String.fromEnvironment('ADMOB_BOARD_BANNER_ID'),
    'ca-app-pub-3940256099942544/9214589741',
    'ca-app-pub-3940256099942544/2435281174',
  ),
  createInterstitial(
    String.fromEnvironment('ADMOB_CREATE_INTERSTITIAL_ID'),
    'ca-app-pub-3940256099942544/1033173712',
    'ca-app-pub-3940256099942544/4411468910',
  );

  const AdUnit(this._fromBuild, this._testAndroid, this._testIos);

  final String _fromBuild;
  final String _testAndroid;
  final String _testIos;

  String get id => _fromBuild.isNotEmpty
      ? _fromBuild
      : Platform.isAndroid
      ? _testAndroid
      : _testIos;
}

// 추적 동의(ATT)를 받지 않으므로 비개인화 광고만 요청한다.
const _request = AdRequest(nonPersonalizedAds: true);

/// 전면 광고를 미리 받아 둔다. 광고를 쓸 수 없거나 실패하면 null.
/// 받은 광고는 show() 하면 닫힐 때 스스로 정리된다. 보여 주지 않으면 dispose() 해야 한다.
Future<InterstitialAd?> loadInterstitial(WidgetRef ref, AdUnit unit) async {
  if (!ref.read(adsEnabledProvider)) return null;
  if (!await ref.read(adsReadyProvider.future)) return null;
  final done = Completer<InterstitialAd?>();
  InterstitialAd.load(
    adUnitId: unit.id,
    request: _request,
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) => ad.dispose(),
          onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
        );
        done.complete(ad);
      },
      onAdFailedToLoad: (_) => done.complete(null),
    ),
  );
  return done.future;
}

/// Scaffold.bottomNavigationBar 에 넣는 배너. 폭은 화면에 맞추고 높이는 폰 50, 태블릿 75.
/// [above]가 있으면 그 아래에 붙이고, 배너가 보일 때는 [above]의 하단 안전 영역을 배너가 맡는다.
/// 광고가 없으면 자리를 차지하지 않는다.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key, required this.unit, this.above});

  final AdUnit unit;
  final Widget? above;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
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

    // 폭은 화면에 맞추고 높이만 고정한다. 폰 50, 태블릿(짧은 변 600 이상) 75.
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final size = AdSize(width: width, height: tablet ? 75 : 50);
    await BannerAd(
      adUnitId: widget.unit.id,
      request: _request,
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
    final above = widget.above;
    final ready =
        ref.watch(adsEnabledProvider) &&
        (ref.watch(adsReadyProvider).valueOrNull ?? false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        if (ready && width != _width) _load(width);
        final ad = _ad;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (above != null)
              MediaQuery.removePadding(
                context: context,
                removeBottom: ad != null,
                child: above,
              ),
            if (ad != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.mm.bg,
                  border: Border(
                    top: BorderSide(color: context.mm.line, width: 2),
                  ),
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
              )
            // bottomNavigationBar 가 있으면 Scaffold가 본문의 하단 안전 영역을 빼므로 대신 채운다.
            else if (above == null)
              const SafeArea(
                top: false,
                child: SizedBox(width: double.infinity),
              ),
          ],
        );
      },
    );
  }
}
