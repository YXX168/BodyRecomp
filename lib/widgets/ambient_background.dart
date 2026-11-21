import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Atmospheric multi-orb aurora backdrop cached in a [RepaintBoundary] so
/// scrolling foreground lists maintain silky 60/120fps without repainting the mesh.
class LiquidBackdrop extends StatelessWidget {
  final Widget child;
  final int pagePhase;

  const LiquidBackdrop({
    super.key,
    required this.child,
    this.pagePhase = 0,
  });

  static const _orb1Aligns = [
    Alignment(-0.90, -0.88),
    Alignment(0.86, -0.82),
    Alignment(-0.75, -0.45),
    Alignment(0.78, -0.68),
  ];

  static const _orb2Aligns = [
    Alignment(0.92, -0.05),
    Alignment(-0.88, 0.24),
    Alignment(0.85, 0.42),
    Alignment(-0.82, -0.18),
  ];

  static const _orb3Aligns = [
    Alignment(-0.40, 0.90),
    Alignment(0.45, 0.86),
    Alignment(0.15, -0.92),
    Alignment(0.40, 0.90),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 300);
    final phase = pagePhase.abs() % 4;
    final dark = p.isDark;

    return ColoredBox(
      color: p.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedAlign(
                    alignment: _orb1Aligns[phase],
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: RepaintBoundary(
                      child: _AuroraOrb(
                        size: 420,
                        color: p.orb1.withValues(alpha: dark ? .26 : .25),
                        midColor: p.orb1.withValues(alpha: dark ? .09 : .10),
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    alignment: _orb2Aligns[phase],
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: RepaintBoundary(
                      child: _AuroraOrb(
                        size: 380,
                        color: p.orb2.withValues(alpha: dark ? .22 : .20),
                        midColor: p.orb2.withValues(alpha: dark ? .07 : .08),
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    alignment: _orb3Aligns[phase],
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: RepaintBoundary(
                      child: _AuroraOrb(
                        size: 360,
                        color: p.orb3.withValues(alpha: dark ? .16 : .20),
                        midColor: p.orb3.withValues(alpha: dark ? .05 : .06),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Backward-compatible wrapper preserving [AmbientCanvas] imports.
class AmbientCanvas extends StatelessWidget {
  final Widget child;
  final int pagePhase;

  const AmbientCanvas({
    super.key,
    required this.child,
    this.pagePhase = 0,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidBackdrop(pagePhase: pagePhase, child: child);
  }
}

class _AuroraOrb extends StatelessWidget {
  final double size;
  final Color color;
  final Color midColor;

  const _AuroraOrb({
    required this.size,
    required this.color,
    required this.midColor,
  });

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: size * 1.35,
      maxHeight: size * 1.35,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, midColor, Colors.transparent],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// High-FPS translucent Liquid Glass card.
/// Defaults to `useBlur: false` because the cached [LiquidBackdrop] underneath
/// is already soft atmospheric aurora light; reserving GPU [BackdropFilter] for
/// floating overlays keeps scrolling locked at 60/120fps on real devices.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool elevated;
  final double radius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool useBlur;
  final double blurSigma;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.highlighted = false,
    this.elevated = false,
    this.radius = 22,
    this.gradient,
    this.backgroundColor,
    this.useBlur = false,
    this.blurSigma = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final topColor = highlighted
        ? Color.alphaBlend(
            p.primary.withValues(alpha: p.isDark ? .13 : .08),
            p.glassFillTop,
          )
        : elevated
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: p.isDark ? .05 : .14),
                p.glassFillTop,
              )
            : p.glassFillTop;

    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [topColor, p.glassFillBottom],
    );

    final List<BoxShadow>? shadow = elevated || highlighted
        ? [
            BoxShadow(
              color: (highlighted ? p.primary : Colors.black).withValues(
                alpha: p.isDark
                    ? (highlighted ? .12 : .18)
                    : (highlighted ? .09 : .05),
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : (!p.isDark
            ? [
                BoxShadow(
                  color: p.textPrimary.withValues(alpha: .045),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null);

    final innerContent =
        padding != null ? Padding(padding: padding!, child: child) : child;

    final interactive = onTap == null
        ? innerContent
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: p.primary.withValues(alpha: .09),
              highlightColor: p.primary.withValues(alpha: .04),
              child: innerContent,
            ),
          );

    final decoratedGlass = CustomPaint(
      foregroundPainter: _LiquidRimPainter(
        radius: radius,
        brightRim: highlighted
            ? Color.alphaBlend(
                p.primaryBright.withValues(alpha: .36),
                p.glassRimBright,
              )
            : p.glassRimBright,
        accentRim:
            highlighted ? p.primary.withValues(alpha: .52) : p.glassRimAccent,
        strokeWidth: highlighted ? 1.2 : 0.95,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gradient == null && backgroundColor != null
              ? backgroundColor
              : null,
          gradient:
              backgroundColor != null ? null : (gradient ?? defaultGradient),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: interactive,
      ),
    );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: useBlur && blurSigma > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: decoratedGlass,
            )
          : decoratedGlass,
    );

    if (shadow == null) return clipped;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: clipped,
    );
  }
}

class _LiquidRimPainter extends CustomPainter {
  final double radius;
  final Color brightRim;
  final Color accentRim;
  final double strokeWidth;

  _LiquidRimPainter({
    required this.radius,
    required this.brightRim,
    required this.accentRim,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular((radius - strokeWidth / 2).clamp(0.0, radius)),
    );

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brightRim,
          brightRim.withValues(alpha: (brightRim.a * .18).clamp(0.0, 1.0)),
          accentRim.withValues(alpha: (accentRim.a * .28).clamp(0.0, 1.0)),
          accentRim,
        ],
        stops: const [0.0, 0.35, 0.72, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, rimPaint);
  }

  @override
  bool shouldRepaint(_LiquidRimPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.brightRim != brightRim ||
      oldDelegate.accentRim != accentRim ||
      oldDelegate.strokeWidth != strokeWidth;
}

class SectionTitleBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: p.textPrimary,
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
        if (trailing != null) trailing!,
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = color ?? p.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: p.isDark ? .16 : .11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tint.withValues(alpha: p.isDark ? .30 : .22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.5, color: tint),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassMenuItem<T> {
  final T value;
  final String label;
  final IconData icon;
  final Color? color;
  final bool isDanger;
  final bool hasTopDivider;

  const GlassMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
    this.isDanger = false,
    this.hasTopDivider = false,
  });
}

Future<T?> showGlassMenu<T>({
  required BuildContext context,
  BuildContext? anchorContext,
  RelativeRect? position,
  String? title,
  required List<GlassMenuItem<T>> items,
}) {
  final navigator = Navigator.of(context);
  final overlayRo = navigator.overlay?.context.findRenderObject();
  final overlayBox =
      overlayRo is RenderBox && overlayRo.attached && overlayRo.hasSize
          ? overlayRo
          : null;
  final overlaySize = overlayBox?.size ?? MediaQuery.sizeOf(context);

  RenderBox? anchorBox;
  if (anchorContext != null && anchorContext.mounted) {
    final ro = anchorContext.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) {
      anchorBox = ro;
    }
  }

  Rect anchorRect;
  if (anchorBox != null && overlayBox != null) {
    anchorRect = Rect.fromPoints(
      anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox),
      anchorBox.localToGlobal(
        anchorBox.size.bottomRight(Offset.zero),
        ancestor: overlayBox,
      ),
    );
  } else if (position != null) {
    anchorRect = Rect.fromLTRB(
      position.left,
      position.top,
      math.max(position.left, overlaySize.width - position.right),
      math.max(position.top, overlaySize.height - position.bottom),
    );
  } else {
    anchorRect = Rect.fromLTWH(overlaySize.width - 56, 72, 36, 36);
  }

  final themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  return navigator.push<T>(
    _GlassMenuRoute<T>(
      anchorRect: anchorRect,
      title: title,
      items: items,
      themes: themes,
      reduceMotion: reduceMotion,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

class _GlassMenuRoute<T> extends PopupRoute<T> {
  final Rect anchorRect;
  final String? title;
  final List<GlassMenuItem<T>> items;
  final CapturedThemes themes;
  final bool reduceMotion;

  _GlassMenuRoute({
    required this.anchorRect,
    required this.title,
    required this.items,
    required this.themes,
    required this.reduceMotion,
    required String barrierLabel,
  }) : _barrierLabel = barrierLabel;

  final String _barrierLabel;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => _barrierLabel;

  @override
  Color get barrierColor => Colors.black.withValues(alpha: 0.08);

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 150);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final safePadding = MediaQuery.paddingOf(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenSize = MediaQuery.sizeOf(context);
    final textDirection = Directionality.of(context);
    final disableMotion =
        reduceMotion || MediaQuery.disableAnimationsOf(context);

    final alignLeft = anchorRect.center.dx < screenSize.width * 0.35;
    final usableTop = safePadding.top + 12.0;
    final usableBottom =
        screenSize.height - safePadding.bottom - bottomInset - 12.0;
    final spaceBelow = usableBottom - (anchorRect.bottom + 6.0);
    final spaceAbove = (anchorRect.top - 6.0) - usableTop;
    final openAbove = spaceBelow < 180.0 && spaceAbove > spaceBelow;
    final scaleAlignment = Alignment(
      alignLeft ? -1.0 : 1.0,
      openAbove ? 1.0 : -1.0,
    );

    final menuCard = RepaintBoundary(
      child: _GlassMenuCard<T>(title: title, items: items),
    );
    const liquidCurve = Cubic(0.22, 1.0, 0.36, 1.0);
    final fadeAnim = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    final scaleAnim = animation.drive(
      Tween<double>(begin: 0.94, end: 1.0)
          .chain(CurveTween(curve: liquidCurve)),
    );

    return themes.wrap(
      SafeArea(
        bottom: false,
        top: false,
        child: CustomSingleChildLayout(
          delegate: _GlassMenuLayoutDelegate(
            anchorRect: anchorRect,
            safePadding: safePadding,
            bottomInset: bottomInset,
            textDirection: textDirection,
          ),
          child: disableMotion
              ? menuCard
              : FadeTransition(
                  opacity: fadeAnim,
                  child: ScaleTransition(
                    scale: scaleAnim,
                    alignment: scaleAlignment,
                    child: menuCard,
                  ),
                ),
        ),
      ),
    );
  }
}

class _GlassMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect anchorRect;
  final EdgeInsets safePadding;
  final double bottomInset;
  final TextDirection textDirection;

  const _GlassMenuLayoutDelegate({
    required this.anchorRect,
    required this.safePadding,
    required this.bottomInset,
    required this.textDirection,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = math.max(160.0, math.min(256.0, constraints.maxWidth - 24.0));
    final availableH = constraints.maxHeight -
        safePadding.top -
        safePadding.bottom -
        bottomInset -
        24.0;
    final maxH = math.max(96.0, availableH);
    return BoxConstraints(maxWidth: maxW, maxHeight: maxH);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minX = safePadding.left + 12.0;
    final maxX = math.max(
      minX,
      size.width - safePadding.right - 12.0 - childSize.width,
    );
    final preferredX = anchorRect.center.dx < size.width * 0.35
        ? anchorRect.left
        : anchorRect.right - childSize.width;
    final x = preferredX.clamp(minX, maxX).toDouble();

    final minY = safePadding.top + 12.0;
    final maxY = math.max(
      minY,
      size.height - safePadding.bottom - bottomInset - 12.0 - childSize.height,
    );
    final belowY = anchorRect.bottom + 6.0;
    final aboveY = anchorRect.top - 6.0 - childSize.height;
    final fitsBelow = belowY <= maxY;
    final fitsAbove = aboveY >= minY;
    final preferredY = fitsBelow || !fitsAbove ? belowY : aboveY;
    final y = preferredY.clamp(minY, maxY).toDouble();

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _GlassMenuLayoutDelegate oldDelegate) =>
      anchorRect != oldDelegate.anchorRect ||
      safePadding != oldDelegate.safePadding ||
      bottomInset != oldDelegate.bottomInset ||
      textDirection != oldDelegate.textDirection;
}

class _GlassMenuCard<T> extends StatelessWidget {
  final String? title;
  final List<GlassMenuItem<T>> items;

  const _GlassMenuCard({
    this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cardWidth = math.min(
      textScale > 1.3 ? 256.0 : 224.0,
      math.max(180.0, MediaQuery.sizeOf(context).width - 24.0),
    );
    final glassTop = p.isDark
        ? Color.alphaBlend(
            p.primary.withValues(alpha: 0.12),
            p.surfaceElevated.withValues(alpha: 0.88),
          )
        : Color.alphaBlend(
            p.primary.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.92),
          );
    final glassBottom = p.isDark
        ? Color.alphaBlend(
            p.glassFillBottom,
            p.canvas.withValues(alpha: 0.92),
          )
        : p.surfaceElevated.withValues(alpha: 0.88);

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: cardWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? 0.42 : 0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: p.primary.withValues(alpha: p.isDark ? 0.12 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 12,
                sigmaY: 12,
                tileMode: TileMode.clamp,
              ),
              child: CustomPaint(
                foregroundPainter: _LiquidRimPainter(
                  radius: 22,
                  brightRim: p.glassRimBright
                      .withValues(alpha: p.isDark ? 0.44 : 0.88),
                  accentRim: p.glassRimAccent,
                  strokeWidth: 1.0,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [glassTop, glassBottom],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null && title!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.primary.withValues(alpha: 0.45),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: p.borderSubtle,
                        ),
                      ],
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final item in items) ...[
                                if (item.hasTopDivider)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      thickness: 0.8,
                                      color: p.borderSubtle,
                                    ),
                                  ),
                                _GlassMenuRow<T>(item: item),
                              ],
                            ],
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
      ),
    );
  }
}

class _GlassMenuRow<T> extends StatelessWidget {
  final GlassMenuItem<T> item;

  const _GlassMenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final itemTint = item.isDanger ? p.danger : (item.color ?? p.primary);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        highlightColor: itemTint.withValues(alpha: p.isDark ? 0.14 : 0.10),
        splashColor: itemTint.withValues(alpha: p.isDark ? 0.18 : 0.12),
        onTap: () => Navigator.of(context).pop(item.value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: itemTint.withValues(alpha: p.isDark ? 0.16 : 0.12),
                  border: Border.all(
                    color: itemTint.withValues(alpha: p.isDark ? 0.28 : 0.22),
                    width: 0.8,
                  ),
                ),
                child: Icon(item.icon, size: 16, color: itemTint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: item.isDanger ? p.danger : p.textPrimary,
                  ),
                ),
              ),
              if (!item.isDanger) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: p.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted Liquid Glass modal dialog frame, keyboard-aware and safe at 2.0x textScale.
class GlassDialogFrame extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? accentColor;
  final List<Widget>? actions;

  const GlassDialogFrame({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.accentColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final media = MediaQuery.of(context);
    final tint = accentColor ?? p.primary;
    final availableHeight = media.size.height -
        media.viewInsets.bottom -
        media.padding.top -
        media.padding.bottom -
        40.0;
    final glassTop = p.isDark
        ? Color.alphaBlend(
            tint.withValues(alpha: 0.11),
            p.surfaceElevated.withValues(alpha: 0.88),
          )
        : Color.alphaBlend(
            tint.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.92),
          );
    final glassBottom = p.isDark
        ? Color.alphaBlend(
            p.glassFillBottom,
            p.canvas.withValues(alpha: 0.93),
          )
        : p.surfaceElevated.withValues(alpha: 0.90);

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: math.max(160.0, availableHeight),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: p.isDark ? 0.48 : 0.16),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: tint.withValues(alpha: p.isDark ? 0.12 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 12,
                      sigmaY: 12,
                      tileMode: TileMode.clamp,
                    ),
                    child: CustomPaint(
                      foregroundPainter: _LiquidRimPainter(
                        radius: 26,
                        brightRim: p.glassRimBright
                            .withValues(alpha: p.isDark ? 0.46 : 0.90),
                        accentRim:
                            tint.withValues(alpha: p.isDark ? 0.34 : 0.24),
                        strokeWidth: 1.05,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [glassTop, glassBottom],
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (icon != null) ...[
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: tint.withValues(
                                            alpha: p.isDark ? 0.18 : 0.12,
                                          ),
                                          border: Border.all(
                                            color: tint.withValues(
                                              alpha: p.isDark ? 0.32 : 0.24,
                                            ),
                                            width: 0.9,
                                          ),
                                        ),
                                        child:
                                            Icon(icon, size: 19, color: tint),
                                      ),
                                      const SizedBox(width: 11),
                                    ],
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                          letterSpacing: -0.2,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((message != null && message!.isNotEmpty) ||
                                    content != null) ...[
                                  const SizedBox(height: 12),
                                  Flexible(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (message != null &&
                                              message!.isNotEmpty)
                                            Text(
                                              message!,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                height: 1.5,
                                                color: p.textSecondary,
                                              ),
                                            ),
                                          if (message != null &&
                                              message!.isNotEmpty &&
                                              content != null)
                                            const SizedBox(height: 12),
                                          if (content != null) content!,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (actions != null && actions!.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.end,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: actions!,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
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

/// Shows a custom modal widget (typically [GlassDialogFrame]) with zero-bounce Liquid Glass transition.
Future<T?> showGlassDialogBuilder<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final p = context.palette;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  const liquidCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: p.isDark ? 0.50 : 0.24),
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 170),
    pageBuilder: (ctx, animation, secondaryAnimation) =>
        RepaintBoundary(child: builder(ctx)),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      if (reduceMotion || MediaQuery.disableAnimationsOf(ctx)) return child;
      final fade = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      final scale = animation.drive(
        Tween<double>(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: liquidCurve)),
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}

/// Shows a frosted Liquid Glass dialog safe at 320x568 @ 2.0x textScale.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  Color? accentColor,
  List<Widget>? actions,
  List<Widget> Function(BuildContext dialogContext)? actionsBuilder,
  bool barrierDismissible = true,
}) =>
    showGlassDialogBuilder<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => GlassDialogFrame(
        title: title,
        message: message,
        content: content,
        icon: icon,
        accentColor: accentColor,
        actions: actionsBuilder != null ? actionsBuilder(ctx) : actions,
      ),
    );

/// Shows a frosted Liquid Glass confirmation / info dialog.
/// Pass `cancelLabel: null` for single-action informational notices.
Future<bool?> showGlassConfirm({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  Color? accentColor,
  String? cancelLabel = '取消',
  String confirmLabel = '确定',
  bool isDanger = false,
  bool barrierDismissible = true,
}) =>
    showGlassDialog<bool>(
      context: context,
      title: title,
      message: message,
      content: content,
      icon: icon ?? (isDanger ? Icons.warning_amber_rounded : null),
      accentColor: accentColor ?? (isDanger ? context.palette.danger : null),
      barrierDismissible: barrierDismissible,
      actionsBuilder: (ctx) {
        final p = ctx.palette;
        return [
          if (cancelLabel != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(foregroundColor: p.textSecondary),
              child: Text(cancelLabel),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDanger
                ? FilledButton.styleFrom(
                    backgroundColor: p.danger,
                    foregroundColor: Colors.white,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ];
      },
    );

/// Bespoke frosted Liquid Glass emblem for the 青燃 top-left brand mark.
class QingranBrandMark extends StatelessWidget {
  final double size;

  const QingranBrandMark({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = size * 0.34;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: p.primary.withValues(alpha: p.isDark ? 0.24 : 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: _LiquidRimPainter(
            radius: radius,
            brightRim:
                p.glassRimBright.withValues(alpha: p.isDark ? 0.56 : 0.90),
            accentRim: p.primary.withValues(alpha: p.isDark ? 0.38 : 0.26),
            strokeWidth: 0.95,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.primary.withValues(alpha: p.isDark ? 0.24 : 0.16),
                  p.accent.withValues(alpha: p.isDark ? 0.11 : 0.08),
                ],
              ),
            ),
            child: CustomPaint(
              painter: _QingranMarkPainter(
                primary: p.primary,
                bright: p.primaryBright,
                accent: p.accent,
                coreColor: p.isDark
                    ? Colors.white.withValues(alpha: 0.94)
                    : Color.lerp(Colors.white, p.primaryBright, 0.22)!
                        .withValues(alpha: 0.96),
                isDark: p.isDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QingranMarkPainter extends CustomPainter {
  final Color primary;
  final Color bright;
  final Color accent;
  final Color coreColor;
  final bool isDark;

  const _QingranMarkPainter({
    required this.primary,
    required this.bright,
    required this.accent,
    required this.coreColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100.0, size.height / 100.0);

    // Primary sculpted ascending flame ribbon.
    final outerFlame = Path()
      ..moveTo(54, 14)
      ..cubicTo(61, 29, 77, 39, 77, 57)
      ..cubicTo(77, 74, 65, 86, 49.5, 86)
      ..cubicTo(34, 86, 23, 74.5, 23, 59)
      ..cubicTo(23, 46, 31.5, 36.5, 37.5, 30)
      ..cubicTo(38.5, 37.5, 42.5, 42, 46.5, 43.5)
      ..cubicTo(43.5, 33, 46.5, 22, 54, 14)
      ..close();

    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [primary, bright, accent.withValues(alpha: 0.92)],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(const Rect.fromLTWH(22, 14, 56, 72));
    canvas.drawPath(outerFlame, flamePaint);

    // Subtle glass specular highlight along left-upper curve.
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: isDark ? 0.36 : 0.55);
    final edgeHighlight = Path()
      ..moveTo(53.5, 19.5)
      ..cubicTo(48.5, 26, 47.5, 34, 49.5, 42);
    canvas.drawPath(edgeHighlight, highlightPaint);

    // Inner luminous ember spark droplet.
    final innerSpark = Path()
      ..moveTo(52, 48)
      ..cubicTo(57.5, 55, 63, 60.5, 62.5, 67.5)
      ..cubicTo(62, 74, 56.8, 78.5, 50.2, 78.5)
      ..cubicTo(43.5, 78.5, 39, 73.8, 39, 67.2)
      ..cubicTo(39, 60.8, 45, 55.2, 52, 48)
      ..close();

    canvas.drawPath(
      innerSpark,
      Paint()..color = coreColor,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _QingranMarkPainter oldDelegate) =>
      primary != oldDelegate.primary ||
      bright != oldDelegate.bright ||
      accent != oldDelegate.accent ||
      coreColor != oldDelegate.coreColor ||
      isDark != oldDelegate.isDark;
}
