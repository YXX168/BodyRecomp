import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import 'daily_workout_service.dart';
import 'history_service.dart';

class RecordSummary {
  final Map<int, int> monthData;
  final int yearTotal;
  final int yearTrainDays;
  final Map<int, Map<int, int>> yearMonths;

  const RecordSummary({
    required this.monthData,
    required this.yearTotal,
    required this.yearTrainDays,
    required this.yearMonths,
  });
}

class DayVolumePoint {
  final DateTime date;
  final int completedSets;
  final int trainedProjects;

  const DayVolumePoint({
    required this.date,
    required this.completedSets,
    required this.trainedProjects,
  });
}

class WorkoutAnalytics {
  final int currentStreak;
  final int longestStreak;
  final int monthCompletedSets;
  final List<DayVolumePoint> last7Days;

  const WorkoutAnalytics({
    required this.currentStreak,
    required this.longestStreak,
    required this.monthCompletedSets,
    required this.last7Days,
  });
}

WorkoutAnalytics computeWorkoutAnalytics(
  Map<String, DailyWorkout> sessions,
  DateTime today, {
  int? viewYear,
  int? viewMonth,
}) {
  final todayOnly = dateOnly(today);
  final trainedDays = <DateTime>{};
  var monthSets = 0;
  final targetYear = viewYear ?? todayOnly.year;
  final targetMonth = viewMonth ?? todayOnly.month;

  for (final session in sessions.values) {
    if (session.trainedProjects <= 0) continue;
    final parsed = DateTime.tryParse(session.date);
    if (parsed == null) continue;
    final day = dateOnly(parsed);
    trainedDays.add(day);
    if (day.year == targetYear && day.month == targetMonth) {
      monthSets += session.completedSets;
    }
  }

  // Current streak: consecutive trained days ending today or yesterday.
  var currentStreak = 0;
  var cursor = trainedDays.contains(todayOnly)
      ? todayOnly
      : DateTime(todayOnly.year, todayOnly.month, todayOnly.day - 1);
  while (trainedDays.contains(cursor)) {
    currentStreak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  // Longest streak across all dated workouts.
  var longestStreak = 0;
  if (trainedDays.isNotEmpty) {
    final sorted = trainedDays.toList()..sort();
    var run = 1;
    longestStreak = 1;
    for (var i = 1; i < sorted.length; i++) {
      final curr = sorted[i];
      final prev = sorted[i - 1];
      final diffDays = DateTime.utc(curr.year, curr.month, curr.day)
          .difference(DateTime.utc(prev.year, prev.month, prev.day))
          .inDays;
      if (diffDays == 1) {
        run++;
        longestStreak = math.max(longestStreak, run);
      } else {
        run = 1;
      }
    }
  }

  final last7Days = <DayVolumePoint>[
    for (var offset = 6; offset >= 0; offset--)
      () {
        final d = DateTime(
          todayOnly.year,
          todayOnly.month,
          todayOnly.day - offset,
        );
        final session = sessions[dayKey(d)];
        return DayVolumePoint(
          date: d,
          completedSets: session?.completedSets ?? 0,
          trainedProjects: session?.trainedProjects ?? 0,
        );
      }(),
  ];

  return WorkoutAnalytics(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    monthCompletedSets: monthSets,
    last7Days: last7Days,
  );
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
  try {
    final rawDone = preferences.getString('recomp_done_v6');
    if (rawDone != null) {
      final storedWeek =
          preferences.getInt('recomp_done_v6_week') ?? isoWeekNumber(current);
      final storedYear =
          preferences.getInt('recomp_done_v6_year') ?? isoWeekYear(current);
      final done = jsonDecode(rawDone) as Map<String, dynamic>;
      final currentCounts = countByActualDate(done, storedYear, storedWeek);
      for (final entry in currentCounts.entries) {
        if (entry.key.year == year && entry.value > 0) {
          months[entry.key.month]![entry.key.day] = entry.value;
        }
      }
    }
  } catch (_) {
    // Malformed current-week data should not hide valid archived history.
  }

  // Dated actual records take precedence over legacy positional progress.
  await awaitPendingWorkoutWrites(preferences);
  final sessions = decodeDailyWorkouts(preferences.getString(dailyWorkoutsKey));
  for (final session in sessions.values) {
    final date = DateTime.parse(session.date);
    if (date.year != year) continue;
    if (session.trainedProjects > 0) {
      months[date.month]![date.day] = session.trainedProjects;
    } else {
      months[date.month]!.remove(date.day);
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
    yearMonths: months,
  );
}
