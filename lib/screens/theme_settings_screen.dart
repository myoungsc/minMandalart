import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('theme.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildThemeOption(
            context,
            ref,
            icon: Icons.light_mode_outlined,
            title: 'theme.light_mode'.tr(),
            description: 'theme.light_mode_desc'.tr(),
            themeMode: ThemeMode.light,
            isSelected: settings.themeMode == ThemeMode.light,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.dark_mode_outlined,
            title: 'theme.dark_mode'.tr(),
            description: 'theme.dark_mode_desc'.tr(),
            themeMode: ThemeMode.dark,
            isSelected: settings.themeMode == ThemeMode.dark,
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.settings_suggest_outlined,
            title: 'theme.system_mode'.tr(),
            description: 'theme.system_mode_desc'.tr(),
            themeMode: ThemeMode.system,
            isSelected: settings.themeMode == ThemeMode.system,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String description,
    required ThemeMode themeMode,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          ref.read(settingsProvider.notifier).setThemeMode(themeMode);
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : AppTheme.textDisabled.withValues(alpha: 0.15),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                      : AppTheme.textDisabled.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
