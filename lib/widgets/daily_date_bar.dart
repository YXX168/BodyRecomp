import 'package:flutter/material.dart';
import '../models/recomp_models.dart';

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
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return Row(children: [
      IconButton(
          key: const Key('previous-date'),
          tooltip: '前一天',
          onPressed: enabled && date.isAfter(DateTime(2000))
              ? () => onChanged(DateTime(date.year, date.month, date.day - 1))
              : null,
          icon: const Icon(Icons.chevron_left)),
      Expanded(
          child: TextButton.icon(
        key: const Key('choose-date'),
        onPressed: !enabled
            ? null
            : () async {
                final value = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: dateOnly(today),
                    helpText: '选择记录日期');
                if (value != null) onChanged(value);
              },
        icon: const Icon(Icons.calendar_month_outlined, size: 15),
        label: Text(
            '${date.month}月${date.day}日 · 周${weekdays[date.weekday - 1]}${isToday ? ' · 今天' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      )),
      IconButton(
          key: const Key('next-date'),
          tooltip: '后一天',
          onPressed: enabled && dateOnly(date).isBefore(dateOnly(today))
              ? () => onChanged(DateTime(date.year, date.month, date.day + 1))
              : null,
          icon: const Icon(Icons.chevron_right)),
    ]);
  }
}
