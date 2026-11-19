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

  Color get onPrimary => isDark ? const Color(0xFF06130E) : Colors.white;

  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryBright],
      );

  static const Map<AppTheme, AppPalette> presets = {
    AppTheme.blue: AppPalette(
      name: '青燃曜石 · 极光',
      tagline: '深邃曜石与薄荷动能光环',
      isDark: true,
      canvas: Color(0xFF090C10),
      ambientGlow: Color(0xFF2EE59D),
      surface: Color(0xFF12171F),
      surfaceElevated: Color(0xFF1A212C),
      surfaceMuted: Color(0xFF1E2733),
      primary: Color(0xFF2EE59D),
      primaryBright: Color(0xFFB8F255),
      accent: Color(0xFF38BDF8),
      accentSoft: Color(0xFF163244),
      textPrimary: Color(0xFFF4F7FA),
      textSecondary: Color(0xFFA1B0C2),
      textTertiary: Color(0xFF64748B),
      borderSubtle: Color(0x1FFFFFFF),
      borderHighlight: Color(0x522EE59D),
      success: Color(0xFF2EE59D),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xD911161E),
    ),
    AppTheme.green: AppPalette(
      name: '青燃白昼 · 晨露',
      tagline: '柔和日光与鼠尾草建筑感白昼',
      isDark: false,
      canvas: Color(0xFFF3F6F1),
      ambientGlow: Color(0xFF10B981),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFEBF0E8),
      primary: Color(0xFF0F7657),
      primaryBright: Color(0xFF34D399),
      accent: Color(0xFF65A30D),
      accentSoft: Color(0xFFE5F3DA),
      textPrimary: Color(0xFF11181C),
      textSecondary: Color(0xFF4B5B63),
      textTertiary: Color(0xFF7C8B94),
      borderSubtle: Color(0x140F172A),
      borderHighlight: Color(0x4D0F7657),
      success: Color(0xFF0F7657),
      warning: Color(0xFFD97706),
      danger: Color(0xFFE11D48),
      dockBg: Color(0xEBFDFEFB),
    ),
    AppTheme.orange: AppPalette(
      name: '熔岩竞技 · 炽燃',
      tagline: '深炭赛道与高能琥珀橙焰',
      isDark: true,
      canvas: Color(0xFF0D0A09),
      ambientGlow: Color(0xFFFF5C28),
      surface: Color(0xFF171210),
      surfaceElevated: Color(0xFF221A17),
      surfaceMuted: Color(0xFF2B201C),
      primary: Color(0xFFFF6A3D),
      primaryBright: Color(0xFFFFB347),
      accent: Color(0xFFF59E0B),
      accentSoft: Color(0xFF3B2214),
      textPrimary: Color(0xFFFAF6F3),
      textSecondary: Color(0xFFB8A79E),
      textTertiary: Color(0xFF7D6D65),
      borderSubtle: Color(0x1FFFFFFF),
      borderHighlight: Color(0x52FF6A3D),
      success: Color(0xFF34D399),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xD916110F),
    ),
    AppTheme.purple: AppPalette(
      name: '星云深空 · 幻紫',
      tagline: '深空夜幕与霓虹星云紫光',
      isDark: true,
      canvas: Color(0xFF090812),
      ambientGlow: Color(0xFF9B72FF),
      surface: Color(0xFF131124),
      surfaceElevated: Color(0xFF1C1933),
      surfaceMuted: Color(0xFF242040),
      primary: Color(0xFF9B72FF),
      primaryBright: Color(0xFFF472B6),
      accent: Color(0xFF38BDF8),
      accentSoft: Color(0xFF25204B),
      textPrimary: Color(0xFFF5F3FF),
      textSecondary: Color(0xFFABA4C9),
      textTertiary: Color(0xFF6F6891),
      borderSubtle: Color(0x1FFFFFFF),
      borderHighlight: Color(0x529B72FF),
      success: Color(0xFF34D399),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xD9121022),
    ),
    AppTheme.pink: AppPalette(
      name: '绯樱丝绒 · 轻雾',
      tagline: '轻透晨雾与优雅玫瑰莓果色',
      isDark: false,
      canvas: Color(0xFFFAF3F7),
      ambientGlow: Color(0xFFEC4899),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFF3E5EE),
      primary: Color(0xFFDB2777),
      primaryBright: Color(0xFFF472B6),
      accent: Color(0xFF8B5CF6),
      accentSoft: Color(0xFFFCE7F3),
      textPrimary: Color(0xFF1E1320),
      textSecondary: Color(0xFF5E4B61),
      textTertiary: Color(0xFF8C778F),
      borderSubtle: Color(0x142A0F24),
      borderHighlight: Color(0x4DDB2777),
      success: Color(0xFF059669),
      warning: Color(0xFFD97706),
      danger: Color(0xFFE11D48),
      dockBg: Color(0xEBFFFDFE),
    ),
    AppTheme.dark: AppPalette(
      name: '钛金极简 · 纯粹',
      tagline: '纯黑 OLED 极简与冰蓝锐利刻度',
      isDark: true,
      canvas: Color(0xFF050608),
      ambientGlow: Color(0xFF38BDF8),
      surface: Color(0xFF101217),
      surfaceElevated: Color(0xFF181B22),
      surfaceMuted: Color(0xFF20242E),
      primary: Color(0xFF38BDF8),
      primaryBright: Color(0xFFA5F3FC),
      accent: Color(0xFFE2E8F0),
      accentSoft: Color(0xFF162738),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textTertiary: Color(0xFF5C6B7F),
      borderSubtle: Color(0x1FFFFFFF),
      borderHighlight: Color(0x5238BDF8),
      success: Color(0xFF34D399),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      dockBg: Color(0xE00C0E13),
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
    surface: p.surface,
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
    extensions: [p],
    textTheme: baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.5,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.45,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        fontSize: 11,
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
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: p.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
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
        side: BorderSide(color: p.borderSubtle),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
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
      fillColor: p.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: BorderSide(color: p.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.danger, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceElevated,
      contentTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: p.textPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.borderSubtle),
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
