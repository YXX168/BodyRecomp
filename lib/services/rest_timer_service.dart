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
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
  if (match == null) return null;
  final amount = double.tryParse(match.group(1)!);
  if (amount == null || amount <= 0) return null;
  final usesMinutes = normalized.contains('min') || normalized.contains('分钟');
  final seconds = (amount * (usesMinutes ? 60 : 1)).round();
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
  await prefs.setBool(autoRestTimerKey, enabled);
}
