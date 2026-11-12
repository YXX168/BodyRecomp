import 'dart:ui' as ui;
import 'package:body_recomp/main.dart';
import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/rest_countdown.dart';
import 'package:body_recomp/widgets/rest_timer_pill.dart';
import 'package:body_recomp/pages/workout_page.dart';
import 'package:body_recomp/widgets/daily_date_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> seed() =>
      saveDailyWorkout(DailyWorkout(date: dayKey(DateTime.now()), blocks: [
        WorkoutBlock(
            id: 'bench', exercise: defaultTemplates.first.exercises.first)
      ]));

  testWidgets('header timer stays compact across pages without shifting cards',
      (tester) async {
    await seed();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    final pill = find.byType(RestTimerPill);
    final rect = tester.getRect(pill);
    final block = find.byKey(const ValueKey('workout-block-0'));
    final cardBefore = tester.getRect(block);
    expect(
        rect.bottom,
        lessThan(
            tester.getTopLeft(find.byKey(const Key('daily-suggestion'))).dy));
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('start-rest-0')));
    for (var frame = 0; frame < 16; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getRect(block), cardBefore);
      expect(tester.getRect(pill), rect);
    }
    await tester.pumpAndSettle();
    expect(tester.getRect(pill), rect);
    expect(tester.getRect(block), cardBefore);
    for (final tab in [1, 2, 3, 0]) {
      await tester.tap(find.byKey(ValueKey('nav-$tab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
      expect(tester.getRect(pill), rect);
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
    await tester.tap(find.byKey(const Key('rest-timer-add')));
    await tester.pumpAndSettle();
    expect(find.text('2:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rest-timer-dismiss')));
    for (var frame = 0; frame < 14; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getRect(block), cardBefore);
    }
    await tester.pumpAndSettle();
    expect(tester.getRect(block), cardBefore);
    expect((await loadDailyWorkouts()).values.single.completedSets, 0);
  });

  testWidgets('pill fades in and out without replaying on every tick',
      (tester) async {
    var now = DateTime(2026, 11, 12, 19);
    final timer = RestCountdown(now: () => now);
    addTearDown(timer.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      RestTimerPill(controller: timer),
      const SizedBox(key: Key('stable-content'), height: 80, width: 200),
    ]))));
    final content = tester.getRect(find.byKey(const Key('stable-content')));
    final panel = find.byKey(const Key('rest-timer-panel'));
    double opacity() => tester
        .widget<FadeTransition>(find
            .ancestor(of: panel, matching: find.byType(FadeTransition))
            .first)
        .opacity
        .value;
    expect(panel, findsNothing);
    timer.start(60, '测试休息');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacity(), allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    now = now.add(const Duration(seconds: 1));
    timer.refresh();
    await tester.pump();
    expect(find.text('0:59'), findsOneWidget);
    expect(opacity(), 1);
    timer.stop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacity(), allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    expect(tester.getRect(find.byKey(const Key('stable-content'))), content);
    timer.start(1, '到时隐藏');
    await tester.pumpAndSettle();
    now = now.add(const Duration(seconds: 2));
    timer.refresh();
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    expect(tester.getRect(find.byKey(const Key('stable-content'))), content);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'rapid stop and restart keeps a single face and disables the exiting pill',
      (tester) async {
    final timer = RestCountdown(now: DateTime.now);
    addTearDown(timer.dispose);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RestTimerPill(controller: timer))));
    final panel = find.byKey(const Key('rest-timer-panel'));
    for (var i = 0; i < 4; i++) {
      timer.start(60, '第一段');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      timer.stop();
      await tester.pump();
      expect(
          tester
              .widget<IgnorePointer>(find
                  .ancestor(of: panel, matching: find.byType(IgnorePointer))
                  .first)
              .ignoring,
          isTrue);
      await tester.pump(const Duration(milliseconds: 40));
      timer.start(90, '第二段');
      await tester.pump();
      expect(panel, findsOneWidget);
      expect(find.text('1:30'), findsOneWidget);
      await tester.pumpAndSettle();
    }
    timer.stop();
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date changes preserve independent expansion and timer state',
      (tester) async {
    final today = DateTime(2026, 11, 12);
    final exercise =
        defaultTemplates.first.exercises.first.copyWith(note: '日期独立的动作说明');
    for (final date in [today, today.subtract(const Duration(days: 1))]) {
      await saveDailyWorkout(DailyWorkout(
          date: dayKey(date),
          blocks: [WorkoutBlock(id: 'same-id', exercise: exercise)]));
    }
    final timer = RestCountdown(now: () => today);
    addTearDown(timer.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkoutPage(now: () => today, restController: timer))));
    await tester.pumpAndSettle();
    final summary = find.byKey(const Key('daily-suggestion'));
    final before = tester.getRect(summary);
    await tester.tap(find.text(exercise.name));
    await tester.pumpAndSettle();
    expect(find.text(exercise.note!), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('start-rest-0')));
    await tester.pumpAndSettle();
    final deadline = timer.value!.deadline;
    await tester.tap(find.byKey(const Key('previous-date')));
    await tester.pumpAndSettle();
    expect(find.text(exercise.note!), findsNothing);
    expect(tester.getRect(summary), before);
    expect(timer.value!.deadline, deadline);
    await tester.tap(find.byKey(const Key('return-today')));
    await tester.pumpAndSettle();
    expect(find.text(exercise.note!), findsOneWidget);
    expect(tester.getRect(summary), before);
    expect(timer.value!.deadline, deadline);
    timer.stop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows and hides immediately', (tester) async {
    final timer = RestCountdown(now: DateTime.now);
    addTearDown(timer.dispose);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(body: RestTimerPill(controller: timer)))));
    timer.start(90, '休息');
    await tester.pump();
    final panel = find.byKey(const Key('rest-timer-panel'));
    expect(panel, findsOneWidget);
    expect(
        tester
            .widget<FadeTransition>(find
                .ancestor(of: panel, matching: find.byType(FadeTransition))
                .first)
            .opacity
            .value,
        1);
    timer.stop();
    await tester.pump();
    expect(panel, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each date restores its own scroll position', (tester) async {
    final today = DateTime(2026, 11, 12);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final date in [today, yesterday]) {
      await saveDailyWorkout(DailyWorkout(date: dayKey(date), blocks: [
        for (var i = 0; i < 8; i++)
          WorkoutBlock(
              id: 'block-$i', exercise: defaultTemplates.first.exercises.first)
      ]));
    }
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WorkoutPage(now: () => today))));
    await tester.pumpAndSettle();
    final list = find.byType(ListView);
    double offset() => tester
        .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first)
        .position
        .pixels;
    final change =
        tester.widget<DailyDateBar>(find.byType(DailyDateBar)).onChanged;
    await tester.drag(list, const Offset(0, -350));
    await tester.pumpAndSettle();
    final todayOffset = offset();
    expect(todayOffset, greaterThan(300));
    change(yesterday);
    await tester.pumpAndSettle();
    expect(offset(), 0);
    await tester.drag(list, const Offset(0, -180));
    await tester.pumpAndSettle();
    final yesterdayOffset = offset();
    change(today);
    await tester.pumpAndSettle();
    expect(offset(), todayOffset);
    change(yesterday);
    await tester.pumpAndSettle();
    expect(offset(), yesterdayOffset);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'held workout title paints no grey rectangle and never logs a set',
      (tester) async {
    await seed();
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey, child: const ThemeState(child: RecompApp())));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('workout-block-0'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    Future<Uint8List> pixels() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return bytes!.buffer.asUint8List();
      }))!;
    }

    final before = await pixels();
    final pointer =
        await tester.startGesture(tester.getCenter(find.text('平板卧推')));
    await tester.pump(const Duration(milliseconds: 650));
    expect(listEquals(await pixels(), before), isTrue);
    await pointer.up();
    await tester.pumpAndSettle();
    expect((await loadDailyWorkouts()).values.single.completedSets, 0);
    expect(tester.takeException(), isNull);
  });
}
