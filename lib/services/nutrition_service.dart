import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_workout.dart';
import 'daily_workout_service.dart';

const mealsKey = 'recomp_meals_v1';
const mealReferences = [
  ('breakfast', '早餐', '3 个水煮蛋 + 250ml 低脂牛奶或无糖豆浆 + 1 根玉米或 50g 燕麦片。'),
  ('lunch', '午餐', '150g 瘦肉（鸡 / 牛 / 鱼 / 虾）+ 1.5–2 拳头米饭 + 2 拳头少油绿叶菜。'),
  (
    'preworkout',
    '练前加餐',
    '下班直接训练时，17:00 左右：1 袋 100g 优形鸡胸肉 + 1 根香蕉或 2 片面包。休息日按实际需要安排。'
  ),
  ('dinner', '晚餐', '练后回家：100g 瘦肉 + 1–1.5 拳头米饭 + 大量蔬菜。'),
  ('extra', '其他 / 蛋白饮', '记录当天其他食物、饮料或蛋白饮；用量和营养以实际食用与包装标注为准。'),
];

class MealEntry {
  final String date;
  final String meal;
  final String actual;
  final double? calories;
  final double? protein;
  const MealEntry(
      {required this.date,
      required this.meal,
      required this.actual,
      this.calories,
      this.protein});
  String get id => '$date|$meal';
  Map<String, dynamic> toJson() => {
        'date': date,
        'meal': meal,
        'actual': actual,
        'calories': calories,
        'protein': protein
      };
  factory MealEntry.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String;
    final meal = json['meal'] as String;
    final actual = json['actual'] as String;
    final calories = (json['calories'] as num?)?.toDouble();
    final protein = (json['protein'] as num?)?.toDouble();
    if (dayKey(DateTime.parse(date)) != date ||
        !mealReferences.any((m) => m.$1 == meal) ||
        actual.trim().isEmpty ||
        [calories, protein].any((v) => v != null && (!v.isFinite || v < 0))) {
      throw const FormatException('饮食记录无效');
    }
    return MealEntry(
        date: date,
        meal: meal,
        actual: actual,
        calories: calories,
        protein: protein);
  }
}

Map<String, MealEntry> decodeMeals(String? raw) {
  if (raw == null) return {};
  return Map<String, dynamic>.from(jsonDecode(raw) as Map).map((key, value) {
    final meal = MealEntry.fromJson(Map<String, dynamic>.from(value as Map));
    if (key != meal.id) throw const FormatException('饮食记录日期不一致');
    return MapEntry(key, meal);
  });
}

Future<Map<String, MealEntry>> loadMeals() async {
  final prefs = await SharedPreferences.getInstance();
  final pending = _mealWrites[prefs];
  if (pending != null) await pending;
  return decodeMeals(prefs.getString(mealsKey));
}

final _mealWrites = Expando<Future<void>>('meal writes');
Future<void> saveMealEntry(String id, MealEntry? meal) async {
  final prefs = await SharedPreferences.getInstance();
  final previous = _mealWrites[prefs] ?? Future<void>.value();
  final next = previous.then((_) async {
    if (meal != null) {
      MealEntry.fromJson(meal.toJson());
      if (id != meal.id) throw const FormatException('饮食记录标识不一致');
    }
    final meals = decodeMeals(prefs.getString(mealsKey));
    if (meal == null) {
      meals.remove(id);
    } else {
      meals[id] = meal;
    }
    await writeJson(prefs, mealsKey,
        {for (final e in meals.entries) e.key: e.value.toJson()});
  });
  _mealWrites[prefs] = next.catchError((Object _) {});
  await next;
}
