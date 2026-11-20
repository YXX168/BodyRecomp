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

/// Calm, unified translucent Mon–Sun strip paired with compact [DailyDateBar].
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
          child: Row(
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
                            onTap: canTap ? () => onChanged(day) : null,
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                gradient: isSelected ? p.primaryGradient : null,
                                color: isSelected
                                    ? null
                                    : isToday
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
                                          ? p.onPrimary.withValues(alpha: .88)
                                          : isToday
                                              ? p.primary
                                              : isFuture &&
                                                      !allowFutureSelection
                                                  ? p.textTertiary
                                                      .withValues(alpha: .45)
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
                                                      !allowFutureSelection
                                                  ? p.textTertiary
                                                      .withValues(alpha: .45)
                                                  : p.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2.5),
                                  Container(
                                    width: status == DayStripStatus.completed
                                        ? 9
                                        : 3.5,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      borderRadius: BorderRadius.circular(99),
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
        ),
      ],
    );
  }
}
