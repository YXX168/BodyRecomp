import 'package:flutter/material.dart';
import '../models/daily_workout.dart';
import '../models/recomp_models.dart';

class WeekCalendar extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final Map<String, DailyWorkout> sessions;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  const WeekCalendar(
      {super.key,
      required this.date,
      required this.today,
      required this.sessions,
      required this.onChanged,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final monday = dateOnly(date.subtract(Duration(days: date.weekday - 1)));
    final current = dateOnly(today);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return Row(children: [
      for (var i = 0; i < 7; i++)
        Expanded(child: Builder(builder: (context) {
          final day = monday.add(Duration(days: i));
          final selected = day == dateOnly(date);
          final future = day.isAfter(current);
          final trained = (sessions[dayKey(day)]?.completedSets ?? 0) > 0;
          return Semantics(
              selected: selected,
              button: true,
              enabled: enabled && !future,
              label: '${day.month}月${day.day}日${trained ? '，有训练记录' : ''}',
              child: InkWell(
                key: ValueKey('week-day-${dayKey(day)}'),
                onTap: enabled && !future ? () => onChanged(day) : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(children: [
                      Text(['一', '二', '三', '四', '五', '六', '日'][i],
                          style: TextStyle(
                              fontSize: 9,
                              color: selected
                                  ? colors.primary
                                  : colors.onSurface.withValues(alpha: .43))),
                      const SizedBox(height: 7),
                      AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: 33,
                          height: 33 + (scale - 1) * 10,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: selected
                                  ? colors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: !selected && day == current
                                      ? colors.primary.withValues(alpha: .32)
                                      : Colors.transparent)),
                          child: Text('${day.day}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? colors.onPrimary
                                      : colors.onSurface.withValues(
                                          alpha: future ? .23 : .8)))),
                      const SizedBox(height: 6),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: trained
                                  ? colors.primary.withValues(alpha: .7)
                                  : Colors.transparent)),
                    ])),
              ));
        })),
    ]);
  }
}
