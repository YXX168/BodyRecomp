import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/rest_countdown.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/rest_timer_pill.dart';
import '../widgets/sheet_frame.dart';
import 'nutrition_page.dart';
import 'plan_hub_page.dart';
import 'profile_page.dart';
import 'trends_page.dart';
import 'workout_page.dart';

class MainShell extends StatefulWidget {
  final String appVersion;
  const MainShell({super.key, this.appVersion = '7.0.2'});

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
    const PlanHubPage(),
    const NutritionPage(),
    const TrendsPage(),
    ProfilePage(appVersion: widget.appVersion),
  ];

  @override
  void initState() {
    super.initState();
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
        title: '外观主题工坊',
        subtitle: '随时切换高定明暗主题与配色风格',
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
                      subtitle: item == controller.current
                          ? '当前主题 · ${target.tagline}'
                          : target.tagline,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: target.canvas,
                          border: Border.all(
                            color: target.primary.withValues(alpha: .45),
                          ),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: target.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
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
      await controller.setTheme(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.canvas,
      extendBody: true,
      body: AmbientCanvas(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 8, 6),
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
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: p.primaryGradient,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  size: 18,
                                  color: p.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    p.primaryGradient.createShader(bounds),
                                child: const Text(
                                  '青燃',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
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
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: '切换主题',
                      onPressed: _showThemeSheet,
                      constraints:
                          const BoxConstraints.tightFor(width: 40, height: 40),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: p.textSecondary,
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
