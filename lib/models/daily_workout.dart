import 'recomp_models.dart';

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class WorkoutBlock {
  final String id;
  final Exercise exercise;
  final int completedSets;

  const WorkoutBlock(
      {required this.id, required this.exercise, this.completedSets = 0});

  WorkoutBlock copyWith({Exercise? exercise, int? completedSets}) =>
      WorkoutBlock(
        id: id,
        exercise: exercise ?? this.exercise,
        completedSets: completedSets ?? this.completedSets,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise': exercise.toJson(),
        'completedSets': completedSets,
      };

  factory WorkoutBlock.fromJson(Map<String, dynamic> json) {
    final exercise =
        Exercise.fromJson(Map<String, dynamic>.from(json['exercise'] as Map));
    final count = json['completedSets'] as int;
    if ((json['id'] as String).isEmpty ||
        exercise.name.trim().isEmpty ||
        exercise.sets < 1 ||
        exercise.sets > 100 ||
        count < 0 ||
        count > exercise.sets) {
      throw const FormatException('训练项目或完成组数无效');
    }
    return WorkoutBlock(
        id: json['id'] as String, exercise: exercise, completedSets: count);
  }
}

class DailyWorkout {
  final String date;
  final List<WorkoutBlock> blocks;
  final bool rested;
  const DailyWorkout(
      {required this.date, this.blocks = const [], this.rested = false});

  // A partial workout is still a real training day.
  int get trainedProjects =>
      blocks.where((block) => block.completedSets > 0).length;
  int get completedSets =>
      blocks.fold(0, (sum, block) => sum + block.completedSets);
  int get plannedSets =>
      blocks.fold(0, (sum, block) => sum + block.exercise.sets);

  DailyWorkout copyWith({List<WorkoutBlock>? blocks, bool? rested}) =>
      DailyWorkout(
        date: date,
        blocks: blocks ?? this.blocks,
        rested: rested ?? this.rested,
      );
  Map<String, dynamic> toJson() => {
        'date': date,
        'blocks': blocks.map((block) => block.toJson()).toList(),
        'rested': rested,
      };
  factory DailyWorkout.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String;
    if (dayKey(DateTime.parse(date)) != date) {
      throw const FormatException('训练日期无效');
    }
    final blocks = (json['blocks'] as List)
        .map((value) =>
            WorkoutBlock.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
    if (blocks.map((block) => block.id).toSet().length != blocks.length) {
      throw const FormatException('训练项目 ID 重复');
    }
    final rested = json['rested'] as bool? ?? false;
    if (rested && blocks.isNotEmpty) {
      throw const FormatException('休息日不能同时包含训练项目');
    }
    return DailyWorkout(date: date, blocks: blocks, rested: rested);
  }
}

class WorkoutTemplate {
  final String id;
  final String name;
  final String note;
  final List<Exercise> exercises;
  const WorkoutTemplate(
      {required this.id,
      required this.name,
      this.note = '',
      this.exercises = const []});
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      };
  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final exercises = (json['exercises'] as List)
        .map((value) =>
            Exercise.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
    if (id.isEmpty ||
        name.trim().isEmpty ||
        exercises
            .any((e) => e.name.trim().isEmpty || e.sets < 1 || e.sets > 100)) {
      throw const FormatException('训练模板无效');
    }
    return WorkoutTemplate(
        id: id,
        name: name,
        note: json['note'] as String? ?? '',
        exercises: exercises);
  }
}
