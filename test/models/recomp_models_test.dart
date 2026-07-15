import 'package:body_recomp/models/recomp_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('calculates BMI and survives JSON round-trip', () {
      final profile = UserProfile(
        birthday: '2000-01-01',
        heightCm: 180,
        weightKg: 81,
        gender: 'male',
      );

      expect(profile.bmi, closeTo(25, 0.001));
      final decoded = UserProfile.fromJson(profile.toJson());
      expect(decoded.birthday, '2000-01-01');
      expect(decoded.heightCm, 180);
      expect(decoded.weightKg, 81);
      expect(decoded.gender, 'male');
    });

    test('returns zero age for invalid or future birthday', () {
      expect(UserProfile(birthday: 'not-a-date').age, 0);
      expect(UserProfile(birthday: '2999-01-01').age, 0);
    });
  });

  group('dated body data', () {
    test('weight upsert replaces the same day and sorts by date', () {
      final result = upsertWeightEntry([
        WeightEntry(date: DateTime(2026, 7, 16), weightKg: 72),
        WeightEntry(date: DateTime(2026, 7, 14), weightKg: 73),
      ], WeightEntry(date: DateTime(2026, 7, 14, 22), weightKg: 72.5));

      expect(result, hasLength(2));
      expect(result.first.date, DateTime(2026, 7, 14));
      expect(result.first.weightKg, 72.5);
      expect(result.last.date, DateTime(2026, 7, 16));
    });

    test('measurement upsert merges values recorded on the same day', () {
      final result = upsertMeasurement(
        [
          BodyMeasurement(
            date: DateTime(2026, 7, 15),
            values: const {'waist': 80, 'chest': 96},
          ),
        ],
        BodyMeasurement(
          date: DateTime(2026, 7, 15, 18),
          values: const {'waist': 79.5, 'arm': 35},
        ),
      );

      expect(result, hasLength(1));
      expect(result.single.values, {'waist': 79.5, 'chest': 96.0, 'arm': 35.0});
    });
  });

  test('ExerciseLog calculates Epley 1RM and round-trips JSON', () {
    final log = ExerciseLog(
      exerciseName: '卧推',
      date: DateTime.utc(2026, 7, 15, 12),
      weightKg: 100,
      sets: 3,
      reps: 5,
      rpe: 8.5,
    );

    expect(log.estimated1RM, closeTo(116.667, 0.001));
    final decoded = ExerciseLog.fromJson(log.toJson());
    expect(decoded.exerciseName, '卧推');
    expect(decoded.date, DateTime.utc(2026, 7, 15, 12));
    expect(decoded.rpe, 8.5);
    expect(decoded.identity, log.identity);
  });
}
