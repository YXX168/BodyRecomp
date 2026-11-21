import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String themePreferenceKey = 'recomp_theme_v6';

/// Preserves v6 enum order so persisted `recomp_theme_v6` indices stay compatible.
enum AppTheme { blue, pink, orange, purple, green, dark }

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final String name;
  final String tagline;
  final bool isDark;
  final Color canvas;
  final Color ambientGlow;
  final Color orb1;
  final Color orb2;
  final Color orb3;
  final Color glassFillTop;
  final Color glassFillBottom;
  final Color glassRimBright;
  final Color glassRimAccent;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color primary;
  final Color primaryBright;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderSubtle;
  final Color borderHighlight;
  final Color success;
  final Color warning;
  final Color danger;
  final Color dockBg;

  const AppPalette({
    required this.name,
    required this.tagline,
    required this.isDark,
    required this.canvas,
    required this.ambientGlow,
    required this.orb1,
    required this.orb2,
    required this.orb3,
    required this.glassFillTop,
    required this.glassFillBottom,
    required this.glassRimBright,
    required this.glassRimAccent,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.primary,
    required this.primaryBright,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderSubtle,
    required this.borderHighlight,
    required this.success,
    required this.warning,
    required this.danger,
    required this.dockBg,
  });

  Color get onPrimary => isDark ? const Color(0xFF04140F) : Colors.white;

  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary,
          isDark ? primaryBright : Color.lerp(primary, primaryBright, 0.38)!,
        ],
      );

  static const Map<AppTheme, AppPalette> presets = {
    AppTheme.blue: AppPalette(
      name: '极光青琉 · 透璃',
      tagline: '深邃海夜与柔光翡青琉璃',
      isDark: true,
      canvas: Color(0xFF070B12),
      ambientGlow: Color(0xFF2EE59D),
      orb1: Color(0xFF15D89B),
      orb2: Color(0xFF2563EB),
      orb3: Color(0xFF0EA5E9),
      glassFillTop: Color(0x1EFFFFFF),
      glassFillBottom: Color(0x0A152538),
      glassRimBright: Color(0x45FFFFFF),
      glassRimAccent: Color(0x382EE59D),
      surface: Color(0x1C141F2E),
      surfaceElevated: Color(0xE8101824),
      surfaceMuted: Color(0x1AFFFFFF),
      primary: Color(0xFF2EE59D),
      primaryBright: Color(0xFF8CEB6A),
      accent: Color(0xFF38BDF8),
      accentSoft: Color(0xFF122C40),
      textPrimary: Color(0xFFF3F7FC),
      textSecondary: Color(0xFF9EB0C5),
      textTertiary: Color(0xFF6B7E94),
      borderSubtle: Color(0x1FFFFFFF),
      borderHighlight: Color(0x662EE59D),
      success: Color(0xFF2EE59D),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xB80E1520),
    ),
    AppTheme.green: AppPalette(
      name: '冰川晨露 · 水晶',
      tagline: '清透日光与柔雾翡翠水晶',
      isDark: false,
      canvas: Color(0xFFEBF2EF),
      ambientGlow: Color(0xFF10B981),
      orb1: Color(0xFF34D399),
      orb2: Color(0xFF38BDF8),
      orb3: Color(0xFFA7F3D0),
      glassFillTop: Color(0xC2FFFFFF),
      glassFillBottom: Color(0x80F6FBF9),
      glassRimBright: Color(0xF0FFFFFF),
      glassRimAccent: Color(0x3810B981),
      surface: Color(0xB3FFFFFF),
      surfaceElevated: Color(0xF2F8FCFA),
      surfaceMuted: Color(0x8AFFFFFF),
      primary: Color(0xFF0B7A59),
      primaryBright: Color(0xFF24C7A6),
      accent: Color(0xFF0284C7),
      accentSoft: Color(0xFFD7F4E8),
      textPrimary: Color(0xFF101D20),
      textSecondary: Color(0xFF4C6168),
      textTertiary: Color(0xFF7B8E95),
      borderSubtle: Color(0x160F2420),
      borderHighlight: Color(0x5C0B7A59),
      success: Color(0xFF0B7A59),
      warning: Color(0xFFD97706),
      danger: Color(0xFFE11D48),
      dockBg: Color(0xCCFFFFFF),
    ),
    AppTheme.orange: AppPalette(
      name: '熔琉琥珀 · 炽光',
      tagline: '深炭空间与柔暖琥珀流彩',
      isDark: true,
      canvas: Color(0xFF0D0908),
      ambientGlow: Color(0xFFFF6A3D),
      orb1: Color(0xFFEB592D),
      orb2: Color(0xFFD97706),
      orb3: Color(0xFFDB2777),
      glassFillTop: Color(0x1CFFF5EE),
      glassFillBottom: Color(0x0A241612),
      glassRimBright: Color(0x42FFE9D8),
      glassRimAccent: Color(0x3DFFA057),
      surface: Color(0x1C1D1412),
      surfaceElevated: Color(0xE8191210),
      surfaceMuted: Color(0x1AFFFFFF),
      primary: Color(0xFFFF7242),
      primaryBright: Color(0xFFFFB454),
      accent: Color(0xFFF59E0B),
      accentSoft: Color(0xFF3A2013),
      textPrimary: Color(0xFFFAF6F2),
      textSecondary: Color(0xFFBBA89F),
      textTertiary: Color(0xFF7D6B63),
      borderSubtle: Color(0x1EFFF0E6),
      borderHighlight: Color(0x66FF7242),
      success: Color(0xFF34D399),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xB818110F),
    ),
    AppTheme.purple: AppPalette(
      name: '星云幻琉 · 暮光',
      tagline: '深空暮色与柔紫霓虹玻璃',
      isDark: true,
      canvas: Color(0xFF080715),
      ambientGlow: Color(0xFFA78BFA),
      orb1: Color(0xFF7C3AED),
      orb2: Color(0xFF0284C7),
      orb3: Color(0xFFDB2777),
      glassFillTop: Color(0x1EF5F0FF),
      glassFillBottom: Color(0x0B1A1538),
      glassRimBright: Color(0x45FFFFFF),
      glassRimAccent: Color(0x3DA78BFA),
      surface: Color(0x1E16132E),
      surfaceElevated: Color(0xE814112B),
      surfaceMuted: Color(0x1AFFFFFF),
      primary: Color(0xFFA78BFA),
      primaryBright: Color(0xFFF472B6),
      accent: Color(0xFF38BDF8),
      accentSoft: Color(0xFF251F4E),
      textPrimary: Color(0xFFF7F5FF),
      textSecondary: Color(0xFFB3ABD4),
      textTertiary: Color(0xFF766F9A),
      borderSubtle: Color(0x1FFFFFFF),
      borderHighlight: Color(0x66A78BFA),
      success: Color(0xFF34D399),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xB8121026),
    ),
    AppTheme.pink: AppPalette(
      name: '绯樱琉璃 · 透粉',
      tagline: '轻透晨雾与柔和玫瑰粉晶',
      isDark: false,
      canvas: Color(0xFFF6ECF2),
      ambientGlow: Color(0xFFEC4899),
      orb1: Color(0xFFF472B6),
      orb2: Color(0xFFA78BFA),
      orb3: Color(0xFFFECDD3),
      glassFillTop: Color(0xC4FFFFFF),
      glassFillBottom: Color(0x82FFF5FA),
      glassRimBright: Color(0xF0FFFFFF),
      glassRimAccent: Color(0x38EC4899),
      surface: Color(0xB5FFFFFF),
      surfaceElevated: Color(0xF2FFF9FC),
      surfaceMuted: Color(0x8AFFFFFF),
      primary: Color(0xFFD62976),
      primaryBright: Color(0xFFF472B6),
      accent: Color(0xFF8B5CF6),
      accentSoft: Color(0xFFFCE7F3),
      textPrimary: Color(0xFF241426),
      textSecondary: Color(0xFF634E67),
      textTertiary: Color(0xFF917D96),
      borderSubtle: Color(0x162A1024),
      borderHighlight: Color(0x5CD62976),
      success: Color(0xFF059669),
      warning: Color(0xFFD97706),
      danger: Color(0xFFE11D48),
      dockBg: Color(0xCCFFFFFF),
    ),
    AppTheme.dark: AppPalette(
      name: '液态钛银 · 冰蓝',
      tagline: '极简石墨黑与冷冽冰蓝透璃',
      isDark: true,
      canvas: Color(0xFF06080D),
      ambientGlow: Color(0xFF38BDF8),
      orb1: Color(0xFF0EA5E9),
      orb2: Color(0xFF4F46E5),
      orb3: Color(0xFF64748B),
      glassFillTop: Color(0x1CF0F7FF),
      glassFillBottom: Color(0x0A111A28),
      glassRimBright: Color(0x47FFFFFF),
      glassRimAccent: Color(0x3838BDF8),
      surface: Color(0x1C111723),
      surfaceElevated: Color(0xE80E131D),
      surfaceMuted: Color(0x1AFFFFFF),
      primary: Color(0xFF38BDF8),
      primaryBright: Color(0xFF93E2FD),
      accent: Color(0xFFE2E8F0),
      accentSoft: Color(0xFF152638),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFFA2B3C7),
      textTertiary: Color(0xFF66788E),
      borderSubtle: Color(0x1FFFFFFF),
      borderHighlight: Color(0x6638BDF8),
      success: Color(0xFF34D399),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xB80C111B),
    ),
  };

  static AppPalette forTheme(AppTheme theme) =>
      presets[theme] ?? presets[AppTheme.blue]!;

  @override
  AppPalette copyWith({
    String? name,
    String? tagline,
    bool? isDark,
    Color? canvas,
    Color? ambientGlow,
    Color? orb1,
    Color? orb2,
    Color? orb3,
    Color? glassFillTop,
    Color? glassFillBottom,
    Color? glassRimBright,
    Color? glassRimAccent,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceMuted,
    Color? primary,
    Color? primaryBright,
    Color? accent,
    Color? accentSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? borderSubtle,
    Color? borderHighlight,
    Color? success,
    Color? warning,
    Color? danger,
    Color? dockBg,
  }) =>
      AppPalette(
        name: name ?? this.name,
        tagline: tagline ?? this.tagline,
        isDark: isDark ?? this.isDark,
        canvas: canvas ?? this.canvas,
        ambientGlow: ambientGlow ?? this.ambientGlow,
        orb1: orb1 ?? this.orb1,
        orb2: orb2 ?? this.orb2,
        orb3: orb3 ?? this.orb3,
        glassFillTop: glassFillTop ?? this.glassFillTop,
        glassFillBottom: glassFillBottom ?? this.glassFillBottom,
        glassRimBright: glassRimBright ?? this.glassRimBright,
        glassRimAccent: glassRimAccent ?? this.glassRimAccent,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        primary: primary ?? this.primary,
        primaryBright: primaryBright ?? this.primaryBright,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        borderSubtle: borderSubtle ?? this.borderSubtle,
        borderHighlight: borderHighlight ?? this.borderHighlight,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        dockBg: dockBg ?? this.dockBg,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      name: t < 0.5 ? name : other.name,
      tagline: t < 0.5 ? tagline : other.tagline,
      isDark: t < 0.5 ? isDark : other.isDark,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      ambientGlow: Color.lerp(ambientGlow, other.ambientGlow, t)!,
      orb1: Color.lerp(orb1, other.orb1, t)!,
      orb2: Color.lerp(orb2, other.orb2, t)!,
      orb3: Color.lerp(orb3, other.orb3, t)!,
      glassFillTop: Color.lerp(glassFillTop, other.glassFillTop, t)!,
      glassFillBottom: Color.lerp(glassFillBottom, other.glassFillBottom, t)!,
      glassRimBright: Color.lerp(glassRimBright, other.glassRimBright, t)!,
      glassRimAccent: Color.lerp(glassRimAccent, other.glassRimAccent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryBright: Color.lerp(primaryBright, other.primaryBright, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderHighlight: Color.lerp(borderHighlight, other.borderHighlight, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dockBg: Color.lerp(dockBg, other.dockBg, t)!,
    );
  }
}

ThemeData buildThemeData(AppTheme mode) {
  final p = AppPalette.forTheme(mode);
  final brightness = p.isDark ? Brightness.dark : Brightness.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primary.withValues(alpha: p.isDark ? .18 : .12),
    onPrimaryContainer: p.primary,
    secondary: p.accent,
    onSecondary: p.isDark ? const Color(0xFF08111A) : Colors.white,
    secondaryContainer: p.accentSoft,
    onSecondaryContainer: p.textPrimary,
    surface: p.surfaceElevated,
    onSurface: p.textPrimary,
    surfaceContainerHighest: p.surfaceElevated,
    onSurfaceVariant: p.textSecondary,
    outline: p.borderSubtle,
    outlineVariant: p.borderSubtle,
    error: p.danger,
    onError: Colors.white,
  );

  final baseText =
      (p.isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
          .apply(
    fontFamily: 'Inter',
    bodyColor: p.textPrimary,
    displayColor: p.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: p.canvas,
    hintColor: p.textTertiary,
    dividerColor: p.borderSubtle,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: [p],
    textTheme: baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.45,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.4,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: 11.5,
        color: p.textSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: p.textPrimary,
      systemOverlayStyle:
          p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: p.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: p.borderSubtle),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: p.glassRimBright.withValues(alpha: .35)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.glassRimBright.withValues(alpha: .35)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.borderSubtle),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.isDark
          ? Colors.white.withValues(alpha: .07)
          : Colors.white.withValues(alpha: .72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(fontSize: 13, color: p.textTertiary),
      labelStyle: TextStyle(fontSize: 13, color: p.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.danger, width: 1.4),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(
          color: p.glassRimBright.withValues(alpha: p.isDark ? .42 : .85),
          width: 1.0,
        ),
      ),
      headerBackgroundColor: Color.alphaBlend(
        p.primary.withValues(alpha: p.isDark ? .14 : .08),
        p.surfaceElevated,
      ),
      headerForegroundColor: p.textPrimary,
      headerHeadlineStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: p.textPrimary,
      ),
      headerHelpStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: p.primary,
      ),
      weekdayStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: p.textSecondary,
      ),
      dayStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return p.textTertiary.withValues(alpha: .42);
        }
        if (states.contains(WidgetState.selected)) return p.onPrimary;
        return p.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.primary;
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.onPrimary;
        return p.primary;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.primary;
        return p.primary.withValues(alpha: p.isDark ? .14 : .10);
      }),
      todayBorder: BorderSide(
        color: p.primary.withValues(alpha: .65),
        width: 1.1,
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return p.textTertiary.withValues(alpha: .42);
        }
        if (states.contains(WidgetState.selected)) return p.onPrimary;
        return p.textPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return p.primary;
        return Colors.transparent;
      }),
      dividerColor: p.borderSubtle,
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: p.textSecondary,
      ),
      confirmButtonStyle: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceElevated,
      elevation: 0,
      contentTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: p.textPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: p.glassRimBright.withValues(alpha: p.isDark ? .34 : .78),
        ),
      ),
    ),
  );
}

class ThemeController extends ChangeNotifier {
  AppTheme _current;
  Future<void> _writes = Future<void>.value();

  ThemeController([this._current = AppTheme.blue]);

  AppTheme get current => _current;
  AppPalette get palette => AppPalette.forTheme(_current);
  ThemeData get themeData => buildThemeData(_current);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(themePreferenceKey) ?? 0;
    final next = AppTheme.values[idx.clamp(0, AppTheme.values.length - 1)];
    if (next != _current) {
      _current = next;
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme mode) {
    if (_current != mode) {
      _current = mode;
      notifyListeners();
    }
    final next = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(themePreferenceKey, mode.index);
    });
    _writes = next.catchError((Object _) {});
    return next;
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.notifier;

  static ThemeController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No ThemeScope found in context');
    return controller!;
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette {
    final ext = Theme.of(this).extension<AppPalette>();
    if (ext != null) return ext;
    final scope = ThemeScope.maybeOf(this);
    if (scope != null) return scope.palette;
    final dark = Theme.of(this).brightness == Brightness.dark;
    return AppPalette.forTheme(dark ? AppTheme.blue : AppTheme.green);
  }

  ThemeController? get themeController => ThemeScope.maybeOf(this);
}
