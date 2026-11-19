import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Atmospheric canvas wrapping pages with a soft radial top glow.
class AmbientCanvas extends StatelessWidget {
  final Widget child;
  const AmbientCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.75, -0.95),
                  radius: 1.25,
                  colors: [
                    p.ambientGlow.withValues(alpha: p.isDark ? .13 : .08),
                    p.accent.withValues(alpha: p.isDark ? .05 : .03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Editorial squircle card with optional highlight border, gradient, and tap ripple.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool elevated;
  final double radius;
  final Gradient? gradient;
  final Color? backgroundColor;

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
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = backgroundColor ?? (elevated ? p.surfaceElevated : p.surface);
    final borderColor = highlighted ? p.borderHighlight : p.borderSubtle;
    final shadow = p.isDark
        ? (highlighted
            ? [
                BoxShadow(
                  color: p.primary.withValues(alpha: .10),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : const <BoxShadow>[])
        : [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: .04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ];

    final body =
        padding != null ? Padding(padding: padding!, child: child) : child;

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor,
          width: highlighted ? 1.25 : 1.0,
        ),
        boxShadow: shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: p.primary.withValues(alpha: .08),
                highlightColor: p.primary.withValues(alpha: .04),
                child: body,
              ),
            ),
    );
  }
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: p.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: p.isDark ? .16 : .11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tint.withValues(alpha: p.isDark ? .32 : .20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
