import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';

class AboutMandalartScreen extends StatelessWidget {
  const AboutMandalartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackIcon(),
        title: Text('about.title'.tr()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(child: _Illustration()),
            const SizedBox(height: 22),
            Text(
              'about.heading'.tr(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'about.intro'.tr(),
              style: const TextStyle(fontSize: 16, height: 1.65),
            ),
            const SizedBox(height: 10),
            Text(
              'about.mini_note'.tr(),
              style: TextStyle(fontSize: 15, height: 1.6, color: c.muted),
            ),
            const SizedBox(height: 22),
            Text(
              'about.how_to_use'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _Step(
              number: 1,
              text: 'about.step1'.tr(),
              fill: c.center,
              foreground: c.onCenter,
              border: c.center,
            ),
            _Step(number: 2, text: 'about.step2'.tr(), fill: c.surface, border: c.line),
            _Step(
              number: 3,
              text: 'about.step3'.tr(),
              fill: c.surface,
              progress: 0.55,
              border: c.line,
            ),
            _Step(
              number: 4,
              text: 'about.step4'.tr(),
              fill: c.accent,
              foreground: MmColors.onAccent,
              border: c.line,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;
  final Color fill;
  final Color border;
  final Color? foreground;
  final double? progress;

  const _Step({
    required this.number,
    required this.text,
    required this.fill,
    required this.border,
    this.foreground,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 40,
            child: _FilledTile(
              fill: fill,
              border: border,
              progress: progress,
              soft: c.accentSoft,
              radius: 6,
              child: Text(
                '$number',
                style: TextStyle(
                  color: foreground ?? c.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledTile extends StatelessWidget {
  final Color fill;
  final Color border;
  final Color soft;
  final double? progress;
  final double radius;
  final Widget? child;

  const _FilledTile({
    required this.fill,
    required this.border,
    required this.soft,
    required this.radius,
    this.progress,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: 2),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (progress != null)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: progress,
                    widthFactor: 1,
                    child: ColoredBox(color: soft),
                  ),
                ),
              ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    Widget tile({Color? fill, double? progress}) => _FilledTile(
      fill: fill ?? c.surface,
      border: c.line,
      soft: c.accentSoft,
      progress: progress,
      radius: 5,
    );
    return SizedBox(
      width: 150,
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            tile(),
            tile(fill: c.accent),
            tile(progress: 0.5),
            tile(progress: 0.3),
            Container(
              decoration: BoxDecoration(
                color: c.center,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(Icons.flag_rounded, size: 24, color: c.centerLabel),
            ),
            tile(fill: c.accent),
            tile(progress: 0.7),
            tile(),
            const DashedBox(radius: 5),
          ],
        ),
      ),
    );
  }
}
