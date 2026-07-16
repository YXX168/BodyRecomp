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
    final activeDayIndex = workoutDays[dayIndex].exercises.isEmpty
        ? 0
        : dayIndex;
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

  testWidgets(
    'switching workout day uses a page transition and staged entries',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ThemeState(child: RecompApp()));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsWidgets);
      expect(find.byType(FadeScaleEntry), findsWidgets);

      final currentDay = DateTime.now().weekday - 1;
      final nextDay = (currentDay + 1) % workoutDays.length;
      await tester.tap(find.text(['一', '二', '三', '四', '五', '六', '日'][nextDay]));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SlideTransition), findsWidgets);
    },
  );

  testWidgets('workout rest timer starts, extends and dismisses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(const ValueKey('exercise_card_0_0'));
    await tester.tap(firstCard);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rest-timer-add')));
    await tester.pump();
    expect(find.text('2:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rest-timer-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
  });
}
