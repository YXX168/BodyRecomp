import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:body_recomp/models/recomp_models.dart';
import 'package:body_recomp/services/workout_plan_service.dart';

void main() {
  const defaults = [
    WorkoutDay(
      dayName: '周一',
      subtitle: '默认计划',
      badge: '默认',
      description: '测试',
      exercises: [
        Exercise(
          name: '卧推',
          muscles: ['胸'],
          muscleTarget: '上部',
          sets: 4,
          reps: '10-12',
          rest: '90s',
        ),
      ],
    ),
  ];

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('current workout schedule is used as the default plan', () async {
    final plan = await loadWorkoutPlan(defaults);
    expect(plan.single.exercises.single.name, '卧推');
  });

  test('edited workout plan persists and can reset to defaults', () async {
    final edited = [
      defaults.single.copyWith(
        exercises: [defaults.single.exercises.single.copyWith(name: '哑铃卧推')],
      ),
    ];
    await saveWorkoutPlan(edited);
    expect(
        (await loadWorkoutPlan(defaults)).single.exercises.single.name, '哑铃卧推');

    await resetWorkoutPlan();
    expect(
        (await loadWorkoutPlan(defaults)).single.exercises.single.name, '卧推');
  });
}
