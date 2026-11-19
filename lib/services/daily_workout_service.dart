import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/legacy_workouts.dart';
import '../data/workout_templates.dart';
import '../models/daily_workout.dart';
import 'history_service.dart';
import 'workout_plan_service.dart';

const dailyWorkoutsKey = 'recomp_daily_workouts_v1';
const workoutTemplatesKey = 'recomp_templates_v1';
const weeklyScheduleKey = 'recomp_schedule_v1';

final _writes = Expando<Future<void>>('workout writes');
Future<void> _serialize(Future<void> Function() write) async {
  final prefs = await SharedPreferences.getInstance();
  final previous = _writes[prefs] ?? Future<void>.value();
  final next = previous.then((_) => write());
  _writes[prefs] = next.catchError((Object _) {});
  await next;
}

Future<void> writeJson(
    SharedPreferences prefs, String key, Object value) async {
  if (!await prefs.setString(key, jsonEncode(value))) {
    throw StateError('保存失败，请重试');
  }
}

Map<String, DailyWorkout> decodeDailyWorkouts(String? raw) {
  if (raw == null) return {};
  final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  return decoded.map((date, value) {
    final session =
        DailyWorkout.fromJson(Map<String, dynamic>.from(value as Map));
    if (session.date != date) throw const FormatException('训练日期不一致');
    return MapEntry(date, session);
  });
}

Future<Map<String, DailyWorkout>> loadDailyWorkouts() async {
  final prefs = await SharedPreferences.getInstance();
  final pending = _writes[prefs];
  if (pending != null) await pending;
  if (!prefs.containsKey(dailyWorkoutsKey)) {
    await _serialize(() async {
      if (prefs.containsKey(dailyWorkoutsKey)) return;
      final sessions = <String, DailyWorkout>{};
      final year = prefs.getInt('recomp_done_v6_year');
      final week = prefs.getInt('recomp_done_v6_week');
      final raw = prefs.getString('recomp_done_v6');
      // Never reinterpret old exercise indices using the new routines.
      if (year != null && week != null && raw != null) {
        final plan =
            await loadWorkoutPlan(legacyWorkoutDays, preferences: prefs);
        final done = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final monday = startOfIsoWeekByYearWeek(year, week);
        for (var day = 0; day < plan.length; day++) {
          final blocks = <WorkoutBlock>[];
          for (var index = 0; index < plan[day].exercises.length; index++) {
            final exercise = plan[day].exercises[index];
            final value = done['${day}_$index'];
            final count = value == true
                ? exercise.sets
                : value is num
                    ? value.toInt().clamp(0, exercise.sets)
                    : 0;
            if (count > 0) {
              blocks.add(WorkoutBlock(
                  id: 'legacy_${day}_$index',
                  exercise: exercise,
                  completedSets: count));
            }
          }
          if (blocks.isNotEmpty) {
            final date = dayKey(monday.add(Duration(days: day)));
            sessions[date] = DailyWorkout(date: date, blocks: blocks);
          }
        }
      }
      await writeJson(prefs, dailyWorkoutsKey,
          {for (final e in sessions.entries) e.key: e.value.toJson()});
    });
  }
  return decodeDailyWorkouts(prefs.getString(dailyWorkoutsKey));
}

Future<void> saveDailyWorkout(DailyWorkout session) => _serialize(() async {
      DailyWorkout.fromJson(session.toJson());
      final prefs = await SharedPreferences.getInstance();
      final sessions = decodeDailyWorkouts(prefs.getString(dailyWorkoutsKey));
      sessions[session.date] = session;
      await writeJson(prefs, dailyWorkoutsKey,
          {for (final e in sessions.entries) e.key: e.value.toJson()});
    });

/// Removes a day's custom override so it falls back to its weekday fixed template.
Future<void> deleteDailyWorkout(String date) => _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final sessions = decodeDailyWorkouts(prefs.getString(dailyWorkoutsKey));
      if (sessions.remove(date) != null) {
        await writeJson(prefs, dailyWorkoutsKey,
            {for (final e in sessions.entries) e.key: e.value.toJson()});
      }
    });

List<WorkoutBlock> instantiateTemplateBlocks(
  WorkoutTemplate template,
  String date, {
  int seed = 0,
}) {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return [
    for (var i = 0; i < template.exercises.length; i++)
      WorkoutBlock(
        id: 'tpl_${date}_${stamp}_${seed}_$i',
        exercise: template.exercises[i],
      ),
  ];
}

List<WorkoutTemplate> decodeWorkoutTemplates(String? raw) {
  if (raw == null) return List.from(defaultTemplates);
  final values = (jsonDecode(raw) as List)
      .map((value) =>
          WorkoutTemplate.fromJson(Map<String, dynamic>.from(value as Map)))
      .toList();
  if (values.map((value) => value.id).toSet().length != values.length) {
    throw const FormatException('模板 ID 重复');
  }
  return values;
}

Future<List<WorkoutTemplate>> loadWorkoutTemplates() async {
  final prefs = await SharedPreferences.getInstance();
  final pending = _writes[prefs];
  if (pending != null) await pending;
  return decodeWorkoutTemplates(prefs.getString(workoutTemplatesKey));
}

Future<void> saveWorkoutTemplates(List<WorkoutTemplate> templates) =>
    _serialize(() async {
      decodeWorkoutTemplates(
          jsonEncode(templates.map((e) => e.toJson()).toList()));
      final prefs = await SharedPreferences.getInstance();
      await writeJson(prefs, workoutTemplatesKey,
          templates.map((e) => e.toJson()).toList());
    });

/// Atomically deletes a template and clears any weekday binding referencing it.
Future<void> deleteWorkoutTemplate(String templateId) => _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final templates =
          decodeWorkoutTemplates(prefs.getString(workoutTemplatesKey))
              .where((t) => t.id != templateId)
              .toList();
      final schedule = decodeWeeklySchedule(prefs.getString(weeklyScheduleKey))
          .map((id) => id == templateId ? '' : id)
          .toList();
      await writeJson(prefs, workoutTemplatesKey,
          templates.map((e) => e.toJson()).toList());
      await writeJson(prefs, weeklyScheduleKey, schedule);
    });

Future<WorkoutTemplate> duplicateWorkoutTemplate(WorkoutTemplate source) async {
  late WorkoutTemplate created;
  await _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    final templates =
        decodeWorkoutTemplates(prefs.getString(workoutTemplatesKey));
    created = WorkoutTemplate(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: '${source.name} 副本',
      note: source.note,
      exercises: List.from(source.exercises),
    );
    templates.add(created);
    await writeJson(
        prefs, workoutTemplatesKey, templates.map((e) => e.toJson()).toList());
  });
  return created;
}

List<String> decodeWeeklySchedule(String? raw) {
  if (raw == null) return List.from(defaultSchedule);
  final list = (jsonDecode(raw) as List).cast<String>();
  if (list.length != 7) throw const FormatException('每周参考安排必须有 7 天');
  return list;
}

Future<List<String>> loadWeeklySchedule() async {
  final prefs = await SharedPreferences.getInstance();
  final pending = _writes[prefs];
  if (pending != null) await pending;
  return decodeWeeklySchedule(prefs.getString(weeklyScheduleKey));
}

Future<void> saveWeeklySchedule(List<String> schedule) => _serialize(() async {
      decodeWeeklySchedule(jsonEncode(schedule));
      final prefs = await SharedPreferences.getInstance();
      await writeJson(prefs, weeklyScheduleKey, schedule);
    });

/// Merge by date and stable block ID; never replace an entire day's other blocks.
String mergeDailyWorkouts(String? currentRaw, String incomingRaw) {
  final current = decodeDailyWorkouts(currentRaw);
  final incoming = decodeDailyWorkouts(incomingRaw);
  for (final entry in incoming.entries) {
    final previous = current[entry.key];
    final blocks = <String, WorkoutBlock>{
      for (final block in previous?.blocks ?? <WorkoutBlock>[]) block.id: block,
      for (final block in entry.value.blocks) block.id: block,
    }.values.toList();
    current[entry.key] = DailyWorkout(
        date: entry.key,
        blocks: blocks,
        rested: blocks.isEmpty &&
            (entry.value.rested || (previous?.rested ?? false)));
  }
  return jsonEncode({for (final e in current.entries) e.key: e.value.toJson()});
}
