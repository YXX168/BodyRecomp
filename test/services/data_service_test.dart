import 'dart:convert';

import 'package:body_recomp/models/recomp_models.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('profile and body data CRUD use mocked SharedPreferences', () async {
    final profile = UserProfile(
      birthday: '1995-05-20',
      heightCm: 175,
      weightKg: 70,
      gender: 'female',
    );
    await saveProfile(profile);
    await saveWeightEntry(
      WeightEntry(date: DateTime(2026, 7, 15), weightKg: 70),
    );
    await saveWeightEntry(
      WeightEntry(date: DateTime(2026, 7, 15, 20), weightKg: 69.5),
    );
    await saveMeasurement(
      BodyMeasurement(date: DateTime(2026, 7, 15), values: const {'waist': 75}),
    );

    expect((await loadProfile()).gender, 'female');
    expect((await loadWeightHistory()).single.weightKg, 69.5);
    expect((await loadMeasurements()).single.values['waist'], 75);

    expect(await deleteWeightEntry(DateTime(2026, 7, 15)), isEmpty);
    expect(await deleteMeasurement(DateTime(2026, 7, 15)), isEmpty);
  });

  test(
    'exercise history is newest first and finds the best estimated 1RM',
    () async {
      final older = ExerciseLog(
        exerciseName: '卧推',
        date: DateTime(2026, 7, 1),
        weightKg: 100,
        sets: 3,
        reps: 5,
        rpe: 8,
      );
      final newer = ExerciseLog(
        exerciseName: '卧推',
        date: DateTime(2026, 7, 15),
        weightKg: 95,
        sets: 3,
        reps: 8,
        rpe: 9,
      );

      await saveExerciseLog('卧推', older);
      await saveExerciseLog('卧推', newer);

      final logs = await loadExerciseLogs();
      expect(logs.map((log) => log.date), [newer.date, older.date]);
      expect(exerciseHistory(logs, '卧推').first.date, newer.date);
      expect(exercisePersonalRecord(logs, '卧推')?.date, newer.date);
    },
  );

  test(
    'export and merge import preserve local data and create a backup',
    () async {
      SharedPreferences.setMockInitialValues({
        weightHistoryKey: jsonEncode([
          {'d': '2026-07-14', 'w': 72.0},
        ]),
        'recomp_done_v6': jsonEncode({'0_0': true}),
        'unrelated': 'must not export',
      });
      final preferences = await SharedPreferences.getInstance();
      final incoming = jsonEncode({
        'schemaVersion': currentSchemaVersion,
        'appVersion': appDataVersion,
        'preferences': {
          weightHistoryKey: jsonEncode([
            {'d': '2026-07-15', 'w': 71.5},
          ]),
          'recomp_done_v6': jsonEncode({'2_0': true}),
        },
      });

      final result = await importAllData(incoming, preferences: preferences);

      expect(result.importedKeys, 2);
      expect(preferences.getString(lastImportBackupKey), isNotEmpty);
      final weights = (jsonDecode(preferences.getString(weightHistoryKey)!)
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(weights, hasLength(2));
      expect(jsonDecode(preferences.getString('recomp_done_v6')!), {
        '0_0': true,
        '2_0': true,
      });

      final exported = jsonDecode(await exportAllData(preferences: preferences))
          as Map<String, dynamic>;
      final exportedPreferences =
          exported['preferences'] as Map<String, dynamic>;
      expect(exportedPreferences, isNot(contains('unrelated')));
    },
  );

  test(
    'overwrite import removes previous recomp data but keeps backup',
    () async {
      SharedPreferences.setMockInitialValues({
        profileKey: jsonEncode({'weightKg': 88}),
        measurementHistoryKey: jsonEncode([
          {
            'd': '2026-07-10',
            'v': {'waist': 90},
          },
        ]),
      });
      final preferences = await SharedPreferences.getInstance();
      final incoming = jsonEncode({
        'schemaVersion': currentSchemaVersion,
        'appVersion': appDataVersion,
        'preferences': {
          profileKey: jsonEncode({'weightKg': 70}),
        },
      });

      await importAllData(
        incoming,
        mode: ImportMode.overwrite,
        preferences: preferences,
      );

      expect(preferences.containsKey(measurementHistoryKey), isFalse);
      expect(preferences.getString(lastImportBackupKey), isNotEmpty);
      expect(jsonDecode(preferences.getString(profileKey)!)['weightKg'], 70);
    },
  );

  test('legacy backup is validated and migrated', () {
    final migrated = validateBackup(
      jsonEncode({
        'version': '6.6.1',
        'profile': {'heightCm': 180, 'weightKg': 80},
        'weightHistory': [
          {'d': '2026-07-01', 'w': 80},
        ],
        'workoutDone': {'0_0': true},
        'settings': {'themeIndex': 2, 'week': 29, 'year': 2026},
      }),
    );

    expect(migrated['migratedLegacyBackup'], isTrue);
    expect(
      migrated['preferences'] as Map<String, dynamic>,
      contains(profileKey),
    );
  });

  test('validation rejects unsupported keys and future schemas', () {
    expect(
      () => validateBackup(
        jsonEncode({
          'schemaVersion': currentSchemaVersion + 1,
          'preferences': <String, dynamic>{},
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => validateBackup(
        jsonEncode({
          'schemaVersion': currentSchemaVersion,
          'preferences': {'other_app_key': 'value'},
        }),
      ),
      throwsFormatException,
    );
  });
}
