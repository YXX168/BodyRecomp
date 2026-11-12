import 'package:shared_preferences/shared_preferences.dart';

// The new explicit-completion UI starts with manual timers, including upgrades.
const String autoRestTimerKey = 'recomp_auto_rest_timer_v2';

int restSecondsUntil(DateTime deadline, {DateTime? now}) {
  final milliseconds =
      deadline.difference(now ?? DateTime.now()).inMilliseconds;
  if (milliseconds <= 0) return 0;
  return (milliseconds / Duration.millisecondsPerSecond).ceil();
}

int? parseRestSeconds(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized.contains('循环')) return null;
  final clock = RegExp(r'^(\d+):([0-5]\d)$').firstMatch(normalized);
  final mixed = RegExp(r'^(\d+)\s*(?:分钟|分|min)\s*(\d+)\s*(?:秒|s)$')
      .firstMatch(normalized);
  final simple = RegExp(
          r'^(\d+(?:\.\d+)?)(?:\s*[-–~至]\s*\d+(?:\.\d+)?)?\s*(分钟|分|min|秒钟|秒|sec|s)?$')
      .firstMatch(normalized);
  double? amount;
  if (clock != null) {
    amount =
        double.tryParse(clock.group(1)!)! * 60 + double.parse(clock.group(2)!);
  } else if (mixed != null) {
    amount =
        double.tryParse(mixed.group(1)!)! * 60 + double.parse(mixed.group(2)!);
  } else if (simple != null) {
    amount = double.tryParse(simple.group(1)!);
    if (const ['分钟', '分', 'min'].contains(simple.group(2))) {
      amount = amount! * 60;
    }
  }
  if (amount == null || !amount.isFinite || amount <= 0) return null;
  final seconds = amount.round();
  return seconds.clamp(1, 3600).toInt();
}

Future<bool> loadAutoRestTimer({SharedPreferences? preferences}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  return prefs.getBool(autoRestTimerKey) ?? false;
}

Future<void> saveAutoRestTimer(
  bool enabled, {
  SharedPreferences? preferences,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  if (!await prefs.setBool(autoRestTimerKey, enabled)) {
    throw StateError('计时偏好保存失败');
  }
}
