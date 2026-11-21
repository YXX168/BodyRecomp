import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/rest_countdown.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/rest_timer_pill.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/undo_notice.dart';
import 'exercise_library_view.dart';
import 'profile_page.dart';
import 'template_manager_page.dart';
import 'workout_page.dart';

class MainShell extends StatefulWidget {
  final String appVersion;
  const MainShell({super.key, this.appVersion = '7.1.5'});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _tab = 0;
  late final RestCountdown _rest = RestCountdown(
    now: DateTime.now,
    onFinished: () => HapticFeedback.heavyImpact(),
  );

  late final List<Widget> _pages = [
    WorkoutPage(showRestTimer: false, restController: _rest),
    const WeeklyTemplatesPage(),
    const ExerciseLibraryView(),
    ProfilePage(appVersion: widget.appVersion),
  ];

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _rest.setActive(state == null || state == AppLifecycleState.resumed);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _rest.setActive(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rest.dispose();
    super.dispose();
  }

  Future<void> _showThemeSheet() async {
    final controller = ThemeScope.maybeOf(context);
    if (controller == null) return;
    final mode = await showModalBottomSheet<AppTheme>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
        title: '流光主题',
        icon: Icons.palette_outlined,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in AppTheme.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Builder(
                  builder: (_) {
                    final target = AppPalette.forTheme(item);
                    return SelectionOption(
                      key: ValueKey('theme-option-${item.name}'),
                      title: target.name,
                      subtitle: target.tagline,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: target.canvas,
                          border: Border.all(
                            color: target.primary.withValues(alpha: .50),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [target.orb1, target.orb2],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      selected: item == controller.current,
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
    if (mode != null && mounted) {
      try {
        await controller.setTheme(mode);
      } catch (_) {
        if (mounted) {
          showGlassNotice(context, '主题保存失败，请重试', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.canvas,
      extendBody: true,
      body: LiquidBackdrop(
        pagePhase: _tab,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 14, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const QingranBrandMark(size: 30),
                              const SizedBox(width: 8),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    p.primaryGradient.createShader(bounds),
                                child: const Text(
                                  '青燃',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    RestTimerPill(controller: _rest),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: '切换主题',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showThemeSheet,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [p.glassFillTop, p.glassFillBottom],
                              ),
                              border: Border.all(color: p.borderSubtle),
                            ),
                            child: Icon(
                              Icons.palette_outlined,
                              size: 18,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  sizing: StackFit.expand,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      TickerMode(
                        enabled: _tab == i,
                        child: RepaintBoundary(child: _pages[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppNavigationBar(
        index: _tab,
        onChanged: (index) {
          if (index == _tab) return;
          HapticFeedback.selectionClick();
          setState(() => _tab = index);
        },
      ),
    );
  }
}
