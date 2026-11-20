import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Glowing gradient ring indicator for workout completion, nutrition, and timers.
class KineticProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Color? startColor;
  final Color? endColor;

  const KineticProgressRing({
    super.key,
    required this.progress,
    this.size = 78,
    this.strokeWidth = 7.5,
    this.center,
    this.startColor,
    this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final clamped = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final c1 = startColor ?? p.primary;
    final c2 = endColor ?? p.primaryBright;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: clamped),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final percent = (value * 100).round();
        return RepaintBoundary(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _KineticRingPainter(
                value: value,
                strokeWidth: strokeWidth,
                trackColor: (p.isDark ? Colors.white : Colors.black)
                    .withValues(alpha: p.isDark ? .14 : .08),
                startColor: c1,
                endColor: c2,
                isDark: p.isDark,
              ),
              child: Center(
                child: center ??
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: size * 0.23,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            letterSpacing: -0.6,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: value >= 1.0 ? c1 : p.textPrimary,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KineticRingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color trackColor;
  final Color startColor;
  final Color endColor;
  final bool isDark;

  _KineticRingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.startColor,
    required this.endColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Recessed background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (value <= 0.001) return;

    final sweep = (math.pi * 2) * value.clamp(0.0, 1.0);
    const startAngle = -math.pi / 2;

    // Soft outer bloom
    if (isDark) {
      final glowPaint = Paint()
        ..color = startColor.withValues(alpha: .32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.45
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawArc(rect, startAngle, sweep, false, glowPaint);
    }

    // Main gradient arc
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [startColor, endColor, startColor],
      stops: const [0.0, 0.55, 1.0],
      transform: const GradientRotation(startAngle - 0.15),
    ).createShader(rect);

    final arcPaint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);

    // Bright end cap dot
    final endAngle = startAngle + sweep;
    final tip = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    canvas.drawCircle(
      tip,
      strokeWidth * 0.24,
      Paint()..color = Colors.white.withValues(alpha: isDark ? .9 : .65),
    );
  }

  @override
  bool shouldRepaint(_KineticRingPainter old) =>
      old.value != value ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.startColor != startColor ||
      old.endColor != endColor ||
      old.isDark != isDark;
}
