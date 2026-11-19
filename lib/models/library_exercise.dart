import 'recomp_models.dart';

/// Editable entry in the user's local exercise library.
class LibraryExercise {
  final String id;
  final String category;
  final Exercise exercise;
  final bool isFavorite;
  final bool isBuiltIn;

  const LibraryExercise({
    required this.id,
    required this.category,
    required this.exercise,
    this.isFavorite = false,
    this.isBuiltIn = false,
  });

  LibraryExercise copyWith({
    String? id,
    String? category,
    Exercise? exercise,
    bool? isFavorite,
    bool? isBuiltIn,
  }) =>
      LibraryExercise(
        id: id ?? this.id,
        category: category ?? this.category,
        exercise: exercise ?? this.exercise,
        isFavorite: isFavorite ?? this.isFavorite,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'exercise': exercise.toJson(),
        'isFavorite': isFavorite,
        'isBuiltIn': isBuiltIn,
      };

  factory LibraryExercise.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final category = json['category'] as String?;
    final rawExercise = json['exercise'];
    if (id == null ||
        id.trim().isEmpty ||
        category == null ||
        category.trim().isEmpty ||
        rawExercise is! Map) {
      throw const FormatException('动作库条目无效');
    }
    final exercise = Exercise.fromJson(Map<String, dynamic>.from(rawExercise));
    if (exercise.name.trim().isEmpty ||
        exercise.sets < 1 ||
        exercise.sets > 100) {
      throw const FormatException('动作参数无效');
    }
    return LibraryExercise(
      id: id,
      category: category.trim(),
      exercise: exercise,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }
}
