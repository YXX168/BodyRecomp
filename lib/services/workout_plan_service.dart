import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recomp_models.dart';

const workoutPlanKey = 'recomp_workout_plan_v1';

Future<List<WorkoutDay>> loadWorkoutPlan(
  List<WorkoutDay> defaults, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final raw = prefs.getString(workoutPlanKey);
  if (raw == null) return List<WorkoutDay>.from(defaults);
  try {
    final values = jsonDecode(raw) as List;
    final result = values
        .whereType<Map>()
        .map((value) => WorkoutDay.fromJson(Map<String, dynamic>.from(value)))
        .toList();
    return result.length == defaults.length
        ? result
        : List<WorkoutDay>.from(defaults);
  } catch (_) {
    return List<WorkoutDay>.from(defaults);
  }
}

Future<void> saveWorkoutPlan(
  List<WorkoutDay> plan, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  await prefs.setString(
    workoutPlanKey,
    jsonEncode(plan.map((day) => day.toJson()).toList()),
  );
}

Future<void> resetWorkoutPlan({SharedPreferences? preferences}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  await prefs.remove(workoutPlanKey);
}
