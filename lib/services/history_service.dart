import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recomp_models.dart';

int isoWeekYear(DateTime date) {
  final day = dateOnly(date);
  return day.add(Duration(days: 4 - day.weekday)).year;
}

int isoWeekNumber(DateTime date) {
  final day = dateOnly(date);
  final thursday = day.add(Duration(days: 4 - day.weekday));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final firstIsoThursday =
      firstThursday.add(Duration(days: 4 - firstThursday.weekday));
  return 1 + (thursday.difference(firstIsoThursday).inDays ~/ 7);
}

DateTime startOfIsoWeek(DateTime date) =>
    dateOnly(date).subtract(Duration(days: date.weekday - 1));

DateTime startOfIsoWeekByYearWeek(int isoYear, int isoWeek) {
  final firstMonday = startOfIsoWeek(DateTime(isoYear, 1, 4));
  return firstMonday.add(Duration(days: (isoWeek - 1) * 7));
}

String historyKey(int year, int month) =>
    'recomp_history_${year}_${month.toString().padLeft(2, '0')}';

Map<int, int> countByWeekday(Map<String, dynamic> done) {
  final result = <int, int>{};
  done.forEach((key, value) {
    if (value != true) return;
    final parts = key.split('_');
    if (parts.length != 2) return;
    final weekday = int.tryParse(parts.first);
    if (weekday != null && weekday >= 0 && weekday < 7) {
      result[weekday] = (result[weekday] ?? 0) + 1;
    }
  });
  return result;
}

Map<int, int> countByDay(Map<String, dynamic> done) => countByWeekday(done);

Map<DateTime, int> countByActualDate(
  Map<String, dynamic> done,
  int isoYear,
  int isoWeek,
) {
  final monday = startOfIsoWeekByYearWeek(isoYear, isoWeek);
  return {
    for (final entry in countByWeekday(done).entries)
      dateOnly(monday.add(Duration(days: entry.key))): entry.value,
  };
}

Future<Map<int, int>> loadMonthHistory(
  SharedPreferences preferences,
  int year,
  int month,
) async {
  final raw = preferences.getString(historyKey(year, month));
  if (raw == null) return {};
  final daysInMonth = DateTime(year, month + 1, 0).day;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final result = <int, int>{};
    map.forEach((key, value) {
      final day = int.tryParse(key);
      final count = value is int ? value : int.tryParse('$value');
      if (day != null &&
          day >= 1 &&
          day <= daysInMonth &&
          count != null &&
          count > 0) {
        result[day] = count;
      }
    });
    return result;
  } catch (_) {
    return {};
  }
}

Future<Map<String, dynamic>> _readMonthHistoryRaw(
  SharedPreferences preferences,
  int year,
  int month,
) async {
  final existing = preferences.getString(historyKey(year, month));
  if (existing == null) return {};
  try {
    return jsonDecode(existing) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

Future<void> _writeMonthHistoryRaw(
  SharedPreferences preferences,
  int year,
  int month,
  Map<String, dynamic> history,
) async {
  final cleaned = <String, dynamic>{};
  final daysInMonth = DateTime(year, month + 1, 0).day;
  history.forEach((key, value) {
    final day = int.tryParse(key);
    final count = value is int ? value : int.tryParse('$value');
    if (day != null &&
        day >= 1 &&
        day <= daysInMonth &&
        count != null &&
        count > 0) {
      cleaned['$day'] = count;
    }
  });
  await preferences.setString(historyKey(year, month), jsonEncode(cleaned));
}

Future<void> saveActualDateCountsToHistory(
  SharedPreferences preferences,
  Map<DateTime, int> dateCounts,
) async {
  final grouped = <String, Map<int, int>>{};
  for (final entry in dateCounts.entries) {
    final day = dateOnly(entry.key);
    grouped.putIfAbsent('${day.year}_${day.month}', () => {})[day.day] =
        entry.value;
  }
  for (final group in grouped.entries) {
    final parts = group.key.split('_');
    final year = int.parse(parts.first);
    final month = int.parse(parts.last);
    final history = await _readMonthHistoryRaw(preferences, year, month);
    group.value.forEach((day, count) {
      if (count > 0) {
        history['$day'] = count;
      } else {
        history.remove('$day');
      }
    });
    await _writeMonthHistoryRaw(preferences, year, month, history);
  }
}

Future<void> saveWeekDoneToHistory(
  SharedPreferences preferences,
  Map<String, dynamic> done,
  int isoYear,
  int isoWeek,
) async {
  final counts = countByActualDate(done, isoYear, isoWeek);
  final monday = startOfIsoWeekByYearWeek(isoYear, isoWeek);
  for (var i = 0; i < 7; i++) {
    counts.putIfAbsent(dateOnly(monday.add(Duration(days: i))), () => 0);
  }
  await saveActualDateCountsToHistory(preferences, counts);
}

Future<void> saveToMonthHistory(
  SharedPreferences preferences,
  int year,
  int month,
  Map<int, int> dayCounts,
) async {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final dateCounts = <DateTime, int>{};
  for (final entry in dayCounts.entries) {
    if (entry.key >= 1 && entry.key <= daysInMonth) {
      dateCounts[DateTime(year, month, entry.key)] = entry.value;
    }
  }
  await saveActualDateCountsToHistory(preferences, dateCounts);
}
