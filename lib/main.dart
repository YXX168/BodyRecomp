import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/recomp_models.dart';
import 'services/data_service.dart';
import 'services/app_signals.dart';
import 'services/record_summary_service.dart';
import 'services/rest_timer_service.dart';
import 'pages/workout_page.dart';
import 'pages/nutrition_page.dart';
import 'pages/template_manager_page.dart';
export 'services/app_signals.dart';

const appVersion = '7.0.0';

// ═══════════════════════════════════════════════════════════════════════════════
// THEME SYSTEM — v6.6: profile + chart + settings support
// ═════════════════════════════════════════════════════════════════════════════==

enum AppTheme { blue, pink, orange, purple, green, dark }

class WorkoutTheme {
  final String name;
  final String emoji;
  final Color bg;
  final Color card;
  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color text4;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color border;
  final Color navbarBg;
  final bool isDark;

  const WorkoutTheme({
    required this.name,
    this.emoji = '',
    required this.bg,
    required this.card,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.text4,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.border,
    required this.navbarBg,
    this.isDark = false,
  });
}

const themes = {
  AppTheme.blue: WorkoutTheme(
    name: '原野 · 鼠尾草',
    bg: Color(0xFFF6F7F3),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF287454),
    primaryLight: Color(0xFFC9E59F),
    accent: Color(0xFFB8D791),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF287454),
    successLight: Color(0xFFC9E59F),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.pink: WorkoutTheme(
    name: '樱花飞舞 · 幻境粉',
    bg: Color(0xFFFDF2F8),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFDB2777),
    primaryLight: Color(0xFFF472B6),
    accent: Color(0xFF7C3AED),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFFDB2777),
    successLight: Color(0xFFF9A8D4),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.orange: WorkoutTheme(
    name: '落日余晖 · 熔岩橙',
    bg: Color(0xFFFFF7ED),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFFEA580C),
    primaryLight: Color(0xFFFB923C),
    accent: Color(0xFFCA8A04),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFFEA580C),
    successLight: Color(0xFFFDBA74),
    warning: Color(0xFFDC2626),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.purple: WorkoutTheme(
    name: '璀璨银河 · 星云紫',
    bg: Color(0xFFFAF5FF),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF7C3AED),
    primaryLight: Color(0xFFA78BFA),
    accent: Color(0xFFDB2777),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF7C3AED),
    successLight: Color(0xFFC4B5FD),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.green: WorkoutTheme(
    name: '深邃秘境 · 森林绿',
    bg: Color(0xFFF0FDF4),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF059669),
    primaryLight: Color(0xFF34D399),
    accent: Color(0xFF0891B2),
    text1: Color(0xFF1E293B),
    text2: Color(0xFF334155),
    text3: Color(0xFF64748B),
    text4: Color(0xFF94A3B8),
    success: Color(0xFF059669),
    successLight: Color(0xFF86EFAC),
    warning: Color(0xFFD97706),
    border: Color(0xFFE2E8F0),
    navbarBg: Color(0xFFFFFFFF),
  ),
  AppTheme.dark: WorkoutTheme(
    name: '夜色 · 深林',
    bg: Color(0xFF121A16),
    card: Color(0xFF1D2822),
    primary: Color(0xFF99BFA2),
    primaryLight: Color(0xFFD0E5BA),
    accent: Color(0xFFC5B18C),
    text1: Color(0xFFECF2EB),
    text2: Color(0xFFB5C2B8),
    text3: Color(0xFF879A8E),
    text4: Color(0xFF6E8175),
    success: Color(0xFF99BFA2),
    successLight: Color(0xFFD0E5BA),
    warning: Color(0xFFFFB800),
    border: Color(0xFF2B3B31),
    navbarBg: Color(0xFF162019),
    isDark: true,
  ),
};

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// WORKOUT DATA
// ═══════════════════════════════════════════════════════════════════════════════

const progressionPhases = [
  ('1-2 周', '学习期', '60-70% 1RM，掌握动作模式，不急着加重'),
  ('3-4 周', '适应期', '70-75% 1RM，轻松完成就加 1.25-2.5kg'),
  ('5-8 周', '增长期', '75-85% 1RM，RPE 7-8，每 1-2 周加重'),
  ('9-12 周', '突破期', '接近 85% 1RM，测 1RM，8-12 周后换动作'),
];

// ═══════════════════════════════════════════════════════════════════════════════
// v6.5: HISTORY HELPERS — ISO 周 + 真实日期归档
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATION HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class FadeScaleEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  const FadeScaleEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 35),
  });
  @override
  State<FadeScaleEntry> createState() => _FadeScaleEntryState();
}

class _FadeScaleEntryState extends State<FadeScaleEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade, _scale;
  Timer? _startTimer;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _startTimer = Timer(widget.delay * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressScale({super.key, required this.child, this.onTap});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _s = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _c.forward() : null,
      onTapUp: enabled
          ? (_) {
              _c.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => _c.reverse() : null,
      child: ScaleTransition(scale: _s, child: widget.child),
    );
  }
}

class AnimatedNote extends StatefulWidget {
  final String note;
  final bool visible;
  final Color color;
  const AnimatedNote({
    super.key,
    required this.note,
    required this.visible,
    required this.color,
  });
  @override
  State<AnimatedNote> createState() => _AnimatedNoteState();
}

class _AnimatedNoteState extends State<AnimatedNote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade, _size;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _size = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    if (widget.visible) _c.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedNote old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      widget.visible ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _size,
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.25),
              end: Offset.zero,
            ).animate(_fade),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.note,
                style: TextStyle(
                  fontSize: 10.5,
                  color: widget.color,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  const _PulseIcon({required this.icon, required this.color}) : size = 56;
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final r1op = math.max(0, 0.35 * (1 - v)).toDouble();
        final r1sz = widget.size + 28 * v;
        final v2 = (v + 0.5) % 1.0;
        final r2op = math.max(0, 0.2 * (1 - v2)).toDouble();
        final r2sz = widget.size + 20 * v2;
        final glowOp = 0.15 + 0.1 * math.sin(v * math.pi * 2);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size + 40,
              height: widget.size + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(glowOp * 0.3),
              ),
            ),
            Container(
              width: r2sz,
              height: r2sz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(r2op),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: r1sz,
              height: r1sz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(r1op),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.1),
              ),
              child: Icon(
                widget.icon,
                size: widget.size * 0.5,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}

class GradientTitle extends StatelessWidget {
  final String text;
  final Color primary;
  final Color accent;
  final double fontSize;
  const GradientTitle({
    super.key,
    required this.text,
    required this.primary,
    required this.accent,
    this.fontSize = 26,
  });
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [primary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME NOTIFIER
// ═══════════════════════════════════════════════════════════════════════════════

class ThemeInherited extends InheritedWidget {
  final AppTheme current;
  final WorkoutTheme theme;
  final Future<void> Function(AppTheme) setTheme;
  const ThemeInherited({
    super.key,
    required this.current,
    required this.theme,
    required this.setTheme,
    required super.child,
  });
  static ThemeInherited of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeInherited>()!;
  @override
  bool updateShouldNotify(covariant ThemeInherited old) =>
      current != old.current;
}

class ThemeState extends StatefulWidget {
  final Widget child;
  const ThemeState({super.key, required this.child});
  @override
  State<ThemeState> createState() => _ThemeStateState();
}

class _ThemeStateState extends State<ThemeState> {
  AppTheme _mode = AppTheme.blue;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final i = p.getInt('recomp_theme_v6') ?? 0;
      if (mounted) {
        setState(
          () => _mode = AppTheme.values[i.clamp(0, AppTheme.values.length - 1)],
        );
      }
    });
  }

  Future<void> setTheme(AppTheme m) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('recomp_theme_v6', m.index);
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _mode = m);
  }

  @override
  Widget build(BuildContext context) => ThemeInherited(
        current: _mode,
        theme: themes[_mode]!,
        setTheme: setTheme,
        child: widget.child,
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN APP
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThemeState(child: RecompApp()));
}

class RecompApp extends StatelessWidget {
  const RecompApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final inh = ThemeInherited.of(context);
        final t = inh.theme;
        final dark = t.isDark;
        return MaterialApp(
          title: 'Body Recomp',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: t.bg,
            colorScheme: ColorScheme(
              brightness: dark ? Brightness.dark : Brightness.light,
              primary: t.primary,
              onPrimary: dark ? const Color(0xFF15251B) : Colors.white,
              secondary: t.accent,
              onSecondary: Colors.white,
              surface: t.card,
              onSurface: t.text1,
              error: t.warning,
              onError: Colors.white,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: t.bg,
              foregroundColor: t.text1,
              elevation: 0,
              scrolledUnderElevation: dark ? 0.2 : 0.5,
            ),
            cardTheme: CardThemeData(
              color: t.card,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: t.border.withOpacity(dark ? 0.72 : 0.85),
                  width: 0.8,
                ),
              ),
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
            fontFamilyFallback: const ['sans-serif'],
            textTheme: (dark
                    ? ThemeData.dark().textTheme
                    : ThemeData.light().textTheme)
                .apply(fontFamily: 'Inter')
                .copyWith(
                    bodyMedium: TextStyle(fontSize: 13, color: t.text1),
                    bodySmall: TextStyle(fontSize: 11, color: t.text3),
                    titleMedium: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.text1),
                    titleLarge: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: t.text1)),
            listTileTheme: const ListTileThemeData(dense: true),
            dividerTheme: DividerThemeData(
                color: t.border.withValues(alpha: .7), thickness: .5),
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        fontFamilyFallback: const ['sans-serif']))),
            outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        fontFamilyFallback: const ['sans-serif']))),
            filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                    textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        fontFamilyFallback: const ['sans-serif']))),
          ),
          home: const MainPage(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE — v6.5: refined chrome + smoother tonal navigation
// ═══════════════════════════════════════════════════════════════════════════════

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tab = 0;
  late final List<Widget> _pages = [
    const WorkoutPage(),
    const NutritionPage(),
    const RecordPage(),
    SettingsPage(onProfileChanged: () {}),
  ];

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    const labels = ['训练', '饮食', '趋势', '我的'];
    const icons = [
      Icons.grid_view_rounded,
      Icons.restaurant_outlined,
      Icons.insights_outlined,
      Icons.person_outline_rounded
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              t.isDark ? Brightness.light : Brightness.dark),
      child: Scaffold(
        body: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 16, 8),
                  child: Row(children: [
                    Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                            color: t.primary,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.fitness_center_rounded,
                            size: 15, color: t.isDark ? t.bg : Colors.white)),
                    const SizedBox(width: 9),
                    Text('Bodyrecomp',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6,
                            color: t.text1)),
                    const Spacer(),
                    IconButton(
                        tooltip: '切换主题',
                        onPressed: _showThemeSheet,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.palette_outlined,
                            size: 20, color: t.text3)),
                  ])),
              Expanded(
                  child: IndexedStack(
                      index: _tab, sizing: StackFit.expand, children: _pages)),
            ])),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
              color: t.navbarBg,
              border: Border(
                  top: BorderSide(color: t.border.withValues(alpha: .65)))),
          child: SafeArea(
              top: false,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Row(children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                          child: InkWell(
                        key: ValueKey('nav-$i'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _tab = i);
                        },
                        child: SizedBox(
                            height: 51,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icons[i],
                                      size: 22,
                                      color: i == _tab ? t.primary : t.text4),
                                  const SizedBox(height: 4),
                                  Text(labels[i],
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontFamilyFallback: const [
                                            'sans-serif'
                                          ],
                                          fontSize: 10,
                                          fontWeight: i == _tab
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color:
                                              i == _tab ? t.text1 : t.text4)),
                                ])),
                      )),
                  ]))),
        ),
      ),
    );
  }

  void _showThemeSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final inh = ThemeInherited.of(ctx);
        final t = inh.theme;
        final cur = inh.current;
        return Container(
          decoration: BoxDecoration(
            color: t.navbarBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '主题选择',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: t.text1,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: t.border.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 18, color: t.text3),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: AppTheme.values.map((m) {
                        final mt = themes[m]!;
                        final sel = m == cur;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PressScale(
                            onTap: () {
                              inh.setTheme(m);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    sel ? mt.primary.withOpacity(0.06) : null,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel ? mt.primary : t.border,
                                  width: sel ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [mt.primary, mt.accent],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: sel
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mt.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: sel ? mt.primary : t.text1,
                                            ),
                                          ),
                                          Text(
                                            sel ? '当前使用中' : '点击切换',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: sel
                                                  ? mt.primary.withOpacity(0.7)
                                                  : t.text4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECORD PAGE — month and year summaries of actual dated workouts
// ═══════════════════════════════════════════════════════════════════════════════

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _viewYear = DateTime.now().year;
  int _viewMonth = DateTime.now().month;
  Map<int, int> _monthData = {};
  Map<int, Map<int, int>> _yearMonths = {};
  bool _loading = true;
  int _yearTotal = 0;
  int _yearTrainDays = 0;
  int _loadGeneration = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    workoutHistoryRevision.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    workoutHistoryRevision.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final generation = ++_loadGeneration;
    final year = _viewYear;
    final month = _viewMonth;
    try {
      final p = await SharedPreferences.getInstance();
      final summary = await loadRecordSummary(p, year, month);
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _monthData = summary.monthData;
          _yearMonths = summary.yearMonths;
          _yearTotal = summary.yearTotal;
          _yearTrainDays = summary.yearTrainDays;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _loading = false;
          _loadError = '训练统计读取失败，原记录未被覆盖。';
        });
      }
    }
  }

  void _prevMonth() {
    setState(() {
      _loading = true;
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_viewYear == now.year && _viewMonth == now.month) return;
    setState(() {
      _loading = true;
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
    _loadData();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _viewYear = now.year;
      _viewMonth = now.month;
      _loading = true;
    });
    _loadData();
  }

  int _totalExercises() {
    return _monthData.values.fold(0, (sum, v) => sum + v);
  }

  int _trainDays() {
    return _monthData.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday - 1;
    final now = DateTime.now();
    final isCurrentMonth = _viewYear == now.year && _viewMonth == now.month;
    final monthNames = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];
    final weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_loadError!),
        TextButton(onPressed: _loadData, child: const Text('重试'))
      ]));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: GradientTitle(
              text: '训练记录',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        // 月份选择器
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PressScale(
                  onTap: _prevMonth,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.chevron_left, size: 20, color: t.primary),
                  ),
                ),
                PressScale(
                  onTap: _goToday,
                  child: Column(
                    children: [
                      Text(
                        '$_viewYear年 ${monthNames[_viewMonth - 1]}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: t.text1,
                        ),
                      ),
                      if (isCurrentMonth)
                        Text(
                          '当前月',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: t.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                PressScale(
                  onTap: _nextMonth,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCurrentMonth
                          ? t.border.withOpacity(0.5)
                          : t.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isCurrentMonth ? t.text4 : t.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 月度统计
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FadeScaleEntry(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBlock('已练项目', '${_totalExercises()}', '个', t),
                      Container(width: 1, height: 36, color: t.border),
                      _statBlock('训练天数', '${_trainDays()}', '天', t),
                      Container(width: 1, height: 36, color: t.border),
                      _statBlock('年度累计', '$_yearTotal', '个', t),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 日历热力图
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FadeScaleEntry(
              index: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (int i = 0; i < 7; i++)
                            Expanded(
                              child: Center(
                                child: Text(
                                  weekLabels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: i >= 5 ? t.text4 : t.text3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ..._buildCalendarRows(
                        daysInMonth,
                        firstWeekday,
                        now,
                        isCurrentMonth,
                        t,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '少',
                            style: TextStyle(fontSize: 9, color: t.text4),
                          ),
                          const SizedBox(width: 4),
                          _legendDot(t, 0),
                          const SizedBox(width: 3),
                          _legendDot(t, 0.25),
                          const SizedBox(width: 3),
                          _legendDot(t, 0.5),
                          const SizedBox(width: 3),
                          _legendDot(t, 0.75),
                          const SizedBox(width: 3),
                          _legendDot(t, 1.0),
                          const SizedBox(width: 4),
                          Text(
                            '多',
                            style: TextStyle(fontSize: 9, color: t.text4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // 年度统计
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: FadeScaleEntry(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_viewYear 年度统计',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: t.text1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statBlock('年度已练', '$_yearTotal', '个项目', t),
                          _statBlock('训练天数', '$_yearTrainDays', '天', t),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 12个月迷你月历
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '全年概览',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                  ),
                ),
                const SizedBox(height: 8),
                _buildYearGrid(t),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _statBlock(String label, String value, String unit, WorkoutTheme t) {
    return Column(
      key: ValueKey('record-stat-$label'),
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: t.text4,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: t.primary,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 9, color: t.text4)),
      ],
    );
  }

  List<Widget> _buildCalendarRows(
    int daysInMonth,
    int firstWeekday,
    DateTime now,
    bool isCurrentMonth,
    WorkoutTheme t,
  ) {
    final rows = <Widget>[];
    int day = 1;
    for (int row = 0; row < 6; row++) {
      if (day > daysInMonth) break;
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col < firstWeekday) {
          cells.add(const Expanded(child: SizedBox(height: 32)));
        } else if (day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 32)));
        } else {
          final isToday = isCurrentMonth && day == now.day;
          final count = _monthData[day] ?? 0;
          final intensity = count > 0 ? (count / 8).clamp(0.0, 1.0) : 0.0;
          cells.add(
            Expanded(
              child: SizedBox(
                height: 32,
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: count == 0
                          ? Colors.transparent
                          : Color.lerp(t.card, t.successLight, intensity),
                      border: isToday
                          ? Border.all(color: t.primary, width: 2)
                          : null,
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: t.primary.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: count == 0
                              ? (isToday ? t.primary : t.text4)
                              : (intensity > 0.62 ? Colors.white : t.text1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          day++;
        }
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(children: cells),
        ),
      );
    }
    return rows;
  }

  Widget _legendDot(WorkoutTheme t, double intensity) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: intensity == 0
            ? t.border
            : Color.lerp(t.card, t.successLight, intensity),
      ),
    );
  }

  Widget _buildYearGrid(WorkoutTheme t) {
    final now = DateTime.now();
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (var month = 1; month <= 12; month++)
        _buildMiniMonth(_yearMonths[month] ?? {}, _viewYear, month, '$month', t,
            _viewYear == now.year && month == now.month),
    ]);
  }

  Widget _buildMiniMonth(
    Map<int, int> counts,
    int year,
    int month,
    String label,
    WorkoutTheme t,
    bool isCurrent,
  ) {
    final history = <String, int>{
      for (final e in counts.entries) '${e.key}': e.value
    };
    final total = history.values.fold<int>(
      0,
      (s, v) => s + v,
    );
    return Container(
      width: (MediaQuery.of(context).size.width - 32 - 24) / 4,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? t.primary : t.border,
          width: isCurrent ? 1.5 : 0.5,
        ),
        color: isCurrent ? t.primary.withOpacity(0.04) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label月',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? t.primary : t.text3,
                ),
              ),
              if (total > 0)
                Text(
                  '$total',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: t.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          ..._buildMiniGrid(year, month, history, t),
        ],
      ),
    );
  }

  List<Widget> _buildMiniGrid(
    int year,
    int month,
    Map<String, dynamic> history,
    WorkoutTheme t,
  ) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday - 1;
    final rows = <Widget>[];
    int day = 1;
    for (int row = 0; row < 6; row++) {
      if (day > daysInMonth) break;
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if (row == 0 && col < firstWeekday || day > daysInMonth) {
          cells.add(SizedBox(width: 4, height: 4));
        } else {
          final rawCount = history[day.toString()];
          final count =
              rawCount is int ? rawCount : int.tryParse('$rawCount') ?? 0;
          final intensity = count > 0 ? (count / 8).clamp(0.0, 1.0) : 0.0;
          cells.add(
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: count == 0
                    ? t.border.withOpacity(0.3)
                    : Color.lerp(t.card, t.successLight, intensity),
              ),
            ),
          );
          day++;
        }
      }
      rows.add(
        Row(mainAxisAlignment: MainAxisAlignment.center, children: cells),
      );
    }
    return rows;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NUTRITION PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ProgressionPage extends StatelessWidget {
  const ProgressionPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GradientTitle(
              text: '渐进超负荷',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              FadeScaleEntry(
                index: 0,
                child: Card(
                  color: t.primary.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '渐进超负荷是增肌的核心原则：在动作稳定、恢复充足的前提下，逐步增加重量、次数或组数，让身体持续适应。每 1-2 周尝试一次小幅进步，并记录训练表现。',
                      style: TextStyle(
                        fontSize: 12,
                        color: t.text2,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeScaleEntry(
                index: 1,
                child: Text(
                  '四阶段计划',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...progressionPhases.asMap().entries.map((e) {
                final (w, ti, d) = progressionPhases[e.key];
                return FadeScaleEntry(
                  index: e.key + 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: t.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: t.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        ti,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: t.text1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: t.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          w,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: t.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    d,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: t.text3,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              FadeScaleEntry(
                index: 7,
                child: Text(
                  '加重策略',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: t.text1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ...[
                ('上肢复合动作', '卧推 / 划船 / 推肩：每次 +1.25-2.5kg'),
                ('下肢复合动作', '倒蹬 / 硬拉 / 臀推：每次 +2.5-5kg'),
                ('孤立动作', '侧平举 / 弯举 / 下压：每次 +0.5-1kg 或 +1-2次'),
                ('遇到瓶颈', '减重 10% 重新开始，或更换动作变式刺激新角度'),
              ].asMap().entries.map(
                    (i) => FadeScaleEntry(
                      index: i.key + 8,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            i.value.$1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: t.text1,
                            ),
                          ),
                          subtitle: Text(
                            i.value.$2,
                            style: TextStyle(
                              fontSize: 11,
                              color: t.text3,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});
  @override
  Widget build(BuildContext context) {
    final inh = ThemeInherited.of(context);
    final t = inh.theme;
    final cur = inh.current;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GradientTitle(
              text: '主题选择',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final m = AppTheme.values[i];
              final mt = themes[m]!;
              final sel = m == cur;
              return FadeScaleEntry(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PressScale(
                    onTap: () => inh.setTheme(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: sel ? mt.primary.withOpacity(0.06) : null,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? mt.primary : t.border,
                          width: sel ? 2 : 1,
                        ),
                        boxShadow: sel && mt.isDark
                            ? [
                                BoxShadow(
                                  color: mt.primary.withOpacity(0.2),
                                  blurRadius: 16,
                                ),
                                BoxShadow(
                                  color: mt.accent.withOpacity(0.1),
                                  blurRadius: 24,
                                ),
                              ]
                            : sel
                                ? [
                                    BoxShadow(
                                      color: mt.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [mt.primary, mt.accent],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: sel && mt.isDark
                                    ? [
                                        BoxShadow(
                                          color: mt.primary.withOpacity(0.5),
                                          blurRadius: 12,
                                        ),
                                        BoxShadow(
                                          color: mt.accent.withOpacity(0.3),
                                          blurRadius: 16,
                                        ),
                                      ]
                                    : sel
                                        ? [
                                            BoxShadow(
                                              color:
                                                  mt.primary.withOpacity(0.3),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: sel
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 22,
                                        key: ValueKey('s'),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mt.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? mt.primary : t.text1,
                                    ),
                                  ),
                                  Text(
                                    sel ? '当前使用中' : '点击切换',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sel
                                          ? mt.primary.withOpacity(0.7)
                                          : t.text4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              padding: sel
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    )
                                  : EdgeInsets.zero,
                              decoration: sel
                                  ? BoxDecoration(
                                      color: mt.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                  : null,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? mt.primary : Colors.transparent,
                                ),
                                child: const Text('已选择'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: AppTheme.values.length),
          ),
        ),
      ],
    );
  }
}

class TrendChartPainter extends CustomPainter {
  final List<(String, double)> data; // (label, value)
  final WorkoutTheme theme;
  TrendChartPainter({required this.data, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final padding = const EdgeInsets.only(
      left: 50,
      right: 16,
      top: 16,
      bottom: 40,
    );
    final chartW = size.width - padding.left - padding.right;
    final chartH = size.height - padding.top - padding.bottom;
    final values = data.map((d) => d.$2).toList();
    double minV = values.reduce(math.min);
    double maxV = values.reduce(math.max);
    if (maxV == minV) {
      maxV += 1;
      minV -= 1;
    }
    final range = maxV - minV;
    final paint = Paint()
      ..color = theme.primary.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = theme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = theme.primary
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding.left +
          (data.length == 1 ? chartW / 2 : (i / (data.length - 1)) * chartW);
      final y = padding.top + chartH - ((data[i].$2 - minV) / range) * chartH;
      points.add(Offset(x, y));
    }
    if (points.length >= 2) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.addPath(path, Offset.zero);
      fillPath.lineTo(points.last.dx, padding.top + chartH);
      fillPath.lineTo(points.first.dx, padding.top + chartH);
      fillPath.close();
    }
    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, dotPaint);
      canvas.drawCircle(
        points[i],
        2.5,
        Paint()
          ..color = theme.bg
          ..style = PaintingStyle.fill,
      );
      textPainter.text = TextSpan(
        text: data[i].$2.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 9,
          color: theme.text3,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 20),
      );
      textPainter.text = TextSpan(
        text: data[i].$1,
        style: TextStyle(fontSize: 8, color: theme.text4),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, padding.top + chartH + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter oldDelegate) =>
      data != oldDelegate.data || theme != oldDelegate.theme;
}

class MiniTrendChart extends StatelessWidget {
  final List<(String, double)> data;
  final WorkoutTheme theme;
  const MiniTrendChart({super.key, required this.data, required this.theme});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: TrendChartPainter(data: data, theme: theme),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE — v6.6: profile, weight log, trends, import/export
// ═══════════════════════════════════════════════════════════════════════════════

class SettingsPage extends StatefulWidget {
  final VoidCallback onProfileChanged;
  const SettingsPage({super.key, required this.onProfileChanged});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  UserProfile? _profile;
  List<WeightEntry> _weightHistory = [];
  List<BodyMeasurement> _measurements = [];
  String _trendTab = 'weight'; // weight or measurements
  bool _autoRestTimer = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final profile = await loadProfile();
    final weights = await loadWeightHistory();
    final measurements = await loadMeasurements();
    final autoRestTimer = await loadAutoRestTimer();
    if (mounted) {
      setState(() {
        _profile = profile;
        _weightHistory = weights;
        _measurements = measurements;
        _autoRestTimer = autoRestTimer;
      });
    }
  }

  Future<void> _saveProfile(UserProfile p) async {
    await saveProfile(p);
    if (mounted) setState(() => _profile = p);
    widget.onProfileChanged();
  }

  Widget _trainingPreferencesCard(WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.accent.withOpacity(0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.timer_rounded, color: t.accent, size: 21),
        ),
        title: Text(
          '完成一组后自动计时',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: t.text1,
          ),
        ),
        subtitle: Text(
          '默认关闭；开启后按项目休息时长计时，补记历史不启动',
          style: TextStyle(fontSize: 11, color: t.text3),
        ),
        value: _autoRestTimer,
        activeThumbColor: t.primary,
        onChanged: (value) async {
          setState(() => _autoRestTimer = value);
          await saveAutoRestTimer(value);
          restTimerPreferenceRevision.value++;
        },
      ),
    );
  }

  Widget _workoutPlanCard(WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PressScale(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TemplateManagerPage(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: t.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '训练模板与每周参考',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: t.text1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '搭建模板、增删项目、设置每天的参考安排',
                      style: TextStyle(fontSize: 11, color: t.text3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: t.text4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeInherited.of(context).theme;
    final p = _profile;
    if (p == null) return const Center(child: CircularProgressIndicator());
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: GradientTitle(
              text: '设置',
              primary: t.primary,
              accent: t.primaryLight,
              fontSize: 22,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── 个人资料卡片 ──
              FadeScaleEntry(index: 0, child: _profileCard(p, t)),
              const SizedBox(height: 12),
              // ── 身体数据趋势 ──
              FadeScaleEntry(index: 1, child: _bodyTrendCard(t)),
              const SizedBox(height: 12),
              // ── 训练计划 ──
              FadeScaleEntry(index: 2, child: _workoutPlanCard(t)),
              const SizedBox(height: 12),
              // ── 训练偏好 ──
              FadeScaleEntry(index: 3, child: _trainingPreferencesCard(t)),
              const SizedBox(height: 12),
              Card(
                  child: ListTile(
                      leading: Icon(Icons.trending_up_rounded,
                          size: 21, color: t.primary),
                      title: const Text('训练参考', style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => Scaffold(
                                  appBar: AppBar(title: const Text('训练参考')),
                                  body: const ProgressionPage()))))),
              const SizedBox(height: 12),
              // ── 数据管理 ──
              FadeScaleEntry(index: 4, child: _dataCard(t)),
              const SizedBox(height: 12),
              // ── 主题设置 ──
              FadeScaleEntry(index: 5, child: _themeCard(t)),
              const SizedBox(height: 12),
              // ── 关于 ──
              FadeScaleEntry(
                index: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '关于',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.text3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Body Recomp v$appVersion',
                          style: TextStyle(
                            fontSize: 13,
                            color: t.text2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '健身追踪 · 趋势分析 · 数据备份',
                          style: TextStyle(fontSize: 11, color: t.text4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GitHub: YXX168/BodyRecomp',
                          style: TextStyle(fontSize: 10, color: t.text4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _themeCard(WorkoutTheme t) {
    final inh = ThemeInherited.of(context);
    final cur = inh.current;
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.palette_rounded, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '主题选择',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.values.map((m) {
                final mt = themes[m]!;
                final sel = m == cur;
                return PressScale(
                  onTap: () => inh.setTheme(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [mt.primary, mt.accent]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? t.text1 : Colors.white.withOpacity(0.75),
                        width: sel ? 2.4 : 1.0,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: mt.primary.withOpacity(
                                  t.isDark ? 0.42 : 0.24,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: sel
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('selected'),
                              color: Colors.white,
                              size: 22,
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              themes[cur]!.name,
              style: TextStyle(
                fontSize: 12,
                color: t.text3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(UserProfile p, WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline_rounded, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '个人资料',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 生日
            _profileTile(
              t,
              Icons.cake_rounded,
              '生日',
              p.birthday.isEmpty ? '未设置' : p.birthday,
              () => _editBirthday(p),
            ),
            const Divider(height: 1),
            // 性别
            _profileTile(
              t,
              Icons.wc_rounded,
              '性别',
              p.gender == 'male' ? '👨 男' : '👩 女',
              () => _editGender(p),
            ),
            const Divider(height: 1),
            // 身高
            _profileTile(
              t,
              Icons.height_rounded,
              '身高',
              '${p.heightCm.toInt()} cm',
              () => _editHeight(p),
            ),
            const Divider(height: 1),
            // 体重
            _profileTile(
              t,
              Icons.monitor_weight_rounded,
              '当前体重',
              '${p.weightKg} kg',
              () => _editWeight(p),
            ),
            const SizedBox(height: 12),
            // BMI 展示
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.primary.withOpacity(0.08),
                    t.accent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI',
                          style: TextStyle(fontSize: 11, color: t.text3),
                        ),
                        Text(
                          _bmiDisplay(p),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: t.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '状态',
                          style: TextStyle(fontSize: 11, color: t.text3),
                        ),
                        Text(
                          _bmiCategory(
                            double.tryParse(_bmiDisplay(p).split(' ')[0]),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '年龄',
                          style: TextStyle(fontSize: 11, color: t.text3),
                        ),
                        Text(
                          p.age > 0 ? '${p.age} 岁' : '--',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.text1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bmiDisplay(UserProfile p) {
    final v = p.bmi;
    if (v == 0) return '--';
    return '${v.toStringAsFixed(1)}';
  }

  String _bmiCategory(double? bmi) {
    if (bmi == null) return '未计算';
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '偏胖';
    return '肥胖';
  }

  Widget _profileTile(
    WorkoutTheme t,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: t.text3),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: t.text2)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: t.text1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: t.text4),
          ],
        ),
      ),
    );
  }

  Future<void> _editBirthday(UserProfile p) async {
    final ctrl = TextEditingController(text: p.birthday);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择生日'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            hintText: 'YYYY-MM-DD',
            labelText: '生日日期',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        DateTime.parse(result);
        _saveProfile(
          UserProfile(
            birthday: result,
            heightCm: p.heightCm,
            weightKg: p.weightKg,
            gender: p.gender,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _editGender(UserProfile p) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择性别'),
        children: ['👨 男', '👩 女']
            .map(
              (g) => SimpleDialogOption(
                child: Text(g),
                onPressed: () =>
                    Navigator.pop(ctx, g == '👨 男' ? 'male' : 'female'),
              ),
            )
            .toList(),
      ),
    );
    if (result != null) {
      _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: p.heightCm,
          weightKg: p.weightKg,
          gender: result,
        ),
      );
    }
  }

  Future<void> _editHeight(UserProfile p) async {
    final ctrl = TextEditingController(text: p.heightCm.toInt().toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置身高 (cm)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null) {
      _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: result,
          weightKg: p.weightKg,
          gender: p.gender,
        ),
      );
    }
  }

  Future<void> _editWeight(UserProfile p) async {
    final ctrl = TextEditingController(text: p.weightKg.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('记录体重 (kg)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: p.heightCm,
          weightKg: result,
          gender: p.gender,
        ),
      );
      final entries = await saveWeightEntry(
        WeightEntry(date: DateTime.now(), weightKg: result),
      );
      if (mounted) setState(() => _weightHistory = entries);
    }
  }

  Widget _bodyTrendCard(WorkoutTheme t) {
    final isWeight = _trendTab == 'weight';
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '身体数据',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
                const Spacer(),
                PressScale(
                  onTap: isWeight ? _addWeightEntry : _addMeasurement,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 14, color: t.primary),
                        Text(
                          '记录',
                          style: TextStyle(
                            fontSize: 11,
                            color: t.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: t.border.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _trendTabButton('weight', '体重', t),
                  _trendTabButton('measurements', '围度', t),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (isWeight)
              _weightTrendContent(t)
            else
              _measurementTrendContent(t),
          ],
        ),
      ),
    );
  }

  Widget _trendTabButton(String value, String label, WorkoutTheme t) {
    final selected = _trendTab == value;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _trendTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? t.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? t.primary : t.text4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _weightTrendContent(WorkoutTheme t) {
    final weights = _weightHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (weights.length < 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                '至少记录 2 次体重后显示趋势图',
                style: TextStyle(fontSize: 12, color: t.text4),
              ),
            ),
          )
        else
          MiniTrendChart(
            data: weights.length > 30
                ? weights
                    .sublist(weights.length - 30)
                    .map((e) => ('${e.date.month}/${e.date.day}', e.weightKg))
                    .toList()
                : weights
                    .map((e) => ('${e.date.month}/${e.date.day}', e.weightKg))
                    .toList(),
            theme: t,
          ),
        if (weights.isNotEmpty) ...[
          Row(
            children: [
              Text(
                '最新: ${weights.last.weightKg.toStringAsFixed(1)}kg',
                style: TextStyle(fontSize: 11, color: t.text3),
              ),
              if (weights.length >= 2)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '变化: ${weights.last.weightKg > weights[weights.length - 2].weightKg ? "+" : ""}${(weights.last.weightKg - weights[weights.length - 2].weightKg).toStringAsFixed(1)}kg',
                    style: TextStyle(
                      fontSize: 11,
                      color: weights.last.weightKg >
                              weights[weights.length - 2].weightKg
                          ? t.warning
                          : t.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...weights.reversed.take(8).map((entry) => _weightEntryRow(entry, t)),
        ],
      ],
    );
  }

  Widget _weightEntryRow(WeightEntry entry, WorkoutTheme t) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: t.text3),
            ),
          ),
          Text(
            '${entry.weightKg.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 11,
              color: t.text1,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '编辑',
            onPressed: () => _editWeightEntry(entry),
            icon: Icon(Icons.edit_outlined, size: 16, color: t.primary),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '删除',
            onPressed: () => _deleteWeightEntry(entry),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: t.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementTrendContent(WorkoutTheme t) {
    const labels = {
      'waist': '腰围',
      'chest': '胸围',
      'hip': '臀围',
      'arm': '臂围',
      'thigh': '大腿围',
    };
    final entries = _measurements;
    final waistData = entries
        .where((entry) => entry.values['waist'] != null)
        .map(
          (entry) =>
              ('${entry.date.month}/${entry.date.day}', entry.values['waist']!),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (waistData.length < 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                '记录至少 2 次腰围后显示围度趋势',
                style: TextStyle(fontSize: 12, color: t.text4),
              ),
            ),
          )
        else
          MiniTrendChart(
            data: waistData.length > 30
                ? waistData.sublist(waistData.length - 30)
                : waistData,
            theme: t,
          ),
        ...entries.reversed.take(8).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        '${entry.date.month}/${entry.date.day}',
                        style: TextStyle(fontSize: 11, color: t.text3),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.values.entries
                            .map(
                              (value) =>
                                  '${labels[value.key] ?? value.key} ${value.value.toStringAsFixed(1)}cm',
                            )
                            .join(' · '),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: t.text1,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '编辑',
                      onPressed: () => _addMeasurement(existing: entry),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: t.primary,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '删除',
                      onPressed: () => _deleteMeasurement(entry),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: t.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _addWeightEntry({WeightEntry? existing}) async {
    final date = existing?.date ?? DateTime.now();
    final ctrl = TextEditingController(
      text:
          existing?.weightKg.toString() ?? _profile?.weightKg.toString() ?? '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '记录体重 (kg)' : '编辑体重 (kg)'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '输入体重',
            labelText: '${date.year}-${date.month}-${date.day}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text);
              if (value != null && value > 0) Navigator.pop(ctx, value);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final entries = await saveWeightEntry(
      WeightEntry(date: date, weightKg: result),
    );
    if (!mounted) return;
    setState(() => _weightHistory = entries);
    if (dateOnly(date) == dateOnly(DateTime.now())) {
      final p = _profile!;
      await _saveProfile(
        UserProfile(
          birthday: p.birthday,
          heightCm: p.heightCm,
          weightKg: result,
          gender: p.gender,
        ),
      );
    }
  }

  Future<void> _editWeightEntry(WeightEntry entry) =>
      _addWeightEntry(existing: entry);

  Future<void> _deleteWeightEntry(WeightEntry entry) async {
    final confirmed = await _confirmDelete(
      '删除 ${entry.weightKg.toStringAsFixed(1)}kg 的体重记录？',
    );
    if (!confirmed) return;
    final entries = await deleteWeightEntry(entry.date);
    if (mounted) setState(() => _weightHistory = entries);
  }

  Future<void> _addMeasurement({BodyMeasurement? existing}) async {
    const fields = {
      'waist': '腰围',
      'chest': '胸围',
      'hip': '臀围',
      'arm': '臂围',
      'thigh': '大腿围',
    };
    final controllers = {
      for (final field in fields.keys)
        field: TextEditingController(
          text: existing?.values[field]?.toString() ?? '',
        ),
    };
    final values = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '记录围度 (cm)' : '编辑围度 (cm)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in fields.entries) ...[
                TextField(
                  controller: controllers[field.key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: field.value,
                    hintText: '可选',
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final result = <String, double>{};
              for (final field in controllers.entries) {
                final value = double.tryParse(field.value.text);
                if (value != null && value > 0) result[field.key] = value;
              }
              if (result.isEmpty) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(const SnackBar(content: Text('请至少填写一项围度')));
                return;
              }
              Navigator.pop(ctx, result);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (values == null) return;
    final entries = await saveMeasurement(
      BodyMeasurement(date: existing?.date ?? DateTime.now(), values: values),
      replaceSameDay: existing != null,
    );
    if (mounted) setState(() => _measurements = entries);
  }

  Future<void> _deleteMeasurement(BodyMeasurement entry) async {
    final confirmed = await _confirmDelete(
      '删除 ${entry.date.month}/${entry.date.day} 的围度记录？',
    );
    if (!confirmed) return;
    final entries = await deleteMeasurement(entry.date);
    if (mounted) setState(() => _measurements = entries);
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _dataCard(WorkoutTheme t) {
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup_outlined, color: t.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '数据管理',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PressScale(
                    onTap: _exportData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: t.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '导出备份',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressScale(
                    onTap: _importData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: t.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.upload_rounded, color: t.accent, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '导入恢复',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'JSON 格式 · 含资料、训练、体重与围度 · 导入前自动备份',
              style: TextStyle(fontSize: 10, color: t.text4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final json = await exportAllData();
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('数据导出'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(json, style: TextStyle(fontSize: 10)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: json));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('✅ 已复制到剪贴板')));
                },
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ 导出失败: $e')));
      }
    }
  }

  Future<void> _importData() async {
    final ctrl = TextEditingController();
    var mode = ImportMode.merge;
    final result = await showDialog<ImportMode>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('导入数据'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: '粘贴 v6.7 JSON 备份数据...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<ImportMode>(
                  value: ImportMode.merge,
                  groupValue: mode,
                  onChanged: (value) => setDialogState(() => mode = value!),
                  title: const Text('合并（推荐）'),
                  subtitle: const Text('同日身体数据以导入值更新，其余历史保留'),
                ),
                RadioListTile<ImportMode>(
                  value: ImportMode.overwrite,
                  groupValue: mode,
                  onChanged: (value) => setDialogState(() => mode = value!),
                  title: const Text('覆盖'),
                  subtitle: const Text('清除当前 BodyRecomp 数据后恢复备份'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, mode);
              },
              child: const Text('导入'),
            ),
          ],
        ),
      ),
    );
    if (result != null && ctrl.text.trim().isNotEmpty) {
      try {
        final imported = await importAllData(ctrl.text, mode: result);
        if (!mounted) return;
        await _loadAll();
        if (!mounted) return;
        widget.onProfileChanged();
        workoutDataRevision.value++;
        workoutHistoryRevision.value++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ 已${result == ImportMode.merge ? "合并" : "覆盖"}导入 ${imported.importedKeys} 项，原数据已自动备份',
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ 导入失败: $e')));
        }
      }
    }
  }
}
