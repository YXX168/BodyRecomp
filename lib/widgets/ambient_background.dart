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
        reduceMotion ? Duration.zero : const Duration(milliseconds: 520);
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
                    child: _AuroraOrb(
                      size: 420,
                      color: p.orb1.withValues(alpha: dark ? .26 : .25),
                      midColor: p.orb1.withValues(alpha: dark ? .09 : .10),
                    ),
                  ),
                  AnimatedAlign(
                    alignment: _orb2Aligns[phase],
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: _AuroraOrb(
                      size: 380,
                      color: p.orb2.withValues(alpha: dark ? .22 : .20),
                      midColor: p.orb2.withValues(alpha: dark ? .07 : .08),
                    ),
                  ),
                  AnimatedAlign(
                    alignment: _orb3Aligns[phase],
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: _AuroraOrb(
                      size: 360,
                      color: p.orb3.withValues(alpha: dark ? .16 : .20),
                      midColor: p.orb3.withValues(alpha: dark ? .05 : .06),
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
                  color: const Color(0xFF0F293A).withValues(alpha: .04),
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

class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.975,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !reduceMotion ? widget.scale : 1.0,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
