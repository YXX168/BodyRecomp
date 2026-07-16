import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'history_service.dart';

class RecordSummary {
  final Map<int, int> monthData;
  final int yearTotal;
  final int yearTrainDays;

  const RecordSummary({
    required this.monthData,
    required this.yearTotal,
    required this.yearTrainDays,
  });
}

Future<RecordSummary> loadRecordSummary(
  SharedPreferences preferences,
  int year,
  int month, {
  DateTime? now,
}) async {
  final months = <int, Map<int, int>>{};
  for (var value = 1; value <= 12; value++) {
    months[value] = await loadMonthHistory(preferences, year, value);
  }

  final current = now ?? DateTime.now();
  final rawDone = preferences.getString('recomp_done_v6');
  final storedWeek =
      preferences.getInt('recomp_done_v6_week') ?? isoWeekNumber(current);
  final storedYear =
      preferences.getInt('recomp_done_v6_year') ?? isoWeekYear(current);
  if (rawDone != null) {
    try {
      final done = jsonDecode(rawDone) as Map<String, dynamic>;
      final currentCounts = countByActualDate(done, storedYear, storedWeek);
      for (final entry in currentCounts.entries) {
        if (entry.key.year == year && entry.value > 0) {
          months[entry.key.month]![entry.key.day] = entry.value;
        }
      }
    } catch (_) {
      // Malformed current-week data should not hide valid archived history.
    }
  }

  var yearTotal = 0;
  var yearTrainDays = 0;
  for (final data in months.values) {
    yearTotal += data.values.fold(0, (sum, value) => sum + value);
    yearTrainDays += data.length;
  }

  return RecordSummary(
    monthData: Map<int, int>.from(months[month]!),
    yearTotal: yearTotal,
    yearTrainDays: yearTrainDays,
  );
}
