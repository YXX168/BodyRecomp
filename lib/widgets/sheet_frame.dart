import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared, keyboard-aware Liquid Glass sheet frame for editing and selection flows.
class SheetFrame extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget body;
  final Widget? footer;
  const SheetFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.body,
    this.footer,
  });

  @override
  State<SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<SheetFrame> {
  final _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top - 12;
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);
    final glassTop = p.isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: .06),
            p.surfaceElevated.withValues(alpha: .82),
          )
        : Colors.white.withValues(alpha: .82);
    final glassBottom = p.isDark
        ? p.canvas.withValues(alpha: .90)
        : p.surfaceElevated.withValues(alpha: .76);

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
                  math.max(0, math.min(media.size.height * .9, available)),
            ),
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12,
                    sigmaY: 12,
                    tileMode: TileMode.clamp,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [glassTop, glassBottom],
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border.all(
                        color: p.glassRimBright.withValues(alpha: .56),
                        width: 1.1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final scrollAll = constraints.maxHeight <
                              200 * media.textScaler.scale(1).clamp(1.0, 2.0);
                          final children = <Widget>[
                            Container(
                              width: 36,
                              height: 4,
                              margin:
                                  const EdgeInsets.only(top: 10, bottom: 14),
                              decoration: BoxDecoration(
                                color: p.textTertiary.withValues(alpha: .42),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          p.primary.withValues(alpha: .26),
                                          p.accent.withValues(alpha: .14),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                        color: p.primary.withValues(alpha: .42),
                                      ),
                                    ),
                                    child: Icon(widget.icon,
                                        color: p.primary, size: 19),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.title,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: p.textPrimary,
                                          ),
                                        ),
                                        if (widget.subtitle != null &&
                                            widget.subtitle!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.subtitle!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: p.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: '关闭',
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              height: 1,
                              color: p.glassRimBright.withValues(alpha: .22),
                            ),
                            if (scrollAll)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                child: body,
                              )
                            else
                              Flexible(
                                child: SingleChildScrollView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                  child: body,
                                ),
                              ),
                            if (widget.footer != null)
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: p.glassRimBright
                                          .withValues(alpha: .22),
                                    ),
                                  ),
                                ),
                                child: widget.footer,
                              ),
                          ];
                          final content = Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          );
                          return scrollAll
                              ? SingleChildScrollView(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  child: content,
                                )
                              : content;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectionOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget leading;
  final bool selected;
  final VoidCallback onTap;
  const SelectionOption({
    super.key,
    required this.title,
    this.subtitle,
    required this.leading,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [
                      p.primary.withValues(alpha: p.isDark ? .24 : .16),
                      p.accent.withValues(alpha: p.isDark ? .10 : .06),
                    ]
                  : [
                      p.glassFillTop,
                      p.glassFillBottom,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? p.borderHighlight : p.borderSubtle,
              width: selected ? 1.35 : 1.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected ? p.primary : p.textPrimary,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: selected ? p.primaryGradient : null,
                      border:
                          selected ? null : Border.all(color: p.textTertiary),
                    ),
                    child: selected
                        ? Icon(Icons.check_rounded,
                            size: 14, color: p.onPrimary)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
