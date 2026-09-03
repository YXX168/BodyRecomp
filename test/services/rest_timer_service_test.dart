import 'package:body_recomp/services/rest_timer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rest parser supports seconds, ranges and minutes', () {
    expect(parseRestSeconds('90s'), 90);
    expect(parseRestSeconds('90-120s'), 90);
    expect(parseRestSeconds('2min'), 120);
    expect(parseRestSeconds('1.5 分钟'), 90);
    expect(parseRestSeconds('循环'), isNull);
    expect(parseRestSeconds(''), isNull);
  });

  test('deadline countdown is exact after pauses and rounds partial seconds up',
      () {
    final now = DateTime(2026, 9, 3, 12);
    expect(
      restSecondsUntil(
        now.add(const Duration(milliseconds: 1501)),
        now: now,
      ),
      2,
    );
    expect(restSecondsUntil(now.subtract(const Duration(seconds: 1)), now: now),
        0);
  });

  test('auto rest timer preference defaults on and persists', () async {
    final preferences = await SharedPreferences.getInstance();
    expect(await loadAutoRestTimer(preferences: preferences), isTrue);

    await saveAutoRestTimer(false, preferences: preferences);

    expect(await loadAutoRestTimer(preferences: preferences), isFalse);
  });
}
