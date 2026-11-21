import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recomp_models.dart';
import 'daily_workout_service.dart';
import 'exercise_library_service.dart';
import 'nutrition_service.dart';
import 'rest_timer_service.dart';
import 'workout_plan_service.dart';

const int currentSchemaVersion = 3;
const String appDataVersion = '7.1.5';
const String profileKey = 'recomp_profile_v6';
const String weightHistoryKey = 'recomp_weight_history_v6';
const String measurementHistoryKey = 'recomp_measurements_v6';
const String exerciseLogsKey = 'recomp_exercise_logs_v6';
const String lastImportBackupKey = 'recomp_import_backup_v6';
const String lastImportBackupDateKey = 'recomp_import_backup_date_v6';

final RegExp _monthHistoryKey = RegExp(r'^recomp_history_\d{4}_\d{2}$');

enum ImportMode { merge, overwrite }

class ImportResult {
  final int importedKeys;
  final String backupJson;
  final bool migratedLegacyBackup;

  const ImportResult({
    required this.importedKeys,
    required this.backupJson,
    required this.migratedLegacyBackup,
  });
}

final _bodyWrites = Expando<Future<void>>('body writes');
Future<T> _serializeBody<T>(
  Future<T> Function() action, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final next =
      (_bodyWrites[prefs] ?? Future<void>.value()).then((_) => action());
  _bodyWrites[prefs] = next.then<void>((_) {}, onError: (Object _) {});
  return next;
}

final _exerciseLogWrites = Expando<Future<void>>('exercise log writes');
Future<T> _serializeExerciseLogs<T>(
  Future<T> Function() action, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final next =
      (_exerciseLogWrites[prefs] ?? Future<void>.value()).then((_) => action());
  _exerciseLogWrites[prefs] = next.then<void>((_) {}, onError: (Object _) {});
  return next;
}

final _importWrites = Expando<Future<void>>('import writes');
Future<T> _serializeImport<T>(
  SharedPreferences prefs,
  Future<T> Function() action,
) {
  final next =
      (_importWrites[prefs] ?? Future<void>.value()).then((_) => action());
  _importWrites[prefs] = next.then<void>((_) {}, onError: (Object _) {});
  return next;
}

Future<UserProfile> loadProfile() async {
  final preferences = await SharedPreferences.getInstance();
  final pending = _bodyWrites[preferences];
  if (pending != null) await pending;
  final raw = preferences.getString(profileKey);
  if (raw == null) return UserProfile();
  final decoded = jsonDecode(raw);
  if (decoded is! Map) throw const FormatException('个人资料格式无效');
  return UserProfile.fromJson(Map<String, dynamic>.from(decoded));
}

Future<void> saveProfile(UserProfile profile) => _serializeBody(() async {
      UserProfile.fromJson(profile.toJson());
      final preferences = await SharedPreferences.getInstance();
      await writeJson(preferences, profileKey, profile.toJson());
    });

List<WeightEntry> _readWeightHistory(SharedPreferences preferences) =>
    _decodeStringList<WeightEntry>(
      preferences.getString(weightHistoryKey),
      WeightEntry.fromJson,
    )..sort((a, b) => a.date.compareTo(b.date));

Future<List<WeightEntry>> loadWeightHistory() async {
  final preferences = await SharedPreferences.getInstance();
  final pending = _bodyWrites[preferences];
  if (pending != null) await pending;
  return _readWeightHistory(preferences);
}

Future<void> saveWeightHistory(List<WeightEntry> entries) =>
    _serializeBody(() => _writeWeightHistory(entries));

Future<void> _writeWeightHistory(List<WeightEntry> entries) async {
  final preferences = await SharedPreferences.getInstance();
  var normalized = <WeightEntry>[];
  for (final entry in entries) {
    WeightEntry.fromJson(entry.toJson());
    normalized = upsertWeightEntry(normalized, entry);
  }
  await writeJson(
    preferences,
    weightHistoryKey,
    normalized.map((entry) => entry.toJson()).toList(),
  );
}

Future<List<WeightEntry>> saveWeightEntry(WeightEntry entry) =>
    _serializeBody(() async {
      final prefs = await SharedPreferences.getInstance();
      final next = upsertWeightEntry(_readWeightHistory(prefs), entry);
      await _writeWeightHistory(next);
      return next;
    });

Future<List<WeightEntry>> deleteWeightEntry(DateTime date) =>
    _serializeBody(() async {
      final prefs = await SharedPreferences.getInstance();
      final day = dateOnly(date);
      final next = _readWeightHistory(prefs)
          .where((entry) => dateOnly(entry.date) != day)
          .toList();
      await _writeWeightHistory(next);
      return next;
    });

List<BodyMeasurement> _readMeasurements(SharedPreferences preferences) =>
    _decodeStringList<BodyMeasurement>(
      preferences.getString(measurementHistoryKey),
      BodyMeasurement.fromJson,
    )..sort((a, b) => a.date.compareTo(b.date));

Future<List<BodyMeasurement>> loadMeasurements() async {
  final preferences = await SharedPreferences.getInstance();
  final pending = _bodyWrites[preferences];
  if (pending != null) await pending;
  return _readMeasurements(preferences);
}

Future<void> saveMeasurements(List<BodyMeasurement> entries) =>
    _serializeBody(() => _writeMeasurements(entries));

Future<void> _writeMeasurements(List<BodyMeasurement> entries) async {
  final preferences = await SharedPreferences.getInstance();
  var normalized = <BodyMeasurement>[];
  for (final entry in entries) {
    BodyMeasurement.fromJson(entry.toJson());
    normalized = upsertMeasurement(normalized, entry);
  }
  await writeJson(
    preferences,
    measurementHistoryKey,
    normalized.map((entry) => entry.toJson()).toList(),
  );
}

Future<List<BodyMeasurement>> saveMeasurement(
  BodyMeasurement entry, {
  bool replaceSameDay = false,
}) =>
    _serializeBody(() async {
      final prefs = await SharedPreferences.getInstance();
      var current = _readMeasurements(prefs);
      if (replaceSameDay) {
        final day = dateOnly(entry.date);
        current =
            current.where((value) => dateOnly(value.date) != day).toList();
      }
      final next = upsertMeasurement(current, entry);
      await _writeMeasurements(next);
      return next;
    });

Future<List<BodyMeasurement>> deleteMeasurement(DateTime date) =>
    _serializeBody(() async {
      final prefs = await SharedPreferences.getInstance();
      final day = dateOnly(date);
      final next = _readMeasurements(prefs)
          .where((entry) => dateOnly(entry.date) != day)
          .toList();
      await _writeMeasurements(next);
      return next;
    });

List<ExerciseLog> _readExerciseLogs(SharedPreferences preferences) {
  final logs = _decodeExerciseLogs(preferences.getString(exerciseLogsKey));
  return logs..sort((a, b) => b.date.compareTo(a.date));
}

Future<List<ExerciseLog>> loadExerciseLogs() async {
  final preferences = await SharedPreferences.getInstance();
  final pending = _exerciseLogWrites[preferences];
  if (pending != null) await pending;
  return _readExerciseLogs(preferences);
}

Future<List<ExerciseLog>> _writeExerciseLogs(
  SharedPreferences preferences,
  List<ExerciseLog> logs,
) async {
  final unique = <String, ExerciseLog>{};
  for (final log in logs) {
    _parseExerciseLog(log.toJson());
    unique[log.identity] = log;
  }
  final sorted = unique.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  await writeJson(
    preferences,
    exerciseLogsKey,
    sorted.map((log) => log.toJson()).toList(),
  );
  return sorted;
}

Future<void> saveExerciseLogs(List<ExerciseLog> logs) =>
    _serializeExerciseLogs(() async {
      final preferences = await SharedPreferences.getInstance();
      await _writeExerciseLogs(preferences, logs);
    });

Future<List<ExerciseLog>> saveExerciseLog(
  String exerciseName,
  ExerciseLog log,
) =>
    _serializeExerciseLogs(() async {
      final preferences = await SharedPreferences.getInstance();
      final logs = _readExerciseLogs(preferences);
      final entry = ExerciseLog(
        exerciseName: exerciseName,
        date: log.date,
        weightKg: log.weightKg,
        sets: log.sets,
        reps: log.reps,
        rpe: log.rpe,
      );
      _parseExerciseLog(entry.toJson());
      logs.insert(0, entry);
      return _writeExerciseLogs(preferences, logs);
    });

Future<List<ExerciseLog>> deleteExerciseLog(ExerciseLog target) =>
    _serializeExerciseLogs(() async {
      final preferences = await SharedPreferences.getInstance();
      final logs = _readExerciseLogs(preferences);
      var removed = false;
      final next = <ExerciseLog>[];
      for (final log in logs) {
        if (!removed && log.identity == target.identity) {
          removed = true;
        } else {
          next.add(log);
        }
      }
      return _writeExerciseLogs(preferences, next);
    });

List<ExerciseLog> exerciseHistory(
  Iterable<ExerciseLog> logs,
  String exerciseName,
) =>
    logs.where((log) => log.exerciseName == exerciseName).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

ExerciseLog? exercisePersonalRecord(
  Iterable<ExerciseLog> logs,
  String exerciseName,
) {
  final history = exerciseHistory(logs, exerciseName);
  if (history.isEmpty) return null;
  return history.reduce(
    (best, log) => log.estimated1RM > best.estimated1RM ? log : best,
  );
}

Map<String, dynamic> _supportedPreferences(SharedPreferences preferences) {
  final values = <String, dynamic>{};
  for (final key in preferences.getKeys()) {
    if (!key.startsWith('recomp_') ||
        key == lastImportBackupKey ||
        key == lastImportBackupDateKey) {
      continue;
    }
    final value = preferences.get(key);
    if (value is String || value is bool || value is int || value is double) {
      values[key] = value;
    } else if (value is List<String>) {
      values[key] = value;
    }
  }
  return values;
}

String _exportPreferencesJson(SharedPreferences prefs) {
  final data = {
    'schemaVersion': currentSchemaVersion,
    'appVersion': appDataVersion,
    'exportDate': DateTime.now().toIso8601String(),
    'preferences': _supportedPreferences(prefs),
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

Future<String> exportAllData({SharedPreferences? preferences}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final pendingImport = _importWrites[prefs];
  if (pendingImport != null) await pendingImport;
  await awaitPendingWorkoutWrites(prefs);
  final pendingBody = _bodyWrites[prefs];
  if (pendingBody != null) await pendingBody;
  final pendingLogs = _exerciseLogWrites[prefs];
  if (pendingLogs != null) await pendingLogs;
  return _exportPreferencesJson(prefs);
}

/// Validates v6.7 backups and migrates the legacy v6.6 object layout in memory.
Map<String, dynamic> validateBackup(String jsonString) {
  final decoded = jsonDecode(jsonString);
  if (decoded is! Map) {
    throw const FormatException('备份根节点必须是 JSON 对象');
  }
  final raw = Map<String, dynamic>.from(decoded);
  final data = raw['preferences'] is Map ? raw : _migrateLegacyBackup(raw);
  final schema = data['schemaVersion'];
  if (schema is! int || schema < 1 || schema > currentSchemaVersion) {
    throw FormatException('不支持的 schemaVersion: $schema');
  }
  if (data['preferences'] is! Map) {
    throw const FormatException('备份缺少 preferences 数据');
  }
  final preferences = Map<String, dynamic>.from(data['preferences'] as Map);
  for (final entry in preferences.entries) {
    if (!entry.key.startsWith('recomp_') ||
        entry.key == lastImportBackupKey ||
        entry.key == lastImportBackupDateKey) {
      throw FormatException('备份包含非法字段: ${entry.key}');
    }
    final value = entry.value;
    if (value is! String &&
        value is! bool &&
        value is! int &&
        value is! double &&
        value is! List) {
      throw FormatException('字段 ${entry.key} 类型不受支持');
    }
    if (value is List && value.any((item) => item is! String)) {
      throw FormatException('字段 ${entry.key} 必须是字符串列表');
    }
  }
  _validateKnownPayloads(preferences);
  return {...data, 'preferences': preferences};
}

Map<String, dynamic> _migrateLegacyBackup(Map<String, dynamic> legacy) {
  final recognized = legacy.keys.any(
    (key) => const {
      'profile',
      'weightHistory',
      'exerciseLogs',
      'workoutDone',
      'settings',
    }.contains(key),
  );
  if (!recognized) {
    throw const FormatException('无法识别备份格式');
  }

  final preferences = <String, dynamic>{};
  if (legacy['profile'] is Map) {
    preferences[profileKey] = jsonEncode(legacy['profile']);
  }
  if (legacy['weightHistory'] is List) {
    preferences[weightHistoryKey] = jsonEncode(legacy['weightHistory']);
  }
  if (legacy['exerciseLogs'] is Map || legacy['exerciseLogs'] is List) {
    preferences[exerciseLogsKey] = jsonEncode(legacy['exerciseLogs']);
  }
  if (legacy['workoutDone'] is Map) {
    preferences['recomp_done_v6'] = jsonEncode(legacy['workoutDone']);
  }
  if (legacy['settings'] is Map) {
    final settings = Map<String, dynamic>.from(legacy['settings'] as Map);
    if (settings['themeIndex'] is int) {
      preferences['recomp_theme_v6'] = settings['themeIndex'];
    }
    if (settings['week'] is int) {
      preferences['recomp_done_v6_week'] = settings['week'];
    }
    if (settings['year'] is int) {
      preferences['recomp_done_v6_year'] = settings['year'];
    }
  }
  return {
    'schemaVersion': 1,
    'appVersion': legacy['version']?.toString() ?? '6.6.x',
    'exportDate': legacy['exportDate']?.toString(),
    'migratedLegacyBackup': true,
    'preferences': preferences,
  };
}

void _validateKnownPayloads(Map<String, dynamic> preferences) {
  try {
    String? requireString(String key) {
      if (!preferences.containsKey(key)) return null;
      final value = preferences[key];
      if (value is! String) throw FormatException('$key 必须是字符串');
      return value;
    }

    decodeDailyWorkouts(requireString(dailyWorkoutsKey));
    decodeWorkoutTemplates(requireString(workoutTemplatesKey));
    decodeWeeklySchedule(requireString(weeklyScheduleKey));
    decodeExerciseLibrary(requireString(exerciseLibraryKey));
    decodeMeals(requireString(mealsKey));

    final theme = preferences['recomp_theme_v6'];
    if (theme != null && (theme is! int || theme < 0)) {
      throw const FormatException('主题设置格式无效');
    }

    final autoRest = preferences[autoRestTimerKey];
    if (autoRest != null && autoRest is! bool) {
      throw const FormatException('自动休息计时设置格式无效');
    }

    final doneRaw = requireString('recomp_done_v6');
    if (doneRaw != null && jsonDecode(doneRaw) is! Map) {
      throw const FormatException('旧版训练进度格式无效');
    }

    final doneWeek = preferences['recomp_done_v6_week'];
    if (doneWeek != null &&
        (doneWeek is! int || doneWeek < 1 || doneWeek > 53)) {
      throw const FormatException('旧版训练周数格式无效');
    }

    final doneYear = preferences['recomp_done_v6_year'];
    if (doneYear != null &&
        (doneYear is! int || doneYear < 1970 || doneYear > 9999)) {
      throw const FormatException('旧版训练年份格式无效');
    }

    final planRaw = requireString(workoutPlanKey);
    if (planRaw != null && jsonDecode(planRaw) is! List) {
      throw const FormatException('旧版训练计划格式无效');
    }

    final profileRaw = requireString(profileKey);
    if (profileRaw != null) {
      final decodedProfile = jsonDecode(profileRaw);
      if (decodedProfile is! Map) {
        throw const FormatException('个人资料格式无效');
      }
      UserProfile.fromJson(Map<String, dynamic>.from(decodedProfile));
    }

    _decodeStringList<WeightEntry>(
      requireString(weightHistoryKey),
      WeightEntry.fromJson,
    );
    _decodeStringList<BodyMeasurement>(
      requireString(measurementHistoryKey),
      BodyMeasurement.fromJson,
    );
    _decodeExerciseLogs(requireString(exerciseLogsKey));

    for (final entry in preferences.entries) {
      if (_monthHistoryKey.hasMatch(entry.key)) {
        if (entry.value is! String) {
          throw FormatException('${entry.key} 必须是字符串');
        }
        final history = jsonDecode(entry.value as String);
        if (history is! Map) throw const FormatException('月度历史格式无效');
        for (final item in history.entries) {
          final count = item.value;
          if (int.tryParse(item.key.toString()) == null ||
              count is! num ||
              !count.isFinite) {
            throw const FormatException('月度历史条目无效');
          }
        }
      }
    }
  } catch (error) {
    throw FormatException('备份数据内容无效: $error');
  }
}

Future<ImportResult> importAllData(
  String jsonString, {
  ImportMode mode = ImportMode.merge,
  SharedPreferences? preferences,
  bool savePreImportBackup = true,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final data = validateBackup(jsonString);
  return _serializeImport(
    prefs,
    () => runSerializedWorkoutWrite(
      () => _serializeBody(
        () => _serializeExerciseLogs(
          () => _applyImport(
            prefs,
            data,
            mode: mode,
            savePreImportBackup: savePreImportBackup,
          ),
          preferences: prefs,
        ),
        preferences: prefs,
      ),
      preferences: prefs,
    ),
  );
}

Future<ImportResult> _applyImport(
  SharedPreferences prefs,
  Map<String, dynamic> data, {
  required ImportMode mode,
  required bool savePreImportBackup,
}) async {
  final incoming = Map<String, dynamic>.from(data['preferences'] as Map);
  final backup = _exportPreferencesJson(prefs);
  if (savePreImportBackup) {
    if (!await prefs.setString(lastImportBackupKey, backup) ||
        !await prefs.setString(
          lastImportBackupDateKey,
          DateTime.now().toIso8601String(),
        )) {
      throw StateError('导入前快照保存失败，请重试');
    }
  }

  if (mode == ImportMode.overwrite) {
    final keysToRemove = prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith('recomp_') &&
              key != lastImportBackupKey &&
              key != lastImportBackupDateKey,
        )
        .toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  for (final entry in incoming.entries) {
    final key = entry.key;
    final value = entry.value;
    if (mode == ImportMode.merge && key == dailyWorkoutsKey) {
      final merged = mergeDailyWorkouts(prefs.getString(key), value as String);
      if (!await prefs.setString(key, merged)) {
        throw StateError('保存失败，请重试');
      }
    } else if (mode == ImportMode.merge && key == mealsKey) {
      final meals = {
        ...decodeMeals(prefs.getString(key)),
        ...decodeMeals(value as String)
      };
      await writeJson(
          prefs, key, {for (final e in meals.entries) e.key: e.value.toJson()});
    } else if (mode == ImportMode.merge && key == workoutTemplatesKey) {
      final templates = {
        for (final t in decodeWorkoutTemplates(prefs.getString(key))) t.id: t,
        for (final t in decodeWorkoutTemplates(value as String)) t.id: t,
      };
      await writeJson(
          prefs, key, templates.values.map((t) => t.toJson()).toList());
    } else if (mode == ImportMode.merge && key == exerciseLibraryKey) {
      final merged =
          mergeExerciseLibrary(prefs.getString(key), value as String);
      if (!await prefs.setString(key, merged)) {
        throw StateError('保存失败，请重试');
      }
    } else if (mode == ImportMode.merge && key == weightHistoryKey) {
      await _mergeWeightHistory(prefs, value);
    } else if (mode == ImportMode.merge && key == measurementHistoryKey) {
      await _mergeMeasurements(prefs, value);
    } else if (mode == ImportMode.merge && key == exerciseLogsKey) {
      await _mergeExerciseLogs(prefs, value);
    } else if (mode == ImportMode.merge && _monthHistoryKey.hasMatch(key)) {
      await _mergeMonthHistory(prefs, key, value);
    } else if (mode == ImportMode.merge && key == 'recomp_done_v6') {
      await _mergeWorkoutDone(prefs, value);
    } else {
      await _writeValue(prefs, key, value);
    }
  }

  // When merging a legacy v6.6 backup into an installation that already has
  // dated daily workouts, fold the legacy week into dailyWorkoutsKey without
  // overwriting existing sessions.
  if (mode == ImportMode.merge &&
      !incoming.containsKey(dailyWorkoutsKey) &&
      incoming.containsKey('recomp_done_v6') &&
      prefs.containsKey(dailyWorkoutsKey)) {
    final legacyYear = (incoming['recomp_done_v6_year'] as int?) ??
        prefs.getInt('recomp_done_v6_year');
    final legacyWeek = (incoming['recomp_done_v6_week'] as int?) ??
        prefs.getInt('recomp_done_v6_week');
    final migrated = await migrateLegacyDoneToDailyWorkouts(
      prefs,
      year: legacyYear,
      week: legacyWeek,
      rawDone: incoming['recomp_done_v6'] as String?,
    );
    if (migrated.isNotEmpty) {
      final incomingDailyRaw = jsonEncode({
        for (final e in migrated.entries) e.key: e.value.toJson(),
      });
      final mergedDaily = mergeDailyWorkouts(
        prefs.getString(dailyWorkoutsKey),
        incomingDailyRaw,
      );
      if (!await prefs.setString(dailyWorkoutsKey, mergedDaily)) {
        throw StateError('保存失败，请重试');
      }
    }
  }

  return ImportResult(
    importedKeys: incoming.length,
    backupJson: backup,
    migratedLegacyBackup: data['migratedLegacyBackup'] == true,
  );
}

Future<bool> hasLastImportBackup({SharedPreferences? preferences}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  return prefs.getString(lastImportBackupKey) != null;
}

Future<ImportResult?> restoreLastImportBackup({
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final backup = prefs.getString(lastImportBackupKey);
  if (backup == null) return null;
  return importAllData(
    backup,
    mode: ImportMode.overwrite,
    preferences: prefs,
    savePreImportBackup: false,
  );
}

Future<void> _mergeWeightHistory(
  SharedPreferences preferences,
  dynamic incomingRaw,
) async {
  final current = _decodeStringList<WeightEntry>(
    preferences.getString(weightHistoryKey),
    WeightEntry.fromJson,
  );
  final incoming = _decodeStringList<WeightEntry>(
    incomingRaw as String?,
    WeightEntry.fromJson,
  );
  var merged = current;
  for (final entry in incoming) {
    merged = upsertWeightEntry(merged, entry);
  }
  await writeJson(
    preferences,
    weightHistoryKey,
    merged.map((entry) => entry.toJson()).toList(),
  );
}

Future<void> _mergeMeasurements(
  SharedPreferences preferences,
  dynamic incomingRaw,
) async {
  final current = _decodeStringList<BodyMeasurement>(
    preferences.getString(measurementHistoryKey),
    BodyMeasurement.fromJson,
  );
  final incoming = _decodeStringList<BodyMeasurement>(
    incomingRaw as String?,
    BodyMeasurement.fromJson,
  );
  var merged = current;
  for (final entry in incoming) {
    merged = upsertMeasurement(merged, entry);
  }
  await writeJson(
    preferences,
    measurementHistoryKey,
    merged.map((entry) => entry.toJson()).toList(),
  );
}

Future<void> _mergeExerciseLogs(
  SharedPreferences preferences,
  dynamic incomingRaw,
) async {
  final current = _decodeExerciseLogs(preferences.getString(exerciseLogsKey));
  final incoming = _decodeExerciseLogs(incomingRaw as String?);
  await _writeExerciseLogs(preferences, [...current, ...incoming]);
}

Future<void> _mergeMonthHistory(
  SharedPreferences preferences,
  String key,
  dynamic incomingRaw,
) async {
  final current = _decodeJsonMap(preferences.getString(key));
  final incoming = _decodeJsonMap(incomingRaw as String?);
  await writeJson(preferences, key, {...current, ...incoming});
}

Future<void> _mergeWorkoutDone(
  SharedPreferences preferences,
  dynamic incomingRaw,
) async {
  final current = _decodeJsonMap(preferences.getString('recomp_done_v6'));
  final incoming = _decodeJsonMap(incomingRaw as String?);
  await writeJson(preferences, 'recomp_done_v6', {...current, ...incoming});
}

Map<String, dynamic> _decodeJsonMap(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) throw const FormatException('数据必须是 JSON 对象');
  return Map<String, dynamic>.from(decoded);
}

List<T> _decodeStringList<T>(
  String? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw == null || raw.isEmpty) return [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) throw const FormatException('数据必须是 JSON 数组');
  return decoded.map((item) {
    if (item is! Map) throw const FormatException('列表条目必须是 JSON 对象');
    return fromJson(Map<String, dynamic>.from(item));
  }).toList();
}

ExerciseLog _parseExerciseLog(Map<String, dynamic> json) {
  final name = json['e'];
  if (name is! String || name.trim().isEmpty) {
    throw const FormatException('负重记录动作名称无效');
  }
  final rawDate = json['d'];
  if (rawDate != null &&
      (rawDate is! String || DateTime.tryParse(rawDate) == null)) {
    throw const FormatException('负重记录日期无效');
  }
  for (final key in const ['w', 's', 'r', 'rpe']) {
    final value = json[key];
    if (value != null &&
        (value is! num || !value.toDouble().isFinite || value < 0)) {
      throw const FormatException('负重记录数值无效');
    }
  }
  return ExerciseLog.fromJson(json);
}

List<ExerciseLog> _decodeExerciseLogs(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  final decoded = jsonDecode(raw);
  if (decoded is List) {
    return decoded.map((item) {
      if (item is! Map) throw const FormatException('负重记录条目无效');
      return _parseExerciseLog(Map<String, dynamic>.from(item));
    }).toList();
  }
  if (decoded is Map) {
    return decoded.entries.map((entry) {
      if (entry.value is! Map) throw const FormatException('负重记录条目无效');
      final json = Map<String, dynamic>.from(entry.value as Map);
      json['e'] ??= entry.key.toString();
      return _parseExerciseLog(json);
    }).toList();
  }
  throw const FormatException('负重记录格式无效');
}

Future<void> _writeValue(
  SharedPreferences preferences,
  String key,
  dynamic value,
) async {
  final bool ok;
  if (value is String) {
    ok = await preferences.setString(key, value);
  } else if (value is bool) {
    ok = await preferences.setBool(key, value);
  } else if (value is int) {
    ok = await preferences.setInt(key, value);
  } else if (value is double) {
    ok = await preferences.setDouble(key, value);
  } else if (value is List) {
    ok = await preferences.setStringList(key, value.cast<String>());
  } else {
    throw FormatException('字段 $key 类型不受支持');
  }
  if (!ok) {
    throw StateError('保存失败，请重试');
  }
}
