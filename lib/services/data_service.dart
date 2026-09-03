import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recomp_models.dart';

const int currentSchemaVersion = 2;
const String appDataVersion = '6.10.0';
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

Future<UserProfile> loadProfile() async {
  final preferences = await SharedPreferences.getInstance();
  final raw = preferences.getString(profileKey);
  if (raw == null) return UserProfile();
  try {
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return UserProfile();
  }
}

Future<void> saveProfile(UserProfile profile) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(profileKey, jsonEncode(profile.toJson()));
}

Future<List<WeightEntry>> loadWeightHistory() async {
  final preferences = await SharedPreferences.getInstance();
  return _decodeStringList<WeightEntry>(
    preferences.getString(weightHistoryKey),
    WeightEntry.fromJson,
  )..sort((a, b) => a.date.compareTo(b.date));
}

Future<void> saveWeightHistory(List<WeightEntry> entries) async {
  final preferences = await SharedPreferences.getInstance();
  var normalized = <WeightEntry>[];
  for (final entry in entries) {
    normalized = upsertWeightEntry(normalized, entry);
  }
  await preferences.setString(
    weightHistoryKey,
    jsonEncode(normalized.map((entry) => entry.toJson()).toList()),
  );
}

Future<List<WeightEntry>> saveWeightEntry(WeightEntry entry) async {
  final next = upsertWeightEntry(await loadWeightHistory(), entry);
  await saveWeightHistory(next);
  return next;
}

Future<List<WeightEntry>> deleteWeightEntry(DateTime date) async {
  final day = dateOnly(date);
  final next = (await loadWeightHistory())
      .where((entry) => dateOnly(entry.date) != day)
      .toList();
  await saveWeightHistory(next);
  return next;
}

Future<List<BodyMeasurement>> loadMeasurements() async {
  final preferences = await SharedPreferences.getInstance();
  return _decodeStringList<BodyMeasurement>(
    preferences.getString(measurementHistoryKey),
    BodyMeasurement.fromJson,
  )..sort((a, b) => a.date.compareTo(b.date));
}

Future<void> saveMeasurements(List<BodyMeasurement> entries) async {
  final preferences = await SharedPreferences.getInstance();
  var normalized = <BodyMeasurement>[];
  for (final entry in entries) {
    normalized = upsertMeasurement(normalized, entry);
  }
  await preferences.setString(
    measurementHistoryKey,
    jsonEncode(normalized.map((entry) => entry.toJson()).toList()),
  );
}

Future<List<BodyMeasurement>> saveMeasurement(
  BodyMeasurement entry, {
  bool replaceSameDay = false,
}) async {
  var current = await loadMeasurements();
  if (replaceSameDay) {
    final day = dateOnly(entry.date);
    current = current.where((value) => dateOnly(value.date) != day).toList();
  }
  final next = upsertMeasurement(current, entry);
  await saveMeasurements(next);
  return next;
}

Future<List<BodyMeasurement>> deleteMeasurement(DateTime date) async {
  final day = dateOnly(date);
  final next = (await loadMeasurements())
      .where((entry) => dateOnly(entry.date) != day)
      .toList();
  await saveMeasurements(next);
  return next;
}

Future<List<ExerciseLog>> loadExerciseLogs() async {
  final preferences = await SharedPreferences.getInstance();
  final logs = _decodeExerciseLogs(preferences.getString(exerciseLogsKey));
  return logs..sort((a, b) => b.date.compareTo(a.date));
}

Future<void> saveExerciseLogs(List<ExerciseLog> logs) async {
  final preferences = await SharedPreferences.getInstance();
  final unique = <String, ExerciseLog>{
    for (final log in logs) log.identity: log,
  };
  final sorted = unique.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  await preferences.setString(
    exerciseLogsKey,
    jsonEncode(sorted.map((log) => log.toJson()).toList()),
  );
}

Future<List<ExerciseLog>> saveExerciseLog(
  String exerciseName,
  ExerciseLog log,
) async {
  final logs = await loadExerciseLogs();
  logs.insert(
    0,
    ExerciseLog(
      exerciseName: exerciseName,
      date: log.date,
      weightKg: log.weightKg,
      sets: log.sets,
      reps: log.reps,
      rpe: log.rpe,
    ),
  );
  await saveExerciseLogs(logs);
  return loadExerciseLogs();
}

Future<List<ExerciseLog>> deleteExerciseLog(ExerciseLog target) async {
  final logs = await loadExerciseLogs();
  var removed = false;
  final next = <ExerciseLog>[];
  for (final log in logs) {
    if (!removed && log.identity == target.identity) {
      removed = true;
    } else {
      next.add(log);
    }
  }
  await saveExerciseLogs(next);
  return next;
}

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

Future<String> exportAllData({SharedPreferences? preferences}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final data = {
    'schemaVersion': currentSchemaVersion,
    'appVersion': appDataVersion,
    'exportDate': DateTime.now().toIso8601String(),
    'preferences': _supportedPreferences(prefs),
  };
  return const JsonEncoder.withIndent('  ').convert(data);
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
    final profile = preferences[profileKey];
    if (profile != null) {
      UserProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(profile as String) as Map),
      );
    }
    _decodeStringList<WeightEntry>(
      preferences[weightHistoryKey] as String?,
      WeightEntry.fromJson,
    );
    _decodeStringList<BodyMeasurement>(
      preferences[measurementHistoryKey] as String?,
      BodyMeasurement.fromJson,
    );
    _decodeExerciseLogs(preferences[exerciseLogsKey] as String?);
    for (final entry in preferences.entries) {
      if (_monthHistoryKey.hasMatch(entry.key)) {
        final history = jsonDecode(entry.value as String);
        if (history is! Map) throw const FormatException();
        for (final item in history.entries) {
          if (int.tryParse(item.key.toString()) == null || item.value is! num) {
            throw const FormatException();
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
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final data = validateBackup(jsonString);
  final incoming = Map<String, dynamic>.from(data['preferences'] as Map);
  final backup = await exportAllData(preferences: prefs);
  await prefs.setString(lastImportBackupKey, backup);
  await prefs.setString(
    lastImportBackupDateKey,
    DateTime.now().toIso8601String(),
  );

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
    if (mode == ImportMode.merge && key == weightHistoryKey) {
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
  return importAllData(backup, mode: ImportMode.overwrite, preferences: prefs);
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
  await preferences.setString(
    weightHistoryKey,
    jsonEncode(merged.map((entry) => entry.toJson()).toList()),
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
  await preferences.setString(
    measurementHistoryKey,
    jsonEncode(merged.map((entry) => entry.toJson()).toList()),
  );
}

Future<void> _mergeExerciseLogs(
  SharedPreferences preferences,
  dynamic incomingRaw,
) async {
  final current = _decodeExerciseLogs(preferences.getString(exerciseLogsKey));
  final incoming = _decodeExerciseLogs(incomingRaw as String?);
  final unique = <String, ExerciseLog>{
    for (final log in [...current, ...incoming]) log.identity: log,
  };
  final sorted = unique.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  await preferences.setString(
    exerciseLogsKey,
    jsonEncode(sorted.map((log) => log.toJson()).toList()),
  );
}

Future<void> _mergeMonthHistory(
  SharedPreferences preferences,
  String key,
  dynamic incomingRaw,
) async {
  final current = _decodeJsonMap(preferences.getString(key));
  final incoming = _decodeJsonMap(incomingRaw as String?);
  await preferences.setString(key, jsonEncode({...current, ...incoming}));
}

Future<void> _mergeWorkoutDone(
  SharedPreferences preferences,
  dynamic incomingRaw,
) async {
  final current = _decodeJsonMap(preferences.getString('recomp_done_v6'));
  final incoming = _decodeJsonMap(incomingRaw as String?);
  await preferences.setString(
    'recomp_done_v6',
    jsonEncode({...current, ...incoming}),
  );
}

Map<String, dynamic> _decodeJsonMap(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  return Map<String, dynamic>.from(jsonDecode(raw) as Map);
}

List<T> _decodeStringList<T>(
  String? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  } catch (_) {
    return [];
  }
}

List<ExerciseLog> _decodeExerciseLogs(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map(
            (item) =>
                ExerciseLog.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
    if (decoded is Map) {
      return decoded.entries.map((entry) {
        final json = Map<String, dynamic>.from(entry.value as Map);
        json['e'] ??= entry.key;
        return ExerciseLog.fromJson(json);
      }).toList();
    }
  } catch (_) {}
  return [];
}

Future<void> _writeValue(
  SharedPreferences preferences,
  String key,
  dynamic value,
) async {
  if (value is String) {
    await preferences.setString(key, value);
  } else if (value is bool) {
    await preferences.setBool(key, value);
  } else if (value is int) {
    await preferences.setInt(key, value);
  } else if (value is double) {
    await preferences.setDouble(key, value);
  } else if (value is List) {
    await preferences.setStringList(key, value.cast<String>());
  } else {
    throw FormatException('字段 $key 类型不受支持');
  }
}
