import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/recomp_models.dart';
import '../theme/app_theme.dart';
import 'daily_date_bar.dart';
import 'day_page_view.dart';

enum DayStripStatus {
  rest,
  planned,
  partial,
  completed,
}

/// Calm, unified translucent Mon–Sun strip paired with compact [DailyDateBar].
///
/// When [pageProgress] is provided, the pill and day-cell illumination track
/// horizontal day paging 1:1 in real time; otherwise it animates smoothly on
/// its own critically-damped curve.
class WeekStripBar extends StatefulWidget {
  final DateTime date;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;
  final DayStripStatus Function(DateTime day) statusForDay;
  final ValueListenable<double>? pageProgress;
  final bool enabled;
  final bool allowFutureSelection;

  const WeekStripBar({
    super.key,
    required this.date,
    required this.today,
    required this.onChanged,
    required this.statusForDay,
    this.pageProgress,
    this.enabled = true,
    this.allowFutureSelection = false,
  });

  @override
  State<WeekStripBar> createState() => _WeekStripBarState();
}

class _WeekStripBarState extends State<WeekStripBar>
    with SingleTickerProviderStateMixin {
  static const Curve _slideCurve = Cubic(0.32, 0.72, 0.0, 1.0);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
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

    if (widget.pageProgress != null) {
      _fromPos = newIdx;
      _toPos = newIdx;
      _controller.value = 1.0;
      return;
    }

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
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    final listenable = widget.pageProgress ?? _controller;

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
              return ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: AnimatedBuilder(
                  animation: listenable,
                  builder: (context, _) {
                    final double relPos;
                    final DateTime monday;
                    final double stretchX;

                    final progress = widget.pageProgress;
                    if (progress != null) {
                      final livePage = progress.value;
                      final nearestDate =
                          DayPageView.pageIndexToDate(livePage.round());
                      monday = _mondayOf(nearestDate);
                      final mondayIndex = DayPageView.dateToPageIndex(monday);
                      relPos = (livePage - mondayIndex)
                          .clamp(-0.65, 6.65)
                          .toDouble();
                      final fracMotion = ((relPos - relPos.round()).abs() * 2.0)
                          .clamp(0.0, 1.0);
                      stretchX =
                          1.0 + 0.08 * math.sin(math.pi * 0.5 * fracMotion);
                    } else {
                      monday = _mondayOf(selected);
                      relPos = _currentPos.clamp(0.0, 6.0);
                      final rawT = _controller.value.clamp(0.0, 1.0);
                      final dist = (_toPos - _fromPos).abs().clamp(0.0, 6.0);
                      final pulse =
                          dist > 0.05 ? math.sin(math.pi * rawT) : 0.0;
                      stretchX =
                          1.0 + 0.08 * pulse * math.min(2.0, math.sqrt(dist));
                    }

                    final pillWidth =
                        (slotWidth * stretchX).clamp(slotWidth, totalWidth);
                    final centerX = (relPos + 0.5) * slotWidth;
                    final rawLeft = centerX - pillWidth / 2;
                    final left = progress != null
                        ? rawLeft
                        : rawLeft
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
                        Row(
                          children: [
                            for (var i = 0; i < 7; i++)
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final day = DateTime(monday.year,
                                        monday.month, monday.day + i);
                                    final isSelected = day == selected;
                                    final isToday = day == todayDay;
                                    final isFuture = day.isAfter(todayDay);
                                    final canTap = widget.enabled &&
                                        (widget.allowFutureSelection ||
                                            !isFuture);
                                    final status = widget.statusForDay(day);
                                    final focus = (1.0 - (i - relPos).abs())
                                        .clamp(0.0, 1.0);

                                    final baseLabelColor = isToday
                                        ? p.primary
                                        : isFuture &&
                                                !widget.allowFutureSelection
                                            ? p.textTertiary
                                                .withValues(alpha: .45)
                                            : p.textSecondary;
                                    final selectedLabelColor =
                                        p.onPrimary.withValues(alpha: .88);
                                    final labelColor = Color.lerp(
                                      baseLabelColor,
                                      selectedLabelColor,
                                      focus,
                                    )!;

                                    final baseDayColor = isToday
                                        ? p.primary
                                        : isFuture &&
                                                !widget.allowFutureSelection
                                            ? p.textTertiary
                                                .withValues(alpha: .45)
                                            : p.textPrimary;
                                    final dayColor = Color.lerp(
                                      baseDayColor,
                                      p.onPrimary,
                                      focus,
                                    )!;

                                    final baseDotColor = switch (status) {
                                      DayStripStatus.completed => p.primary,
                                      DayStripStatus.partial => p.warning,
                                      DayStripStatus.planned =>
                                        p.textTertiary.withValues(alpha: .50),
                                      DayStripStatus.rest => Colors.transparent,
                                    };
                                    final activeDotColor = switch (status) {
                                      DayStripStatus.completed => p.onPrimary,
                                      DayStripStatus.partial => p.onPrimary,
                                      DayStripStatus.planned =>
                                        p.onPrimary.withValues(alpha: .72),
                                      DayStripStatus.rest => Colors.transparent,
                                    };
                                    final dotColor = Color.lerp(
                                      baseDotColor,
                                      activeDotColor,
                                      focus,
                                    )!;

                                    final todayFillAlpha = isToday
                                        ? (p.isDark ? 0.12 : 0.08) *
                                            (1.0 - focus)
                                        : 0.0;
                                    final todayBorderAlpha =
                                        isToday ? 0.40 * (1.0 - focus) : 0.0;

                                    return Semantics(
                                      selected: isSelected,
                                      button: canTap,
                                      label: '周${labels[i]} ${day.day}日',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          key: ValueKey('week-strip-day-$i'),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          onTap: canTap
                                              ? () => widget.onChanged(day)
                                              : null,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            decoration: BoxDecoration(
                                              color: todayFillAlpha > 0.002
                                                  ? p.primary.withValues(
                                                      alpha: todayFillAlpha)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: todayBorderAlpha > 0.002
                                                    ? p.primary.withValues(
                                                        alpha: todayBorderAlpha)
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
                                                    fontWeight:
                                                        focus > 0.5 || isToday
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                    color: labelColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 1.5),
                                                Text(
                                                  '${day.day}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    height: 1.15,
                                                    fontWeight:
                                                        focus > 0.5 || isToday
                                                            ? FontWeight.w800
                                                            : FontWeight.w600,
                                                    fontFeatures: const [
                                                      FontFeature
                                                          .tabularFigures()
                                                    ],
                                                    color: dayColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 2.5),
                                                Container(
                                                  width: status ==
                                                          DayStripStatus
                                                              .completed
                                                      ? 9
                                                      : 3.5,
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    color: dotColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            99),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
