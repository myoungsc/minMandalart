import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';
import '../models/goal_model.dart';

const double _cardSize = 358;
const double _outputSize = 1080;

/// 공유 미리보기. 진입하면 1080×1080 이미지를 만들고, 공유하기로 기기 공유 창을 연다.
class ShareScreen extends StatefulWidget {
  final MandalartBoard board;

  const ShareScreen({super.key, required this.board});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _cardKey = GlobalKey();
  final _buttonKey = GlobalKey();
  XFile? _image;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  /// 새 화면은 전환 첫 프레임에 아직 그려지지 않으므로, 전환이 끝나고 그려진 뒤에 캡처한다.
  Future<void> _waitUntilPainted() async {
    final animation = ModalRoute.of(context)?.animation;
    if (animation != null && !animation.isCompleted) {
      final settled = Completer<void>();
      void listener(AnimationStatus status) {
        if (status.isCompleted || status.isDismissed) {
          animation.removeStatusListener(listener);
          settled.complete();
        }
      }

      animation.addStatusListener(listener);
      await settled.future;
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _generate() async {
    setState(() => _failed = false);
    try {
      await _waitUntilPainted();
      if (!mounted) return;
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _outputSize / _cardSize);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/minimanda_${widget.board.id}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      if (mounted) setState(() => _image = XFile(file.path, mimeType: 'image/png'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _failed = true);
      _showError(e);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('common.error'.tr(namedArgs: {'error': '$e'}))),
    );
  }

  Future<void> _share() async {
    final box = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [_image!],
          // iPad에서는 공유 창을 띄울 기준 위치가 필요하다.
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    final generating = _image == null && !_failed;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackIcon(),
        title: Text('share.title'.tr()),
      ),
      bottomNavigationBar: BottomAction(
        child: KeyedSubtree(
          key: _buttonKey,
          child: PrimaryButton(
            label: 'share.button'.tr(),
            icon: Icons.ios_share_rounded,
            onTap: _failed ? _generate : (_image == null ? null : _share),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              // 좁은 화면에서는 줄여 보여 주되, 이미지는 항상 같은 크기로 만든다.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: c.line, offset: const Offset(6, 6))],
                    ),
                    child: SizedBox.square(
                      dimension: _cardSize,
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            key: _cardKey,
                            child: ShareCard(board: widget.board),
                          ),
                          if (generating)
                            Positioned.fill(
                              child: ColoredBox(
                                color: c.bg,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 14),
                                    Text(
                                      'share.generating'.tr(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: c.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  'share.hint'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 공유 이미지. 테마와 관계없이 항상 라이트 팔레트로 그린다.
class ShareCard extends StatelessWidget {
  final MandalartBoard board;

  const ShareCard({super.key, required this.board});

  static const _c = MmColors.light;

  @override
  Widget build(BuildContext context) {
    final byPosition = {for (final g in board.subGoals) g.position: g};
    return MediaQuery.withNoTextScaling(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _c.bg,
          border: Border.all(color: _c.line, width: 2),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: _c.ink),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      board.centerGoal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${board.overallProgress}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    for (int row = 0; row < 3; row++) ...[
                      if (row > 0) const SizedBox(height: 5),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (int col = 0; col < 3; col++) ...[
                              if (col > 0) const SizedBox(width: 5),
                              Expanded(child: _cell(byPosition, row * 3 + col)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'app.name'.tr(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    'home.stats'.tr(
                      namedArgs: {
                        'done': '${board.completedCount}',
                        'filled': '${board.filledCount}',
                      },
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _c.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(Map<int, Goal> byPosition, int index) {
    if (index == 4) {
      return Container(
        padding: const EdgeInsets.all(6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: _c.center,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          board.centerGoal,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _c.onCenter,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.28,
          ),
        ),
      );
    }

    final goal = byPosition[index > 4 ? index - 1 : index];
    final status = goal?.status ?? GoalStatus.empty;
    if (status == GoalStatus.empty) {
      return Theme(
        data: AppTheme.lightTheme,
        child: const DashedBox(radius: 4),
      );
    }

    final (icon, label) = switch (status) {
      GoalStatus.done => (Icons.check_circle_rounded, 'board.status_done'.tr()),
      GoalStatus.inProgress => (Icons.timelapse_rounded, '${goal!.progress}%'),
      _ => (Icons.radio_button_unchecked_rounded, 'board.status_todo'.tr()),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: status == GoalStatus.done ? _c.accent : _c.surface,
          border: Border.all(color: _c.line, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            if (status == GoalStatus.inProgress)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: goal!.progress / 100,
                    widthFactor: 1,
                    child: ColoredBox(color: _c.accentSoft),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        goal!.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MmColors.onAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.28,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(icon, size: 12, color: MmColors.onAccent),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MmColors.onAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
