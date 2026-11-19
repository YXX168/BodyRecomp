import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TrendPoint {
  final String label;
  final double value;
  const TrendPoint(this.label, this.value);
}

/// Interactive smooth cubic Bezier trend chart with glowing area fill & point inspection.
class SmoothTrendChart extends StatefulWidget {
  final List<TrendPoint> points;
  final String unit;
  final Color? lineColor;
  final Color? glowColor;
  final double height;

  const SmoothTrendChart({
    super.key,
    required this.points,
    this.unit = '',
    this.lineColor,
    this.glowColor,
    this.height = 176,
  });

  @override
  State<SmoothTrendChart> createState() => _SmoothTrendChartState();
}

class _SmoothTrendChartState extends State<SmoothTrendChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(SmoothTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex != null && _selectedIndex! >= widget.points.length) {
      _selectedIndex = null;
    }
  }

  void _selectAt(double localX, double width) {
    if (widget.points.isEmpty) return;
    const leftPad = 14.0;
    const rightPad = 14.0;
    final usable = math.max(1.0, width - leftPad - rightPad);
    if (widget.points.length == 1) {
      setState(() => _selectedIndex = 0);
      return;
    }
    final ratio = ((localX - leftPad) / usable).clamp(0.0, 1.0);
    final idx = (ratio * (widget.points.length - 1))
        .round()
        .clamp(0, widget.points.length - 1);
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final line = widget.lineColor ?? p.primary;
    final bright = widget.glowColor ?? p.primaryBright;

    if (widget.points.length < 2) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            '至少记录 2 次数据后显示平滑趋势图',
            style: TextStyle(fontSize: 12, color: p.textTertiary),
          ),
        ),
      );
    }

    final values = widget.points.map((e) => e.value).toList();
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final activeIdx = _selectedIndex ?? (widget.points.length - 1);
    final active = widget.points[activeIdx];

    String fmt(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: line.withValues(alpha: p.isDark ? .14 : .09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${active.label} · ${fmt(active.value)}${widget.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: line,
                  ),
                ),
              ),
              Text(
                '低 ${fmt(minVal)} · 高 ${fmt(maxVal)}${widget.unit}',
                style: TextStyle(
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _selectAt(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) =>
                  _selectAt(d.localPosition.dx, width),
              child: SizedBox(
                width: width,
                height: widget.height,
                child: CustomPaint(
                  painter: _SmoothTrendPainter(
                    points: widget.points,
                    selectedIndex: activeIdx,
                    lineColor: line,
                    brightColor: bright,
                    gridColor: p.borderSubtle,
                    labelColor: p.textTertiary,
                    surfaceColor: p.surface,
                    isDark: p.isDark,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SmoothTrendPainter extends CustomPainter {
  final List<TrendPoint> points;
  final int selectedIndex;
  final Color lineColor;
  final Color brightColor;
  final Color gridColor;
  final Color labelColor;
  final Color surfaceColor;
  final bool isDark;

  _SmoothTrendPainter({
    required this.points,
    required this.selectedIndex,
    required this.lineColor,
    required this.brightColor,
    required this.gridColor,
    required this.labelColor,
    required this.surfaceColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const leftPad = 14.0;
    const rightPad = 14.0;
    const topPad = 16.0;
    const bottomPad = 24.0;
    final chartW = math.max(1.0, size.width - leftPad - rightPad);
    final chartH = math.max(1.0, size.height - topPad - bottomPad);

    final vals = points.map((e) => e.value).toList();
    final minVal = vals.reduce(math.min);
    final maxVal = vals.reduce(math.max);
    final span = (maxVal - minVal).abs();
    final pad = span < 0.01 ? 1.0 : span * 0.18;
    final yMin = minVal - pad;
    final yMax = maxVal + pad;
    final ySpan = math.max(0.01, yMax - yMin);

    // Subtle horizontal guide lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = topPad + (chartH / 2) * i;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
    }

    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final x = leftPad + (chartW * i) / (points.length - 1);
      final normalized = (points[i].value - yMin) / ySpan;
      final y = topPad + chartH * (1 - normalized);
      coords.add(Offset(x, y));
    }

    // Smooth Catmull-Rom / cubic Bezier path
    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (var i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Area fill under spline
    final fillPath = Path.from(linePath)
      ..lineTo(coords.last.dx, topPad + chartH)
      ..lineTo(coords.first.dx, topPad + chartH)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: isDark ? .28 : .20),
          lineColor.withValues(alpha: .0),
        ],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Glow line
    if (isDark) {
      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Main gradient curve
    final strokePaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor, brightColor],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, strokePaint);

    // Vertical indicator for selected point
    final sel = coords[selectedIndex.clamp(0, coords.length - 1)];
    canvas.drawLine(
      Offset(sel.dx, topPad),
      Offset(sel.dx, topPad + chartH),
      Paint()
        ..color = lineColor.withValues(alpha: .28)
        ..strokeWidth = 1.2,
    );

    // Point markers
    for (var i = 0; i < coords.length; i++) {
      final c = coords[i];
      final isSelected = i == selectedIndex;
      if (points.length <= 16 || isSelected) {
        canvas.drawCircle(
          c,
          isSelected ? 6.0 : 3.2,
          Paint()
            ..color =
                isSelected ? lineColor.withValues(alpha: .26) : surfaceColor,
        );
        canvas.drawCircle(
          c,
          isSelected ? 4.2 : 2.3,
          Paint()..color = isSelected ? brightColor : lineColor,
        );
      }
    }

    // X-axis edge date labels
    void drawXLabel(String text, double x, TextAlign align) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = switch (align) {
        TextAlign.left => x,
        TextAlign.right => x - tp.width,
        _ => x - tp.width / 2,
      };
      tp.paint(
        canvas,
        Offset(dx.clamp(0, size.width - tp.width), topPad + chartH + 6),
      );
    }

    drawXLabel(points.first.label, leftPad, TextAlign.left);
    if (points.length >= 3) {
      final mid = points.length ~/ 2;
      drawXLabel(points[mid].label, coords[mid].dx, TextAlign.center);
    }
    drawXLabel(points.last.label, size.width - rightPad, TextAlign.right);
  }

  @override
  bool shouldRepaint(_SmoothTrendPainter old) =>
      old.points != points ||
      old.selectedIndex != selectedIndex ||
      old.lineColor != lineColor ||
      old.brightColor != brightColor ||
      old.isDark != isDark;
}
