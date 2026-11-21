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

  test('concurrent body entries retain every day and same-day field', () async {
    await Future.wait([
      saveWeightEntry(WeightEntry(date: DateTime(2026, 11, 10), weightKg: 72)),
      saveWeightEntry(
          WeightEntry(date: DateTime(2026, 11, 11), weightKg: 71.8)),
      saveMeasurement(BodyMeasurement(
          date: DateTime(2026, 11, 11), values: const {'waist': 80})),
      saveMeasurement(BodyMeasurement(
          date: DateTime(2026, 11, 11), values: const {'arm': 32})),
    ]);
    expect((await loadWeightHistory()).map((e) => e.weightKg), [72, 71.8]);
    expect((await loadMeasurements()).single.values, {'waist': 80, 'arm': 32});
  });

  test('invalid body values and damaged history cannot overwrite records',
      () async {
    await saveProfile(UserProfile());
    final prefs = await SharedPreferences.getInstance();
    final before = prefs.getString(profileKey);
    await expectLater(
        saveProfile(UserProfile(heightCm: 0)), throwsFormatException);
    expect(prefs.getString(profileKey), before);
    await expectLater(
        saveWeightEntry(
            WeightEntry(date: DateTime(2026), weightKg: double.infinity)),
        throwsFormatException);
    await prefs.setString(weightHistoryKey, '[damaged');
    await expectLater(loadWeightHistory(), throwsFormatException);
    await expectLater(
        saveWeightEntry(WeightEntry(date: DateTime(2026), weightKg: 70)),
        throwsFormatException);
    expect(prefs.getString(weightHistoryKey), '[damaged');
    expect(await exportAllData(), contains('[damaged'));
  });

  test('invalid nested backup is rejected before any local data changes',
      () async {
    await saveProfile(UserProfile(weightKg: 70));
    final prefs = await SharedPreferences.getInstance();
    for (final value in [
      'not json',
      '[{"d":"2026-02-31","w":72}]',
      '[{"d":"2026-11-10","w":-2}]'
    ]) {
      final backup = jsonEncode({
        'schemaVersion': 3,
        'preferences': {weightHistoryKey: value}
      });
      await expectLater(importAllData(backup, mode: ImportMode.overwrite),
          throwsFormatException);
      expect((await loadProfile()).weightKg, 70);
      expect(prefs.containsKey(lastImportBackupKey), isFalse);
    }
  });

  test('strict payload validation rejects wrong-typed keys and corrupt logs',
      () async {
    final invalidCases = <Map<String, dynamic>>[
      {'recomp_auto_rest_timer_v2': 'yes'},
      {
        'recomp_schedule_v1': jsonEncode([1, 2, 3, 4, 5, 6, 7])
      },
      {'recomp_theme_v6': -1},
      {'recomp_theme_v6': 'blue'},
      {'recomp_done_v6_week': 54},
      {'recomp_done_v6_year': 1900},
      {'recomp_done_v6': '[]'},
      {exerciseLogsKey: '[corrupt json'},
      {
        exerciseLogsKey: jsonEncode([
          {'e': '卧推', 'd': 'bad-date', 'w': -10, 's': 3, 'r': 5},
        ]),
      },
    ];

    for (final prefsMap in invalidCases) {
      final backup = jsonEncode({
        'schemaVersion': currentSchemaVersion,
        'preferences': prefsMap,
      });
      expect(
        () => validateBackup(backup),
        throwsFormatException,
        reason: 'expected FormatException for $prefsMap',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(exerciseLogsKey, '{broken-logs');
    await expectLater(loadExerciseLogs(), throwsFormatException);
  });

  test('restoreLastImportBackup restores prior snapshot and keeps backup key',
      () async {
    await saveProfile(UserProfile(weightKg: 71.5));
    await saveWeightEntry(
      WeightEntry(date: DateTime(2026, 11, 10), weightKg: 71.5),
    );
    final prefs = await SharedPreferences.getInstance();

    final incoming = jsonEncode({
      'schemaVersion': currentSchemaVersion,
      'preferences': {
        profileKey: jsonEncode({'weightKg': 88.0}),
      },
    });
    await importAllData(
      incoming,
      mode: ImportMode.overwrite,
      preferences: prefs,
    );
    final savedBackup = prefs.getString(lastImportBackupKey);
    expect(savedBackup, isNotNull);
    expect((await loadProfile()).weightKg, 88.0);
    expect(await loadWeightHistory(), isEmpty);

    final restored = await restoreLastImportBackup(preferences: prefs);
    expect(restored, isNotNull);
    expect((await loadProfile()).weightKg, 71.5);
    expect((await loadWeightHistory()).single.weightKg, 71.5);
    // Restoring does not overwrite the saved pre-import snapshot.
    expect(prefs.getString(lastImportBackupKey), savedBackup);
  });

  test('legacy merge folds recomp_done_v6 into existing daily workouts',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'recomp_daily_workouts_v1',
      jsonEncode({
        '2026-11-15': {
          'date': '2026-11-15',
          'blocks': [
            {
              'id': 'keep',
              'exercise': {
                'name': '平板卧推',
                'muscles': ['胸'],
                'muscleTarget': '胸',
                'sets': 4,
                'reps': '8-10',
                'rest': '90s',
              },
              'completedSets': 2,
            }
          ],
          'rested': false,
        }
      }),
    );

    final legacyBackup = jsonEncode({
      'version': '6.6.1',
      'workoutDone': {'1_0': true},
      'settings': {'week': 46, 'year': 2026},
    });
    await importAllData(
      legacyBackup,
      mode: ImportMode.merge,
      preferences: prefs,
    );

    final decoded =
        jsonDecode(prefs.getString('recomp_daily_workouts_v1')!) as Map;
    expect(decoded.keys, containsAll(['2026-11-15', '2026-11-10']));
  });
}
