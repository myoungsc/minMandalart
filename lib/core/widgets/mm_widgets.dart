import 'dart:ui' show PathMetric;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// 점선 테두리. 빈 칸을 나타낸다.
class DashedBox extends StatelessWidget {
  final double radius;
  final double strokeWidth;
  final Widget? child;

  const DashedBox({
    super.key,
    this.radius = 6,
    this.strokeWidth = 2,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(context.mm.dashed, radius, strokeWidth),
      child: child ?? const SizedBox.expand(),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  _DashedPainter(this.color, this.radius, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final dash = strokeWidth * 2.5;
    for (final PathMetric metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash * 2) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth;
}

/// 오프셋 그림자가 있는 표면. 누르면 그림자 거리만큼 이동하고 그림자가 사라진다.
class ShadowPressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Color color;
  final Color shadowColor;
  final Color? borderColor;
  final double radius;
  final double shadow;
  final String? semanticLabel;
  final Widget child;

  const ShadowPressable({
    super.key,
    required this.onTap,
    required this.color,
    required this.shadowColor,
    required this.child,
    this.borderColor,
    this.radius = 8,
    this.shadow = 3,
    this.semanticLabel,
  });

  @override
  State<ShadowPressable> createState() => _ShadowPressableState();
}

class _ShadowPressableState extends State<ShadowPressable> {
  bool _down = false;

  void _set(bool down) {
    if (widget.onTap != null) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: _down
              ? Matrix4.translationValues(widget.shadow, widget.shadow, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.radius),
            border: widget.borderColor == null
                ? null
                : Border.all(color: widget.borderColor!, width: 2),
            boxShadow: _down
                ? null
                : [
                    BoxShadow(
                      color: widget.shadowColor,
                      offset: Offset(widget.shadow, widget.shadow),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 주 버튼: 높이 56, ink 배경, accent 그림자.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const PrimaryButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Opacity(
      opacity: onTap == null ? 0.38 : 1,
      child: ShadowPressable(
        onTap: onTap,
        color: c.ink,
        shadowColor: c.accent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: c.bg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.bg,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 앱 전체에서 빈 곳을 누르면 키보드를 내린다. MaterialApp.builder에 넣는다.
Widget dismissKeyboardOnTap(BuildContext context, Widget? child) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: child,
  );
}

/// 화면 하단에 고정되는 주 버튼. Scaffold.bottomNavigationBar에 넣는다.
class BottomAction extends StatelessWidget {
  final Widget child;

  const BottomAction({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: child,
      ),
    );
  }
}

/// 입력칸: 포커스되면 accent 오프셋 그림자가 생긴다.
class MmField extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;
  final bool hasError;
  final bool emphasized;
  final int minLines;
  final int? maxLength;
  final bool singleParagraph;

  const MmField({
    super.key,
    required this.controller,
    this.hint,
    this.hasError = false,
    this.emphasized = false,
    this.minLines = 2,
    this.maxLength,
    this.singleParagraph = false,
  });

  @override
  State<MmField> createState() => _MmFieldState();
}

class _MmFieldState extends State<MmField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: _focused
              ? [BoxShadow(color: c.accent, offset: const Offset(3, 3))]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: widget.minLines + 2,
          maxLength: widget.maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: widget.singleParagraph
              ? [FilteringTextInputFormatter.deny('\n')]
              : null,
          style: TextStyle(
            color: c.ink,
            fontSize: widget.emphasized ? 17 : 15,
            fontWeight: widget.emphasized ? FontWeight.w700 : FontWeight.w400,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            errorText: widget.hasError ? '' : null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        if (required)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'common.required'.tr(),
              style: const TextStyle(
                color: MmColors.onAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class FieldHelper extends StatelessWidget {
  final String text;

  const FieldHelper(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 12, color: context.mm.muted));
}

class FieldError extends StatelessWidget {
  final String text;

  const FieldError(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(Icons.error_rounded, size: 18, color: c.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: c.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 위험 동작 확인 다이얼로그. 확인하면 true.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: context.mm.scrim,
    builder: (context) {
      final c = context.mm;
      return Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.line, width: 2),
              boxShadow: [BoxShadow(color: c.line, offset: const Offset(6, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: TextStyle(fontSize: 15, height: 1.5, color: c.muted),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: c.ink,
                          minimumSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'common.cancel'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.error,
                          foregroundColor: c.onError,
                          minimumSize: const Size(44, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return confirmed == true;
}

void showMmSnack(ScaffoldMessengerState messenger, BuildContext context, String message) {
  final c = context.mm;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 20, color: c.centerLabel),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// 시트 공통 틀: 핸들, 라벨 + 완료 버튼, 스크롤되는 내용. 키보드 위로 올라간다.
class MmSheetFrame extends StatelessWidget {
  final String label;
  final VoidCallback onDone;
  final Widget child;

  const MmSheetFrame({
    super.key,
    required this.label,
    required this.onDone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.muted,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadowPressable(
                    onTap: onDone,
                    color: c.ink,
                    shadowColor: c.accent,
                    shadow: 2,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 72, minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Text(
                            'common.done'.tr(),
                            style: TextStyle(
                              color: c.bg,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  16 + (media.viewInsets.bottom > 0 ? 0 : media.padding.bottom),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 6),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.mm.dashed,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class BackIcon extends StatelessWidget {
  const BackIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'common.back'.tr(),
      iconSize: 26,
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => Navigator.maybePop(context),
    );
  }
}
