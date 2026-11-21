import 'package:flutter/material.dart';
import '../models/recomp_models.dart';
import '../theme/app_theme.dart';

/// Compact date header; opens the full calendar on demand.
class DailyDateBar extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final bool allowFutureNext;

  const DailyDateBar({
    super.key,
    required this.date,
    required this.today,
    required this.onChanged,
    this.enabled = true,
    this.allowFutureNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final day = dateOnly(date);
    final todayDay = dateOnly(today);
    final isToday = day == todayDay;
    final isFuture = day.isAfter(todayDay);
    final dateInk = isToday
        ? p.primary
        : isFuture
            ? p.accent
            : p.textPrimary;
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final prefix = isToday
        ? '今天 · '
        : isFuture
            ? '预览 · '
            : '';
    final label =
        '$prefix${date.year != today.year ? '${date.year}年' : ''}${date.month}月${date.day}日 周${weekdays[date.weekday - 1]}';

    final firstDate = DateTime(2000);
    final lastDate = allowFutureNext
        ? DateTime(todayDay.year + 1, todayDay.month, todayDay.day)
        : todayDay;
    final canGoNext = day.isBefore(lastDate);
    final canGoPrev = day.isAfter(firstDate);

    return Row(
      children: [
        Expanded(
          child: TextButton(
            key: const Key('choose-date'),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              foregroundColor: dateInk,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: !enabled
                ? null
                : () async {
                    final clampedInitial = day.isBefore(firstDate)
                        ? firstDate
                        : day.isAfter(lastDate)
                            ? lastDate
                            : day;
                    final value = await showDatePicker(
                      context: context,
                      initialDate: clampedInitial,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      helpText: '选择记录日期',
                    );
                    if (value != null && context.mounted) onChanged(value);
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded, size: 15, color: dateInk),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: dateInk,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: p.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (!isToday)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: TextButton(
              key: const Key('return-today'),
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                minimumSize: const Size(0, 28),
                backgroundColor:
                    p.primary.withValues(alpha: p.isDark ? .14 : .10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: enabled ? () => onChanged(todayDay) : null,
              child: Text(
                '回今天',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: p.primary,
                ),
              ),
            ),
          ),
        IconButton(
          key: const Key('previous-date'),
          tooltip: '前一天',
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          padding: EdgeInsets.zero,
          onPressed: enabled && canGoPrev
              ? () => onChanged(DateTime(day.year, day.month, day.day - 1))
              : null,
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 18,
            color: canGoPrev
                ? p.textSecondary
                : p.textTertiary.withValues(alpha: .35),
          ),
        ),
        IconButton(
          key: const Key('next-date'),
          tooltip: '后一天',
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          padding: EdgeInsets.zero,
          onPressed: enabled && canGoNext
              ? () => onChanged(DateTime(day.year, day.month, day.day + 1))
              : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: canGoNext
                ? p.textSecondary
                : p.textTertiary.withValues(alpha: .35),
          ),
        ),
      ],
    );
  }
}
