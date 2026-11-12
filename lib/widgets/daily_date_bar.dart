import 'package:flutter/material.dart';
import '../models/recomp_models.dart';

/// A quiet date selector; the full calendar only opens on request.
class DailyDateBar extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  const DailyDateBar(
      {super.key,
      required this.date,
      required this.today,
      required this.onChanged,
      this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final isToday = dateOnly(date) == dateOnly(today);
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .45);
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final label =
        '${isToday ? '今天 · ' : ''}${date.year != today.year ? '${date.year}年' : ''}${date.month}月${date.day}日 周${weekdays[date.weekday - 1]}';
    return Row(children: [
      Expanded(
          child: TextButton(
              key: const Key('choose-date'),
              style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                  foregroundColor: colors.onSurface.withValues(alpha: .7),
                  minimumSize: const Size(0, 40)),
              onPressed: !enabled
                  ? null
                  : () async {
                      final value = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2000),
                          lastDate: dateOnly(today),
                          helpText: '选择记录日期');
                      if (value != null && context.mounted) onChanged(value);
                    },
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: muted),
                const SizedBox(width: 7),
                Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500))),
                const SizedBox(width: 3),
                Icon(Icons.expand_more_rounded, size: 14, color: muted),
              ]))),
      if (!isToday)
        TextButton(
            key: const Key('return-today'),
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 40)),
            onPressed: enabled ? () => onChanged(dateOnly(today)) : null,
            child: const Text('回今天', style: TextStyle(fontSize: 10))),
      IconButton(
          key: const Key('previous-date'),
          tooltip: '前一天',
          constraints: const BoxConstraints.tightFor(width: 34, height: 40),
          padding: EdgeInsets.zero,
          onPressed: enabled && date.isAfter(DateTime(2000))
              ? () => onChanged(DateTime(date.year, date.month, date.day - 1))
              : null,
          icon: const Icon(Icons.chevron_left_rounded, size: 19)),
      IconButton(
          key: const Key('next-date'),
          tooltip: '后一天',
          constraints: const BoxConstraints.tightFor(width: 34, height: 40),
          padding: EdgeInsets.zero,
          onPressed: enabled && dateOnly(date).isBefore(dateOnly(today))
              ? () => onChanged(DateTime(date.year, date.month, date.day + 1))
              : null,
          icon: const Icon(Icons.chevron_right_rounded, size: 19)),
    ]);
  }
}
