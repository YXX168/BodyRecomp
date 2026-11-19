import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/exercise_library.dart';
import '../models/daily_workout.dart';
import '../models/library_exercise.dart';
import 'daily_workout_service.dart';

const String exerciseLibraryKey = 'recomp_exercise_library_v1';

final _libraryWrites = Expando<Future<void>>('library writes');

Future<T> _serializeLibrary<T>(Future<T> Function() action) async {
  final prefs = await SharedPreferences.getInstance();
  final previous = _libraryWrites[prefs] ?? Future<void>.value();
  final next = previous.then((_) => action());
  _libraryWrites[prefs] = next.then<void>((_) {}, onError: (Object _) {});
  return next;
}

List<LibraryExercise> decodeExerciseLibrary(String? raw) {
  if (raw == null) return buildDefaultExerciseLibrary();
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('动作库数据格式无效');
  }
  final items = decoded
      .map((item) =>
          LibraryExercise.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
  if (items.map((item) => item.id).toSet().length != items.length) {
    throw const FormatException('动作库存在重复 ID');
  }
  return items;
}

Future<List<LibraryExercise>> loadExerciseLibrary() async {
  final prefs = await SharedPreferences.getInstance();
  final pending = _libraryWrites[prefs];
  if (pending != null) await pending;
  return decodeExerciseLibrary(prefs.getString(exerciseLibraryKey));
}

Future<void> saveExerciseLibrary(List<LibraryExercise> items) =>
    _serializeLibrary(() async {
      final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
      decodeExerciseLibrary(encoded);
      final prefs = await SharedPreferences.getInstance();
      await writeJson(
        prefs,
        exerciseLibraryKey,
        items.map((item) => item.toJson()).toList(),
      );
    });

Future<List<LibraryExercise>> addLibraryExercise(LibraryExercise item) =>
    _serializeLibrary(() async {
      final prefs = await SharedPreferences.getInstance();
      final current =
          decodeExerciseLibrary(prefs.getString(exerciseLibraryKey));
      if (current.any((existing) => existing.id == item.id)) {
        throw const FormatException('动作库 ID 已存在');
      }
      final next = [item, ...current];
      await writeJson(
        prefs,
        exerciseLibraryKey,
        next.map((e) => e.toJson()).toList(),
      );
      return next;
    });

Future<List<LibraryExercise>> updateLibraryExercise(LibraryExercise item) =>
    _serializeLibrary(() async {
      final prefs = await SharedPreferences.getInstance();
      final current =
          decodeExerciseLibrary(prefs.getString(exerciseLibraryKey));
      final index = current.indexWhere((existing) => existing.id == item.id);
      final next = List<LibraryExercise>.from(current);
      if (index < 0) {
        next.insert(0, item);
      } else {
        next[index] = item;
      }
      await writeJson(
        prefs,
        exerciseLibraryKey,
        next.map((e) => e.toJson()).toList(),
      );
      return next;
    });

Future<List<LibraryExercise>> deleteLibraryExercise(String id) =>
    _serializeLibrary(() async {
      final prefs = await SharedPreferences.getInstance();
      final current =
          decodeExerciseLibrary(prefs.getString(exerciseLibraryKey));
      final next = current.where((item) => item.id != id).toList();
      await writeJson(
        prefs,
        exerciseLibraryKey,
        next.map((e) => e.toJson()).toList(),
      );
      return next;
    });

Future<List<LibraryExercise>> restoreDefaultExerciseLibrary({
  bool keepCustom = true,
}) =>
    _serializeLibrary(() async {
      final prefs = await SharedPreferences.getInstance();
      final current =
          decodeExerciseLibrary(prefs.getString(exerciseLibraryKey));
      final defaults = buildDefaultExerciseLibrary();
      final defaultIds = defaults.map((e) => e.id).toSet();
      final currentMap = {for (final item in current) item.id: item};
      final restored = <LibraryExercise>[
        for (final def in defaults) currentMap[def.id] ?? def,
        if (keepCustom)
          ...current.where((item) => !defaultIds.contains(item.id)),
      ];
      await writeJson(
        prefs,
        exerciseLibraryKey,
        restored.map((e) => e.toJson()).toList(),
      );
      return restored;
    });

String mergeExerciseLibrary(String? currentRaw, String incomingRaw) {
  final current = decodeExerciseLibrary(currentRaw);
  final incoming = decodeExerciseLibrary(incomingRaw);
  final merged = <String, LibraryExercise>{
    for (final item in current) item.id: item,
    for (final item in incoming) item.id: item,
  };
  return jsonEncode(merged.values.map((item) => item.toJson()).toList());
}

/// Groups library items cleanly into category buckets for picker & browser views.
List<WorkoutTemplate> groupExerciseLibrary(List<LibraryExercise> items) {
  final byCategory = <String, List<LibraryExercise>>{};
  for (final item in items) {
    byCategory.putIfAbsent(item.category, () => []).add(item);
  }
  final orderedKeys = <String>[
    for (final category in exerciseCategories)
      if (byCategory.containsKey(category)) category,
    ...byCategory.keys.where((c) => !exerciseCategories.contains(c)),
  ];
  return [
    for (final category in orderedKeys)
      WorkoutTemplate(
        id: 'library_${_categorySlug(category)}',
        name: category,
        exercises: byCategory[category]!.map((e) => e.exercise).toList(),
      ),
  ];
}

String _categorySlug(String category) => switch (category) {
      '胸部' => 'chest',
      '背部' => 'back',
      '肩部' => 'shoulders',
      '腿臀' => 'legs',
      '手臂' => 'arms',
      '核心' => 'core',
      '有氧恢复' => 'cardio',
      '其他' => 'other',
      _ => category,
    };
