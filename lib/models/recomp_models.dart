class UserProfile {
  String birthday;
  double heightCm;
  double weightKg;
  String gender;

  UserProfile({
    this.birthday = '',
    this.heightCm = 176.0,
    this.weightKg = 72.5,
    this.gender = 'male',
  });

  int get age {
    if (birthday.isEmpty) return 0;
    try {
      final birthDate = DateTime.parse(birthday);
      final now = DateTime.now();
      var result = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        result--;
      }
      return result < 0 ? 0 : result;
    } catch (_) {
      return 0;
    }
  }

  double get bmi =>
      heightCm > 0 ? weightKg / ((heightCm / 100) * (heightCm / 100)) : 0;

  Map<String, dynamic> toJson() => {
        'birthday': birthday,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'gender': gender,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        birthday: json['birthday'] as String? ?? '',
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 176.0,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 72.5,
        gender: json['gender'] as String? ?? 'male',
      );
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class WeightEntry {
  final DateTime date;
  final double weightKg;

  const WeightEntry({required this.date, required this.weightKg});

  Map<String, dynamic> toJson() => {
        'd': dateOnly(date).toIso8601String().substring(0, 10),
        'w': weightKg,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        date: DateTime.parse(json['d'] as String),
        weightKg: (json['w'] as num).toDouble(),
      );
}

List<WeightEntry> upsertWeightEntry(
  Iterable<WeightEntry> entries,
  WeightEntry entry,
) {
  final byDate = <DateTime, WeightEntry>{
    for (final value in entries) dateOnly(value.date): value,
  };
  byDate[dateOnly(entry.date)] = WeightEntry(
    date: dateOnly(entry.date),
    weightKg: entry.weightKg,
  );
  return byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

class BodyMeasurement {
  final DateTime date;
  final Map<String, double> values;

  const BodyMeasurement({required this.date, required this.values});

  Map<String, dynamic> toJson() => {
        'd': dateOnly(date).toIso8601String().substring(0, 10),
        'v': values,
      };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        date: DateTime.parse(json['d'] as String),
        values: (json['v'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      );
}

List<BodyMeasurement> upsertMeasurement(
  Iterable<BodyMeasurement> entries,
  BodyMeasurement entry,
) {
  final byDate = <DateTime, BodyMeasurement>{
    for (final value in entries) dateOnly(value.date): value,
  };
  final day = dateOnly(entry.date);
  final existing = byDate[day];
  byDate[day] = BodyMeasurement(
    date: day,
    values: {...?existing?.values, ...entry.values},
  );
  return byDate.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

class ExerciseLog {
  final String exerciseName;
  final DateTime date;
  final double weightKg;
  final int sets;
  final int reps;
  final double rpe;

  ExerciseLog({
    required this.exerciseName,
    DateTime? date,
    this.weightKg = 0,
    this.sets = 0,
    this.reps = 0,
    this.rpe = 0,
  }) : date = date ?? DateTime.now();

  double get estimated1RM =>
      weightKg > 0 && reps > 0 ? weightKg * (1 + reps / 30.0) : 0;

  String get identity =>
      '${date.toIso8601String()}|$exerciseName|$weightKg|$sets|$reps|$rpe';

  Map<String, dynamic> toJson() => {
        'e': exerciseName,
        'd': date.toIso8601String(),
        'w': weightKg,
        's': sets,
        'r': reps,
        'rpe': rpe,
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
        exerciseName: json['e'] as String,
        date: DateTime.tryParse(json['d'] as String? ?? '') ?? DateTime(2000),
        weightKg: (json['w'] as num?)?.toDouble() ?? 0,
        sets: (json['s'] as num?)?.toInt() ?? 0,
        reps: (json['r'] as num?)?.toInt() ?? 0,
        rpe: (json['rpe'] as num?)?.toDouble() ?? 0,
      );
}

class Exercise {
  final String name;
  final List<String> muscles;
  final String muscleTarget;
  final int sets;
  final String reps;
  final String rest;
  final String? note;
  final bool isStar;

  const Exercise({
    required this.name,
    required this.muscles,
    required this.muscleTarget,
    required this.sets,
    required this.reps,
    required this.rest,
    this.note,
    this.isStar = false,
  });
}

class WorkoutDay {
  final String dayName;
  final String subtitle;
  final String badge;
  final String description;
  final bool isRest;
  final bool isOptional;
  final String? optionalDesc;
  final List<Exercise> exercises;
  final List<String>? recoveryOptions;
  final String? circuitNote;

  const WorkoutDay({
    required this.dayName,
    required this.subtitle,
    required this.badge,
    required this.description,
    this.isRest = false,
    this.isOptional = false,
    this.optionalDesc,
    this.exercises = const [],
    this.recoveryOptions,
    this.circuitNote,
  });
}
