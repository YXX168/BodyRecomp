import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:body_recomp/main.dart';
import 'package:body_recomp/services/history_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'recomp_done_v6_week': isoWeekNumber(DateTime.now()),
      'recomp_done_v6_year': isoWeekYear(DateTime.now()),
      'recomp_done_v6': '{}',
    });
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('tapping an exercise card toggles its completed state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();

    final dayIndex = DateTime.now().weekday - 1;
    if (workoutDays[dayIndex].exercises.isEmpty) {
      final mondayTab = find.text('一');
      expect(mondayTab, findsOneWidget);
      await tester.tap(mondayTab);
      await tester.pumpAndSettle();
    }
    final activeDayIndex =
        workoutDays[dayIndex].exercises.isEmpty ? 0 : dayIndex;
    final exerciseTotal = workoutDays[activeDayIndex].exercises.length;
    final firstCard = find.byKey(ValueKey('exercise_card_${activeDayIndex}_0'));
    expect(firstCard, findsOneWidget);
    expect(find.text('0/$exerciseTotal'), findsOneWidget);

    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    expect(find.text('1/$exerciseTotal'), findsOneWidget);
    expect(
      find.descendant(
        of: firstCard,
        matching: find.text(workoutDays[activeDayIndex].exercises.first.note!),
      ),
      findsNothing,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('recomp_done_v6'),
      contains('${activeDayIndex}_0'),
    );

    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pumpAndSettle();
    expect(find.text('0/$exerciseTotal'), findsOneWidget);
  });
}
