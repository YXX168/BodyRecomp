import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:body_recomp/main.dart';
import 'package:body_recomp/services/history_service.dart';
import 'package:body_recomp/services/rest_timer_service.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size logicalSize = const Size(360, 800),
    double devicePixelRatio = 3,
    double textScaleFactor = 1,
  }) async {
    tester.view.physicalSize = logicalSize * devicePixelRatio;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

  testWidgets('training UI fits a compact phone with larger text', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      logicalSize: const Size(320, 568),
      devicePixelRatio: 2,
      textScaleFactor: 1.3,
    );
    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(const ValueKey('exercise_card_0_0'));
    expect(firstCard, findsOneWidget);

    await tester.ensureVisible(firstCard);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(firstCard);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an exercise card advances one set at a time', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
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
    final secondCard =
        find.byKey(ValueKey('exercise_card_${activeDayIndex}_1'));
    expect(firstCard, findsOneWidget);
    expect(secondCard, findsOneWidget);
    expect(find.text('0/$exerciseTotal'), findsOneWidget);
    final initialFirstRect = tester.getRect(firstCard);
    final initialSecondRect = tester.getRect(secondCard);

    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    final firstExercise = workoutDays[activeDayIndex].exercises.first;
    expect(find.text('0/$exerciseTotal'), findsOneWidget);
    expect(find.text('1/${firstExercise.sets} 组完成 · 点击继续'), findsOneWidget);
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
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(find.text('1/$exerciseTotal'), findsOneWidget);
    expect(
      find.text('${firstExercise.sets}/${firstExercise.sets} 组已完成'),
      findsOneWidget,
    );
    expect(tester.getRect(firstCard), initialFirstRect);
    expect(tester.getRect(secondCard), initialSecondRect);

    final saved = jsonDecode(
      (await SharedPreferences.getInstance()).getString('recomp_done_v6')!,
    ) as Map<String, dynamic>;
    expect(saved['${activeDayIndex}_0'], isTrue);

    await tester.tap(firstCard);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('1/$exerciseTotal'), findsOneWidget);

    await tester.tap(
      find.byKey(ValueKey('exercise_reset_${activeDayIndex}_0')),
    );
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

  testWidgets('rest timer overlay never moves exercise tap targets', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();

    final firstCard = find.byKey(const ValueKey('exercise_card_0_0'));
    final secondCard = find.byKey(const ValueKey('exercise_card_0_1'));
    final firstRect = tester.getRect(firstCard);
    final secondRect = tester.getRect(secondCard);

    await tester.tapAt(firstRect.center);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect(tester.getRect(firstCard), firstRect);
    expect(tester.getRect(secondCard), secondRect);

    await tester.tapAt(firstRect.center);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('2/4 组完成 · 点击继续'), findsOneWidget);
    expect(
      find.descendant(
        of: secondCard,
        matching: find.text('点击卡片完成第 1 组'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('manual timer button does not complete a set', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('exercise_timer_0_0')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('exercise_card_0_0')),
        matching: find.text('点击卡片完成第 1 组'),
      ),
      findsOneWidget,
    );
    expect(
      (await SharedPreferences.getInstance()).getString('recomp_done_v6'),
      '{}',
    );
  });

  testWidgets('timer and selected day survive bottom navigation changes', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise_timer_0_0')));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('饮食'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('训练'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise_card_0_0')), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('auto rest preference updates the preserved workout page', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('一'));
    await tester.pumpAndSettle();

    await saveAutoRestTimer(false);
    restTimerPreferenceRevision.value++;
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('exercise_card_0_0')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
  });

  testWidgets('record page refreshes after workout progress changes', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    final now = DateTime.now();
    final weekStart = startOfIsoWeek(now);
    final dayIndex =
        List<int>.generate(workoutDays.length, (index) => index).firstWhere(
      (index) =>
          workoutDays[index].exercises.isNotEmpty &&
          weekStart.add(Duration(days: index)).month == now.month,
    );
    await tester.tap(find.text(['一', '二', '三', '四', '五', '六', '日'][dayIndex]));
    await tester.pumpAndSettle();
    final firstCard = find.byKey(ValueKey('exercise_card_${dayIndex}_0'));

    for (var set = 0; set < workoutDays[dayIndex].exercises.first.sets; set++) {
      await tester.tap(firstCard);
      await tester.pump(const Duration(milliseconds: 350));
    }

    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('record-stat-完成动作')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
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
    expect(
      find.text('1/${workoutDays.first.exercises.length}'),
      findsOneWidget,
    );
  });
}
