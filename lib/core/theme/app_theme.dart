import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 디자인 토큰 (방향 1b, 그래픽 타일). 색상은 `context.mm`으로 읽는다.
class MmColors extends ThemeExtension<MmColors> {
  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color tile;
  final Color dashed;
  final Color center;
  final Color onCenter;
  final Color centerLabel;
  final Color error;
  final Color onError;
  final Color scrim;

  const MmColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.tile,
    required this.dashed,
    required this.center,
    required this.onCenter,
    required this.centerLabel,
    required this.error,
    required this.onError,
    required this.scrim,
  });

  /// accent 위 글자는 테마와 관계없이 이 색을 쓴다.
  static const Color onAccent = Color(0xFF121212);

  static const light = MmColors(
    bg: Color(0xFFF3F2EE),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF121212),
    muted: Color(0xFF555555),
    line: Color(0xFF121212),
    accent: Color(0xFFF2C230),
    accentSoft: Color(0xFFFAE29A),
    tile: Color(0xFFE6E4DD),
    dashed: Color(0xFF767676),
    center: Color(0xFF121212),
    onCenter: Color(0xFFFFFFFF),
    centerLabel: Color(0xFFF2C230),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    scrim: Color(0x73000000),
  );

  static const dark = MmColors(
    bg: Color(0xFF121212),
    surface: Color(0xFF1E1E1C),
    ink: Color(0xFFF3F2EE),
    muted: Color(0xFFB3B0A8),
    line: Color(0xFFCFCCC4),
    accent: Color(0xFFF2C230),
    accentSoft: Color(0xFF4D3F10),
    tile: Color(0xFF2A2A28),
    dashed: Color(0xFF8E8B84),
    center: Color(0xFFF3F2EE),
    onCenter: Color(0xFF121212),
    centerLabel: Color(0xFF7A5A00),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    scrim: Color(0x99000000),
  );

  @override
  MmColors copyWith() => this;

  @override
  MmColors lerp(covariant MmColors? other, double t) =>
      other != null && t >= 0.5 ? other : this;
}

extension MmColorsContext on BuildContext {
  MmColors get mm => Theme.of(this).extension<MmColors>()!;
}

class AppTheme {
  static final ThemeData lightTheme = _build(MmColors.light, Brightness.light);
  static final ThemeData darkTheme = _build(MmColors.dark, Brightness.dark);

  static ThemeData _build(MmColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: c.line, width: 2),
    );
    final errorBorder = border.copyWith(
      borderSide: BorderSide(color: c.error, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [c],
      scaffoldBackgroundColor: c.bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.tile,
      hoverColor: c.tile,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.ink,
        onPrimary: c.bg,
        secondary: c.accent,
        onSecondary: MmColors.onAccent,
        surface: c.surface,
        onSurface: c.ink,
        error: c.error,
        onError: c.onError,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: c.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: TextStyle(color: c.muted, fontWeight: FontWeight.w400),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.accent.withValues(alpha: 0.5),
        selectionHandleColor: c.ink,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        elevation: 0,
        modalElevation: 0,
        constraints: const BoxConstraints(maxWidth: 560),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.line, width: 2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentTextStyle: TextStyle(
          color: c.bg,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: c.line, width: 2),
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.ink : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(c.bg),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.ink : c.tile,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.ink : c.muted,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.muted,
        ),
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Icon(Icons.check_rounded, color: MmColors.onAccent)
              : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.ink),
    );
  }
}
