import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import 'about_mandalart_screen.dart';
import 'theme_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
          _buildSectionHeader('settings.appearance_section'.tr()),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'settings.theme_title'.tr(),
            subtitle: _getThemeModeText(settings.themeMode),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('settings.info_section'.tr()),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'settings.about_mandalart_title'.tr(),
            subtitle: 'settings.about_mandalart_subtitle'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutMandalartScreen(),
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'settings.app_version_title'.tr(),
            subtitle: 'settings.app_version'.tr(),
            onTap: null,
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.textDisabled.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'settings.theme_subtitle_light'.tr();
      case ThemeMode.dark:
        return 'settings.theme_subtitle_dark'.tr();
      case ThemeMode.system:
        return 'settings.theme_subtitle_system'.tr();
    }
  }
}
