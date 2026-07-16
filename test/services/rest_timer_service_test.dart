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

  test('auto rest timer preference defaults on and persists', () async {
    final preferences = await SharedPreferences.getInstance();
    expect(await loadAutoRestTimer(preferences: preferences), isTrue);

    await saveAutoRestTimer(false, preferences: preferences);

    expect(await loadAutoRestTimer(preferences: preferences), isFalse);
  });
}
