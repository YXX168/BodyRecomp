import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppNavigationBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const AppNavigationBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  static const labels = ['训练', '计划', '饮食', '趋势', '我的'];
  static const activeIcons = [
    Icons.bolt_rounded,
    Icons.dashboard_customize_rounded,
    Icons.restaurant_rounded,
    Icons.insights_rounded,
    Icons.person_rounded,
  ];
  static const inactiveIcons = [
    Icons.bolt_outlined,
    Icons.dashboard_customize_outlined,
    Icons.restaurant_outlined,
    Icons.insights_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final labelHeight = MediaQuery.textScalerOf(context).scale(11) * 1.45;
    final itemHeight = 36 + labelHeight;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: p.dockBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: p.borderSubtle, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: p.isDark ? .38 : .08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: i == index,
                          button: true,
                          label: labels[i],
                          child: InkWell(
                            key: ValueKey('nav-$i'),
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onChanged(i),
                            child: SizedBox(
                              height: itemHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    width: i == index ? 42 : 34,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      gradient:
                                          i == index ? p.primaryGradient : null,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      i == index
                                          ? activeIcons[i]
                                          : inactiveIcons[i],
                                      size: 19,
                                      color: i == index
                                          ? p.onPrimary
                                          : p.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      fontWeight: i == index
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: i == index
                                          ? p.primary
                                          : p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
