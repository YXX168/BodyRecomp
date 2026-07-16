import 'dart:convert';

import 'package:body_recomp/services/history_service.dart';
import 'package:body_recomp/services/record_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'current week replaces archived counts instead of double counting',
    () async {
      final now = DateTime(2026, 7, 16);
      final year = isoWeekYear(now);
      final week = isoWeekNumber(now);
      final done = <String, dynamic>{'0_0': true, '0_1': true, '2_0': true};
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('recomp_done_v6', jsonEncode(done));
      await preferences.setInt('recomp_done_v6_year', year);
      await preferences.setInt('recomp_done_v6_week', week);
      await saveWeekDoneToHistory(preferences, done, year, week);

      final summary = await loadRecordSummary(preferences, 2026, 7, now: now);

      expect(summary.yearTotal, 3);
      expect(summary.yearTrainDays, 2);
      expect(summary.monthData.values.fold(0, (sum, value) => sum + value), 3);
    },
  );

  test(
    'current week fills record summary before history is archived',
    () async {
      final now = DateTime(2026, 7, 16);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'recomp_done_v6',
        jsonEncode({'1_0': true, '1_1': true}),
      );
      await preferences.setInt('recomp_done_v6_year', isoWeekYear(now));
      await preferences.setInt('recomp_done_v6_week', isoWeekNumber(now));

      final summary = await loadRecordSummary(preferences, 2026, 7, now: now);

      expect(summary.yearTotal, 2);
      expect(summary.yearTrainDays, 1);
    },
  );
}
