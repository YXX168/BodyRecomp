import 'dart:convert';

import 'package:body_recomp/services/history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ISO week helpers handle year boundaries', () {
    final newYearFriday = DateTime(2021, 1, 1);

    expect(isoWeekYear(newYearFriday), 2020);
    expect(isoWeekNumber(newYearFriday), 53);
    expect(startOfIsoWeek(newYearFriday), DateTime(2020, 12, 28));
    expect(startOfIsoWeekByYearWeek(2020, 53), DateTime(2020, 12, 28));
  });

  test('done keys are counted by weekday and mapped to actual dates', () {
    final done = <String, dynamic>{
      '0_0': true,
      '0_1': true,
      '2_0': true,
      '6_4': false,
      'invalid': true,
      '7_0': true,
    };

    expect(countByWeekday(done), {0: 2, 2: 1});
    expect(countByActualDate(done, 2020, 53), {
      DateTime(2020, 12, 28): 2,
      DateTime(2020, 12, 30): 1,
    });
  });

  test(
    'saving a week writes real dates across month and year boundaries',
    () async {
      final preferences = await SharedPreferences.getInstance();

      await saveWeekDoneToHistory(
        preferences,
        {'0_0': true, '4_0': true, '4_1': true},
        2020,
        53,
      );

      expect(await loadMonthHistory(preferences, 2020, 12), {28: 1});
      expect(await loadMonthHistory(preferences, 2021, 1), {1: 2});
    },
  );

  test('month history ignores malformed and legacy weekday entries', () async {
    SharedPreferences.setMockInitialValues({
      historyKey(2026, 2): jsonEncode({
        '0': 3,
        '1': 0,
        '14': '2',
        '29': 4,
        'bad': 9,
      }),
    });
    final preferences = await SharedPreferences.getInstance();

    expect(await loadMonthHistory(preferences, 2026, 2), {14: 2});
  });

  test('zero actual-date count removes an existing history entry', () async {
    SharedPreferences.setMockInitialValues({
      historyKey(2026, 7): jsonEncode({'15': 4, '16': 2}),
    });
    final preferences = await SharedPreferences.getInstance();

    await saveActualDateCountsToHistory(preferences, {
      DateTime(2026, 7, 15): 0,
    });

    expect(await loadMonthHistory(preferences, 2026, 7), {16: 2});
  });
}
