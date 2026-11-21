import 'dart:convert';

import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/models/library_exercise.dart';
import 'package:body_recomp/models/recomp_models.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:body_recomp/services/exercise_library_service.dart';
import 'package:body_recomp/services/record_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('default library contains 52 built-in exercises with unique IDs',
      () async {
    final items = await loadExerciseLibrary();
    expect(items, hasLength(52));
    expect(items.map((e) => e.id).toSet(), hasLength(52));
    expect(items.every((e) => e.isBuiltIn), isTrue);
  });

  test('library CRUD supports add, edit, delete, and restoring built-ins',
      () async {
    const custom = LibraryExercise(
      id: 'custom_1',
      category: '胸部',
      exercise: Exercise(
        name: '双杠臂屈伸',
        muscles: ['胸部'],
        muscleTarget: '下胸',
        sets: 4,
        reps: '8-12',
        rest: '90s',
      ),
      isFavorite: true,
    );

    await addLibraryExercise(custom);
    var loaded = await loadExerciseLibrary();
    expect(loaded, hasLength(53));
    expect(loaded.first.id, 'custom_1');
    expect(loaded.first.isFavorite, isTrue);

    await updateLibraryExercise(
      custom.copyWith(
        exercise: custom.exercise.copyWith(sets: 5, reps: '10-12'),
      ),
    );
    loaded = await loadExerciseLibrary();
    expect(loaded.first.exercise.sets, 5);

    // Delete a built-in item and verify custom survives restore.
    await deleteLibraryExercise('builtin_library_chest_0');
    loaded = await loadExerciseLibrary();
    expect(loaded.any((e) => e.id == 'builtin_library_chest_0'), isFalse);

    await restoreDefaultExerciseLibrary(keepCustom: true);
    loaded = await loadExerciseLibrary();
    expect(loaded.any((e) => e.id == 'builtin_library_chest_0'), isTrue);
    expect(loaded.any((e) => e.id == 'custom_1'), isTrue);

    await deleteLibraryExercise('custom_1');
    loaded = await loadExerciseLibrary();
    expect(loaded.any((e) => e.id == 'custom_1'), isFalse);
  });

  test('backup export and merge import preserve custom library items',
      () async {
    const customA = LibraryExercise(
      id: 'custom_a',
      category: '背部',
      exercise: Exercise(
        name: '山羊挺身',
        muscles: ['背部'],
        muscleTarget: '竖脊肌',
        sets: 3,
        reps: '12-15',
        rest: '60s',
      ),
    );
    await addLibraryExercise(customA);
    final backupA = await exportAllData();

    SharedPreferences.setMockInitialValues({});
    const customB = LibraryExercise(
      id: 'custom_b',
      category: '肩部',
      exercise: Exercise(
        name: '阿诺德推举',
        muscles: ['肩部'],
        muscleTarget: '全束',
        sets: 4,
        reps: '10-12',
        rest: '90s',
      ),
    );
    await addLibraryExercise(customB);

    await importAllData(backupA, mode: ImportMode.merge);
    final merged = await loadExerciseLibrary();
    expect(merged.any((e) => e.id == 'custom_a'), isTrue);
    expect(merged.any((e) => e.id == 'custom_b'), isTrue);

    // Corrupted library payload in backup is rejected before mutating state.
    final badBackup = jsonEncode({
      'schemaVersion': 3,
      'preferences': {exerciseLibraryKey: '{"bad":true}'},
    });
    await expectLater(
      importAllData(badBackup, mode: ImportMode.overwrite),
      throwsFormatException,
    );
    expect(
        (await loadExerciseLibrary()).any((e) => e.id == 'custom_b'), isTrue);

    // Overwrite import replaces local custom library items cleanly.
    await importAllData(backupA, mode: ImportMode.overwrite);
    final overwritten = await loadExerciseLibrary();
    expect(overwritten.any((e) => e.id == 'custom_a'), isTrue);
    expect(overwritten.any((e) => e.id == 'custom_b'), isFalse);

    // Duplicate IDs inside library backup are rejected.
    final dupBackup = jsonEncode({
      'schemaVersion': 3,
      'preferences': {
        exerciseLibraryKey: jsonEncode([customA.toJson(), customA.toJson()]),
      },
    });
    await expectLater(
      importAllData(dupBackup, mode: ImportMode.merge),
      throwsFormatException,
    );
  });

  test('deleteWorkoutTemplate removes template and clears dangling schedule',
      () async {
    await saveWorkoutTemplates(List.from(defaultTemplates));
    await saveWeeklySchedule(
      ['push', 'pull', 'push', 'legs', 'upper_pump', 'cardio', 'recovery'],
    );

    await deleteWorkoutTemplate('push');
    final templates = await loadWorkoutTemplates();
    final schedule = await loadWeeklySchedule();

    expect(templates.any((t) => t.id == 'push'), isFalse);
    expect(schedule[0], '');
    expect(schedule[2], '');
    expect(schedule[1], 'pull');

    final copy = await duplicateWorkoutTemplate(templates.first);
    expect(copy.name, '${templates.first.name} 副本');
    expect((await loadWorkoutTemplates()).any((t) => t.id == copy.id), isTrue);
  });

  test('computeWorkoutAnalytics calculates streaks and 7-day volume accurately',
      () {
    final today = DateTime(2026, 11, 20);
    final ex = defaultTemplates.first.exercises.first;
    final sessions = {
      '2026-11-16': DailyWorkout(
        date: '2026-11-16',
        blocks: [WorkoutBlock(id: '1', exercise: ex, completedSets: 4)],
      ),
      '2026-11-18': DailyWorkout(
        date: '2026-11-18',
        blocks: [WorkoutBlock(id: '2', exercise: ex, completedSets: 3)],
      ),
      '2026-11-19': DailyWorkout(
        date: '2026-11-19',
        blocks: [WorkoutBlock(id: '3', exercise: ex, completedSets: 5)],
      ),
      '2026-11-20': DailyWorkout(
        date: '2026-11-20',
        blocks: [WorkoutBlock(id: '4', exercise: ex, completedSets: 2)],
      ),
    };

    final analytics = computeWorkoutAnalytics(sessions, today);
    expect(analytics.currentStreak, 3);
    expect(analytics.longestStreak, 3);
    expect(analytics.monthCompletedSets, 14);
    expect(analytics.last7Days, hasLength(7));
    expect(analytics.last7Days.last.completedSets, 2);
  });
}
