import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/reminder_service.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';
import 'about_mandalart_screen.dart';

const _appVersion = '1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mm;
    final settings = ref.watch(settingsProvider);
    final selected = settings.themeMode;
    final notifier = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackIcon(),
        title: Text('settings.title'.tr()),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionLabel('settings.theme_section'.tr()),
            _Group(
              children: [
                for (final (mode, icon, label) in [
                  (ThemeMode.light, Icons.light_mode_rounded, 'settings.theme_light'.tr()),
                  (ThemeMode.dark, Icons.dark_mode_rounded, 'settings.theme_dark'.tr()),
                  (ThemeMode.system, Icons.brightness_auto_rounded, 'settings.theme_system'.tr()),
                ])
                  _Row(
                    icon: icon,
                    label: label,
                    selected: selected == mode,
                    onTap: () => notifier.setThemeMode(mode),
                    trailing: _Radio(selected: selected == mode),
                  ),
              ],
            ),
            if (reminderSupported) ...[
              const SizedBox(height: 24),
              _SectionLabel('settings.reminder_section'.tr()),
              _Group(
                children: [
                  _Row(
                    icon: Icons.notifications_rounded,
                    label: 'settings.reminder_enabled'.tr(),
                    toggled: settings.reminderEnabled,
                    onTap: () => _setReminderEnabled(context, ref, !settings.reminderEnabled),
                    // 행 전체가 스위치 역할을 하므로 스위치 자체는 스크린리더에서 뺀다.
                    trailing: ExcludeSemantics(
                      child: Switch(
                        value: settings.reminderEnabled,
                        onChanged: (on) => _setReminderEnabled(context, ref, on),
                      ),
                    ),
                  ),
                  _Row(
                    icon: Icons.schedule_rounded,
                    label: 'settings.reminder_time'.tr(),
                    enabled: settings.reminderEnabled,
                    onTap: () => _pickReminderTime(context, ref),
                    trailing: Text(
                      settings.reminderTime.format(context),
                      style: TextStyle(fontSize: 15, color: c.muted),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            _SectionLabel('settings.info_section'.tr()),
            _Group(
              children: [
                _Row(
                  icon: Icons.grid_view_rounded,
                  label: 'settings.about'.tr(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutMandalartScreen()),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, size: 22, color: c.muted),
                ),
                _Row(
                  icon: Icons.info_rounded,
                  label: 'settings.version'.tr(),
                  trailing: Text(
                    _appVersion,
                    style: TextStyle(fontSize: 15, color: c.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _setReminderEnabled(BuildContext context, WidgetRef ref, bool on) =>
    _report(context, ref.read(reminderControllerProvider.notifier).setEnabled(on));

Future<void> _pickReminderTime(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(reminderControllerProvider.notifier);
  final picked = await showTimePicker(
    context: context,
    initialTime: ref.read(settingsProvider).reminderTime,
  );
  if (picked == null || !context.mounted) return;
  await _report(context, controller.setTime(picked));
}

/// 알림 처리 결과에 맞는 안내를 띄운다.
Future<void> _report(BuildContext context, Future<ReminderOutcome> action) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (await action == ReminderOutcome.denied && context.mounted) {
      showMmSnack(messenger, context, 'settings.reminder_denied'.tr());
    }
  } catch (e) {
    if (context.mounted) {
      showMmSnack(messenger, context, 'common.error'.tr(namedArgs: {'error': '$e'}));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: context.mm.muted,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: c.tile),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final bool? selected;
  final bool? toggled;
  final bool enabled;
  final VoidCallback? onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.trailing,
    this.selected,
    this.toggled,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      // 행마다 별도 요소로 둔다. 합쳐지면 스크린리더가 행을 구분해 누를 수 없다.
      container: true,
      inMutuallyExclusiveGroup: selected != null,
      checked: selected,
      toggled: toggled,
      enabled: enabled ? null : false,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
    return enabled ? row : Opacity(opacity: 0.4, child: row);
  }
}

class _Radio extends StatelessWidget {
  final bool selected;

  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? c.ink : c.muted, width: 2),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
            )
          : null,
    );
  }
}
