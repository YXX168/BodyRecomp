import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:body_recomp/main.dart';
import 'package:body_recomp/services/history_service.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pump(const Duration(milliseconds: 800));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'recomp_done_v6_week': isoWeekNumber(DateTime.now()),
      'recomp_done_v6_year': isoWeekYear(DateTime.now()),
      'recomp_done_v6': '{}',
    });
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('tapping an exercise card advances one set at a time', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

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

    final firstExercise = workoutDays[activeDayIndex].exercises.first;
    expect(find.text('0/$exerciseTotal'), findsOneWidget);
    expect(
      find.text('已完成 1/${firstExercise.sets} 组 · 点击完成下一组'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: firstCard,
        matching: find.text(workoutDays[activeDayIndex].exercises.first.note!),
      ),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('recomp_done_v6'),
      contains('${activeDayIndex}_0'),
    );

    for (var set = 1; set < firstExercise.sets; set++) {
      await tester.tap(firstCard);
      await tester.pumpAndSettle();
    }
    expect(find.text('1/$exerciseTotal'), findsOneWidget);
    expect(find.text('已完成 · 再点一次重置'), findsOneWidget);
    expect(find.byKey(const Key('exercise-completion-pulse')), findsWidgets);

    await tester.tap(firstCard);
    await tester.pumpAndSettle();
    expect(find.text('0/$exerciseTotal'), findsOneWidget);
  });

  testWidgets(
    'switching workout day uses a page transition and staged entries',
    (WidgetTester tester) async {
      await pumpApp(tester);

      expect(find.byType(AnimatedSwitcher), findsWidgets);
      expect(find.byType(FadeScaleEntry), findsWidgets);

      final currentDay = DateTime.now().weekday - 1;
      final nextDay = (currentDay + 1) % workoutDays.length;
      await tester.tap(find.text(['一', '二', '三', '四', '五', '六', '日'][nextDay]));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SlideTransition), findsWidgets);
    },
  );

  testWidgets('workout rest timer starts after a set, extends and dismisses', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(const ValueKey('exercise_card_0_0'));
    await tester.tap(firstCard);
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);

    tester
        .widget<IconButton>(find.byKey(const Key('rest-timer-add')))
        .onPressed!();
    await tester.pump();
    expect(find.text('2:00'), findsOneWidget);

    tester
        .widget<IconButton>(find.byKey(const Key('rest-timer-dismiss')))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
  });

  testWidgets('finishing the last set does not start another rest timer', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(const ValueKey('exercise_card_0_0'));
    final sets = workoutDays.first.exercises.first.sets;

    for (var set = 0; set < sets; set++) {
      await tester.tap(firstCard);
      await tester.pump(const Duration(milliseconds: 250));
      if (set < sets - 1) {
        expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
        tester
            .widget<IconButton>(find.byKey(const Key('rest-timer-dismiss')))
            .onPressed!();
        await tester.pumpAndSettle();
      }
    }

    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
    expect(find.text('1/${workoutDays.first.exercises.length}'), findsOneWidget);
  });
}
