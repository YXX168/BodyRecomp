import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const AppNavigationBar(
      {super.key, required this.index, required this.onChanged});
  static const labels = ['训练', '饮食', '趋势', '我的'];
  static const icons = [
    Icons.fitness_center_rounded,
    Icons.restaurant_rounded,
    Icons.insights_rounded,
    Icons.person_outline_rounded
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelHeight = MediaQuery.textScalerOf(context).scale(10) * 1.5;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
              top: BorderSide(color: colors.onSurface.withValues(alpha: .06)))),
      child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 7, 16, 5),
            child: Row(children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                    child: Semantics(
                  selected: i == index,
                  button: true,
                  label: labels[i],
                  child: InkWell(
                    key: ValueKey('nav-$i'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onChanged(i),
                    child: SizedBox(
                        height: 41 + labelHeight,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  width: 36,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: i == index
                                        ? colors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(icons[i],
                                      size: 19,
                                      color: i == index
                                          ? colors.onPrimary
                                          : colors.onSurface
                                              .withValues(alpha: .42))),
                              const SizedBox(height: 5),
                              Text(labels[i],
                                  style: TextStyle(
                                      fontSize: 10,
                                      height: 1.5,
                                      fontWeight: i == index
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: i == index
                                          ? colors.primary
                                          : colors.onSurface
                                              .withValues(alpha: .45))),
                            ])),
                  ),
                )),
            ]),
          )),
    );
  }
}
