import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared, keyboard-aware frame for short editing and selection flows.
class SheetFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget body;
  final Widget? footer;
  const SheetFrame(
      {super.key,
      required this.title,
      this.subtitle,
      required this.icon,
      required this.body,
      this.footer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top - 12;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight:
                      math.max(0, math.min(media.size.height * .9, available))),
              child: Material(
                color: colors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                clipBehavior: Clip.antiAlias,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 30,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 16),
                      decoration: BoxDecoration(
                          color: colors.onSurface.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(4))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
                      child: Row(children: [
                        Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: .09),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(icon, color: colors.primary, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700)),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(subtitle!,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: colors.onSurface
                                            .withValues(alpha: .50))),
                              ],
                            ])),
                        IconButton(
                            tooltip: '关闭',
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded,
                                size: 19,
                                color: colors.onSurface.withValues(alpha: .5))),
                      ])),
                  Divider(
                      height: 1,
                      color: colors.onSurface.withValues(alpha: .07)),
                  Flexible(
                      child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                          child: body)),
                  if (footer != null)
                    Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(
                                    color: colors.onSurface
                                        .withValues(alpha: .07)))),
                        child: footer),
                ]),
              ),
            ),
          )),
    );
  }
}

class SelectionOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;
  const SelectionOption(
      {super.key,
      required this.title,
      this.subtitle,
      required this.leading,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        selected: selected,
        button: true,
        child: Material(
          color:
              selected ? colors.primary.withValues(alpha: .06) : colors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(
                  color: selected
                      ? colors.primary.withValues(alpha: .55)
                      : colors.onSurface.withValues(alpha: .09),
                  width: 1)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? colors.primary
                                      : colors.onSurface)),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(subtitle!,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: colors.onSurface
                                        .withValues(alpha: .48))),
                          ],
                        ])),
                    const SizedBox(width: 8),
                    Container(
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                selected ? colors.primary : Colors.transparent,
                            border: Border.all(
                                color: selected
                                    ? colors.primary
                                    : colors.onSurface.withValues(alpha: .18))),
                        child: selected
                            ? Icon(Icons.check_rounded,
                                size: 14, color: colors.onPrimary)
                            : null),
                  ]))),
        ));
  }
}
