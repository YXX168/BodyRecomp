import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/recomp_models.dart';
import '../theme/app_theme.dart';
import 'daily_date_bar.dart';

enum DayStripStatus {
  rest,
  planned,
  partial,
  completed,
}

/// Calm, unified translucent Mon–Sun strip paired with compact [DailyDateBar]
/// and a smooth critically-damped sliding selection indicator.
class WeekStripBar extends StatefulWidget {
  final DateTime date;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;
  final DayStripStatus Function(DateTime day) statusForDay;
  final bool enabled;
  final bool allowFutureSelection;

  const WeekStripBar({
    super.key,
    required this.date,
    required this.today,
    required this.onChanged,
    required this.statusForDay,
    this.enabled = true,
    this.allowFutureSelection = false,
  });

  @override
  State<WeekStripBar> createState() => _WeekStripBarState();
}

class _WeekStripBarState extends State<WeekStripBar>
    with SingleTickerProviderStateMixin {
  static const Curve _slideCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late DateTime _monday = _mondayOf(widget.date);
  late double _fromPos = _slotIndex(widget.date).toDouble();
  late double _toPos = _slotIndex(widget.date).toDouble();

  static DateTime _mondayOf(DateTime date) {
    final d = dateOnly(date);
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  static int _slotIndex(DateTime date) => (date.weekday - 1).clamp(0, 6);

  double get _currentPos {
    final t = _slideCurve.transform(_controller.value.clamp(0.0, 1.0));
    return lerpDouble(_fromPos, _toPos, t) ?? _toPos;
  }

  @override
  void initState() {
    super.initState();
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(WeekStripBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newMonday = _mondayOf(widget.date);
    final newIdx = _slotIndex(widget.date).toDouble();
    final oldIdx = _slotIndex(oldWidget.date).toDouble();
    final sameWeek = newMonday == _monday;
    _monday = newMonday;

    if (!sameWeek || MediaQuery.disableAnimationsOf(context)) {
      _fromPos = newIdx;
      _toPos = newIdx;
      _controller.value = 1.0;
      return;
    }

    if (newIdx != oldIdx || newIdx != _toPos) {
      _fromPos = _currentPos;
      _toPos = newIdx;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = dateOnly(widget.date);
    final todayDay = dateOnly(widget.today);
    final monday = _mondayOf(selected);
    const labels = ['一', '二', '三', '四', '五', '六', '日'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DailyDateBar(
          date: widget.date,
          today: widget.today,
          enabled: widget.enabled,
          allowFutureNext: widget.allowFutureSelection,
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.glassFillTop, p.glassFillBottom],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.borderSubtle, width: 0.9),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final slotWidth = totalWidth / 7;
              return Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final rawT = _controller.value.clamp(0.0, 1.0);
                        final dist = (_toPos - _fromPos).abs().clamp(0.0, 6.0);
                        final pulse =
                            dist > 0.05 ? math.sin(math.pi * rawT) : 0.0;
                        final stretchX =
                            1.0 + 0.10 * pulse * math.min(2.0, math.sqrt(dist));
                        final pos = _currentPos.clamp(0.0, 6.0);
                        final pillWidth =
                            (slotWidth * stretchX).clamp(slotWidth, totalWidth);
                        final centerX = (pos + 0.5) * slotWidth;
                        final left = (centerX - pillWidth / 2)
                            .clamp(0.0, math.max(0.0, totalWidth - pillWidth))
                            .toDouble();

                        return Stack(
                          children: [
                            Positioned(
                              left: left,
                              top: 0,
                              bottom: 0,
                              width: pillWidth,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: p.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: p.isDark ? 0.22 : 0.34,
                                    ),
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: p.primary.withValues(
                                        alpha: p.isDark ? 0.28 : 0.20,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final day = DateTime(
                                  monday.year, monday.month, monday.day + i);
                              final isSelected = day == selected;
                              final isToday = day == todayDay;
                              final isFuture = day.isAfter(todayDay);
                              final canTap = widget.enabled &&
                                  (widget.allowFutureSelection || !isFuture);
                              final status = widget.statusForDay(day);

                              final dotColor = switch (status) {
                                DayStripStatus.completed =>
                                  isSelected ? p.onPrimary : p.primary,
                                DayStripStatus.partial =>
                                  isSelected ? p.onPrimary : p.warning,
                                DayStripStatus.planned => isSelected
                                    ? p.onPrimary.withValues(alpha: .72)
                                    : p.textTertiary.withValues(alpha: .50),
                                DayStripStatus.rest => Colors.transparent,
                              };

                              return Semantics(
                                selected: isSelected,
                                button: canTap,
                                label: '周${labels[i]} ${day.day}日',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: ValueKey('week-strip-day-$i'),
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: canTap
                                        ? () => widget.onChanged(day)
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: !isSelected && isToday
                                            ? p.primary.withValues(
                                                alpha: p.isDark ? .12 : .08,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: !isSelected && isToday
                                              ? p.primary.withValues(alpha: .40)
                                              : Colors.transparent,
                                          width: 0.9,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            labels[i],
                                            style: TextStyle(
                                              fontSize: 10,
                                              height: 1.15,
                                              fontWeight: isSelected || isToday
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? p.onPrimary
                                                      .withValues(alpha: .88)
                                                  : isToday
                                                      ? p.primary
                                                      : isFuture &&
                                                              !widget
                                                                  .allowFutureSelection
                                                          ? p.textTertiary
                                                              .withValues(
                                                                  alpha: .45)
                                                          : p.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 1.5),
                                          Text(
                                            '${day.day}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.15,
                                              fontWeight: isSelected || isToday
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures()
                                              ],
                                              color: isSelected
                                                  ? p.onPrimary
                                                  : isToday
                                                      ? p.primary
                                                      : isFuture &&
                                                              !widget
                                                                  .allowFutureSelection
                                                          ? p.textTertiary
                                                              .withValues(
                                                                  alpha: .45)
                                                          : p.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2.5),
                                          Container(
                                            width: status ==
                                                    DayStripStatus.completed
                                                ? 9
                                                : 3.5,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: dotColor,
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
