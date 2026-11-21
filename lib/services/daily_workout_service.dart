import 'dart:convert';
import 'dart:math' as math;

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

Future<T> runSerializedWorkoutWrite<T>(
  Future<T> Function() action, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final previous = _writes[prefs] ?? Future<void>.value();
  final next = previous.then((_) => action());
  _writes[prefs] = next.then<void>((_) {}, onError: (Object _) {});
  return next;
}

Future<void> awaitPendingWorkoutWrites(SharedPreferences prefs) async {
  final pending = _writes[prefs];
  if (pending != null) await pending;
}

Future<void> _serialize(Future<void> Function() write) =>
    runSerializedWorkoutWrite(write);

Future<void> writeJson(
    SharedPreferences prefs, String key, Object value) async {
  if (!await prefs.setString(key, jsonEncode(value))) {
    throw StateError('保存失败，请重试');
  }
}

Map<String, DailyWorkout> decodeDailyWorkouts(String? raw) {
  if (raw == null) return {};
  final rawDecoded = jsonDecode(raw);
  if (rawDecoded is! Map) throw const FormatException('训练记录格式无效');
  final decoded = Map<String, dynamic>.from(rawDecoded);
  return decoded.map((date, value) {
    if (value is! Map) throw const FormatException('训练记录格式无效');
    final session = DailyWorkout.fromJson(Map<String, dynamic>.from(value));
    if (session.date != date) throw const FormatException('训练日期不一致');
    return MapEntry(date, session);
  });
}

Future<Map<String, DailyWorkout>> migrateLegacyDoneToDailyWorkouts(
  SharedPreferences prefs, {
  required int? year,
  required int? week,
  required String? rawDone,
}) async {
  if (year == null || week == null || rawDone == null) return {};
  try {
    final decoded = jsonDecode(rawDone);
    if (decoded is! Map) return {};
    final plan = await loadWorkoutPlan(legacyWorkoutDays, preferences: prefs);
    final done = Map<String, dynamic>.from(decoded);
    final monday = startOfIsoWeekByYearWeek(year, week);
    final sessions = <String, DailyWorkout>{};
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
        final date =
            dayKey(DateTime(monday.year, monday.month, monday.day + day));
        sessions[date] = DailyWorkout(date: date, blocks: blocks);
      }
    }
    return sessions;
  } catch (_) {
    // Corrupted legacy progress must never brick modern daily workout loading.
    return {};
  }
}

Future<Map<String, DailyWorkout>> loadDailyWorkouts() async {
  final prefs = await SharedPreferences.getInstance();
  await awaitPendingWorkoutWrites(prefs);
  if (!prefs.containsKey(dailyWorkoutsKey)) {
    await _serialize(() async {
      if (prefs.containsKey(dailyWorkoutsKey)) return;
      int? year;
      int? week;
      String? raw;
      try {
        year = prefs.getInt('recomp_done_v6_year');
        week = prefs.getInt('recomp_done_v6_week');
        raw = prefs.getString('recomp_done_v6');
      } catch (_) {
        // Malformed legacy key types should not block initialization.
      }
      // Never reinterpret old exercise indices using the new routines.
      final sessions = await migrateLegacyDoneToDailyWorkouts(
        prefs,
        year: year,
        week: week,
        rawDone: raw,
      );
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
  bool preview = false,
}) {
  if (preview) {
    return [
      for (var i = 0; i < template.exercises.length; i++)
        WorkoutBlock(
          id: 'preview_${date}_${template.id}_$i',
          exercise: template.exercises[i],
        ),
    ];
  }
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
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('训练模板格式无效');
  }
  final values = decoded.map((value) {
    if (value is! Map) throw const FormatException('训练模板格式无效');
    return WorkoutTemplate.fromJson(Map<String, dynamic>.from(value));
  }).toList();
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
  final decoded = jsonDecode(raw);
  if (decoded is! List || decoded.length != 7) {
    throw const FormatException('每周参考安排必须有 7 天');
  }
  final list = <String>[];
  for (final item in decoded) {
    if (item is! String) {
      throw const FormatException('每周参考安排格式无效');
    }
    list.add(item);
  }
  return list;
}

Future<List<String>> loadWeeklySchedule() async {
  final prefs = await SharedPreferences.getInstance();
  await awaitPendingWorkoutWrites(prefs);
  return decodeWeeklySchedule(prefs.getString(weeklyScheduleKey));
}

Future<void> saveWeeklySchedule(List<String> schedule) => _serialize(() async {
      decodeWeeklySchedule(jsonEncode(schedule));
      final prefs = await SharedPreferences.getInstance();
      await writeJson(prefs, weeklyScheduleKey, schedule);
    });

final _templateStampBlockId = RegExp(r'^tpl_\d{4}-\d{2}-\d{2}_\d+_\d+_(\d+)$');

String? _templateBlockSemanticKey(WorkoutBlock block) {
  final match = _templateStampBlockId.firstMatch(block.id);
  if (match == null) return null;
  return '${match.group(1)}|${jsonEncode(block.exercise.toJson())}';
}

/// Merge by date and stable block ID; never replace an entire day's other blocks.
/// Deduplicates identical multi-device template-timestamp blocks by slot + exercise.
String mergeDailyWorkouts(String? currentRaw, String incomingRaw) {
  final current = decodeDailyWorkouts(currentRaw);
  final incoming = decodeDailyWorkouts(incomingRaw);
  for (final entry in incoming.entries) {
    final previous = current[entry.key];
    final blocks = <String, WorkoutBlock>{
      for (final block in previous?.blocks ?? <WorkoutBlock>[]) block.id: block,
    };
    final existingTemplateSlots = <String, List<String>>{};
    for (final block in previous?.blocks ?? <WorkoutBlock>[]) {
      final key = _templateBlockSemanticKey(block);
      if (key != null) {
        existingTemplateSlots.putIfAbsent(key, () => []).add(block.id);
      }
    }
    final incomingIds = entry.value.blocks.map((b) => b.id).toSet();
    for (final queue in existingTemplateSlots.values) {
      queue.removeWhere(incomingIds.contains);
    }

    for (final block in entry.value.blocks) {
      if (blocks.containsKey(block.id)) {
        blocks[block.id] = block;
        continue;
      }
      final semanticKey = _templateBlockSemanticKey(block);
      final matchingIds =
          semanticKey == null ? null : existingTemplateSlots[semanticKey];
      if (matchingIds != null && matchingIds.isNotEmpty) {
        final existingId = matchingIds.removeAt(0);
        final existing = blocks[existingId]!;
        blocks[existingId] = existing.copyWith(
          completedSets: math.max(existing.completedSets, block.completedSets),
        );
      } else {
        blocks[block.id] = block;
      }
    }

    final mergedBlocks = blocks.values.toList();
    final rested = mergedBlocks.isEmpty &&
        (entry.value.rested || (previous?.rested ?? false));
    current[entry.key] = DailyWorkout(
      date: entry.key,
      blocks: mergedBlocks,
      rested: rested,
      templateId:
          rested ? null : (entry.value.templateId ?? previous?.templateId),
      templateName:
          rested ? null : (entry.value.templateName ?? previous?.templateName),
    );
  }
  return jsonEncode({for (final e in current.entries) e.key: e.value.toJson()});
}
