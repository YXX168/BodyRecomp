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

/// Interactive Mon-Sun strip paired with the compact [DailyDateBar].
class WeekStripBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = dateOnly(date);
    final todayDay = dateOnly(today);
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DailyDateBar(
          date: date,
          today: today,
          enabled: enabled,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final day = monday.add(Duration(days: i));
                    final isSelected = day == selected;
                    final isToday = day == todayDay;
                    final isFuture = day.isAfter(todayDay);
                    final canTap =
                        enabled && (allowFutureSelection || !isFuture);
                    final status = statusForDay(day);

                    final dotColor = switch (status) {
                      DayStripStatus.completed => p.primary,
                      DayStripStatus.partial => p.warning,
                      DayStripStatus.planned =>
                        p.textTertiary.withValues(alpha: .55),
                      DayStripStatus.rest => Colors.transparent,
                    };

                    return Padding(
                      padding: EdgeInsets.only(right: i == 6 ? 0 : 4),
                      child: Semantics(
                        selected: isSelected,
                        button: canTap,
                        label: '周${labels[i]} ${day.day}日',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('week-strip-day-$i'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: canTap ? () => onChanged(day) : null,
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? p.primary
                                        .withValues(alpha: p.isDark ? .18 : .13)
                                    : isToday
                                        ? p.surfaceElevated
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? p.primary.withValues(alpha: .65)
                                      : isToday
                                          ? p.borderHighlight
                                          : p.borderSubtle.withValues(
                                              alpha: isFuture ? .35 : .8),
                                  width: isSelected ? 1.2 : 0.8,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    labels[i],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? p.primary
                                          : isFuture && !allowFutureSelection
                                              ? p.textTertiary
                                                  .withValues(alpha: .45)
                                              : p.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                      color: isSelected
                                          ? p.primary
                                          : isFuture && !allowFutureSelection
                                              ? p.textTertiary
                                                  .withValues(alpha: .45)
                                              : p.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: status == DayStripStatus.completed
                                        ? 10
                                        : 5,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      borderRadius: BorderRadius.circular(99),
                                      border: status == DayStripStatus.rest
                                          ? Border.all(
                                              color: p.textTertiary
                                                  .withValues(alpha: .28),
                                              width: 0.8,
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
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
  }
}
