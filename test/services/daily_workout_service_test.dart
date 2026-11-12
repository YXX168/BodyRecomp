import 'dart:convert';
import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:body_recomp/services/nutrition_service.dart';
import 'package:body_recomp/services/record_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final bench = defaultTemplates.first.exercises.first;
  DailyWorkout session(String date, {String id = 'bench', int done = 1}) =>
      DailyWorkout(
          date: date,
          blocks: [WorkoutBlock(id: id, exercise: bench, completedSets: done)]);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'legacy migration uses old snapshots and original ISO dates exactly once',
      () async {
    SharedPreferences.setMockInitialValues({
      'recomp_done_v6_year': 2026,
      'recomp_done_v6_week': 46,
      'recomp_done_v6': jsonEncode({'1_0': true, '1_1': 2})
    });
    final records = await loadDailyWorkouts();
    final tuesday = records['2026-11-10']!;
    expect(tuesday.blocks.first.exercise.name, '倒蹬机');
    expect(tuesday.blocks.first.completedSets, 4);
    expect(tuesday.blocks.last.completedSets, 2);
    await saveDailyWorkout(tuesday.copyWith(blocks: [tuesday.blocks.last]));
    expect((await loadDailyWorkouts())['2026-11-10']!.blocks, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('recomp_done_v6'), contains('1_0'));
  });

  test('concurrent writes preserve different dates across weeks and months',
      () async {
    await loadDailyWorkouts();
    await Future.wait([
      saveDailyWorkout(session('2026-11-01')),
      saveDailyWorkout(session('2026-11-09')),
      saveDailyWorkout(session('2026-12-01'))
    ]);
    expect((await loadDailyWorkouts()).keys,
        containsAll(['2026-11-01', '2026-11-09', '2026-12-01']));
  });

  test('template changes cannot mutate dated exercise snapshots', () async {
    await loadDailyWorkouts();
    await saveDailyWorkout(session('2026-11-12', done: 2));
    await saveWorkoutTemplates([
      WorkoutTemplate(
          id: 'push',
          name: '新模板',
          exercises: [bench.copyWith(name: '其他动作', sets: 8)])
    ]);
    final old = (await loadDailyWorkouts())['2026-11-12']!.blocks.single;
    expect(old.exercise.name, '平板卧推');
    expect(old.completedSets, 2);
    expect(old.exercise.sets, 4);
  });

  test('corrupted data is surfaced without silently replacing it', () async {
    SharedPreferences.setMockInitialValues({dailyWorkoutsKey: '{bad json'});
    await expectLater(loadDailyWorkouts(), throwsFormatException);
    await expectLater(
        saveDailyWorkout(session('2026-11-12')), throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(dailyWorkoutsKey), '{bad json');
  });

  test('partial actual training overrides positional counts in month and year',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'recomp_history_2026_11', jsonEncode({'12': 9, '10': 3}));
    await loadDailyWorkouts();
    await saveDailyWorkout(session('2026-11-12'));
    final summary = await loadRecordSummary(prefs, 2026, 11);
    expect(summary.monthData, {10: 3, 12: 1});
    expect(summary.yearMonths[11], summary.monthData);
    await saveDailyWorkout(
        const DailyWorkout(date: '2026-11-12', rested: true));
    expect((await loadRecordSummary(prefs, 2026, 11)).monthData, {10: 3});
  });

  test('backups merge blocks and dates and round trip meals and templates',
      () async {
    await loadDailyWorkouts();
    await saveDailyWorkout(session('2026-11-12'));
    await saveMealEntry(
        '2026-11-12|breakfast',
        const MealEntry(
            date: '2026-11-12', meal: 'breakfast', actual: '鸡蛋', protein: 12));
    await saveWorkoutTemplates([
      WorkoutTemplate(id: 'custom1', name: '自选组合', exercises: [bench])
    ]);
    final backup = await exportAllData();
    await saveDailyWorkout(session('2026-11-13'));
    await saveDailyWorkout(session('2026-11-12', id: 'other'));
    await importAllData(backup);
    final records = await loadDailyWorkouts();
    expect(records.keys, containsAll(['2026-11-12', '2026-11-13']));
    expect(records['2026-11-12']!.blocks.map((b) => b.id),
        containsAll(['bench', 'other']));
    expect((await loadMeals()).values.single.protein, 12);
    await importAllData(backup, mode: ImportMode.overwrite);
    expect((await loadDailyWorkouts()).keys, ['2026-11-12']);
    expect((await loadWorkoutTemplates()).single.id, 'custom1');
    expect((jsonDecode(backup) as Map)['schemaVersion'], 3);
  });

  test('invalid imports are rejected before overwriting existing records',
      () async {
    await loadDailyWorkouts();
    await saveDailyWorkout(session('2026-11-12'));
    final invalid = session('2026-11-12', done: 9);
    final backup = jsonEncode({
      'schemaVersion': 3,
      'preferences': {
        dailyWorkoutsKey: jsonEncode({invalid.date: invalid.toJson()})
      }
    });
    await expectLater(importAllData(backup, mode: ImportMode.overwrite),
        throwsFormatException);
    expect((await loadDailyWorkouts())['2026-11-12']!.completedSets, 1);
    await expectLater(
        saveMealEntry(
            '2026-11-12|breakfast',
            const MealEntry(
                date: '2026-11-12',
                meal: 'breakfast',
                actual: '食物',
                calories: -1)),
        throwsFormatException);
  });

  test('changing the reference schedule leaves actual records intact',
      () async {
    await loadDailyWorkouts();
    await saveDailyWorkout(session('2026-11-12'));
    await saveWeeklySchedule(['legs', 'push', 'pull', '', '', '', '']);
    expect((await loadWeeklySchedule()).first, 'legs');
    expect(
        (await loadDailyWorkouts())['2026-11-12']!.blocks.single.exercise.name,
        '平板卧推');
  });
}
