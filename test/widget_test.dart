import 'dart:convert';
import 'package:body_recomp/main.dart';
import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/pages/workout_page.dart';
import 'package:body_recomp/pages/nutrition_page.dart';
import 'package:body_recomp/pages/template_manager_page.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/rest_timer_service.dart';
import 'package:body_recomp/services/nutrition_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final today = DateTime(2026, 11, 12, 19);
  DailyWorkout seeded({int done = 0}) =>
      DailyWorkout(date: dayKey(today), blocks: [
        WorkoutBlock(
            id: 'bench',
            exercise: defaultTemplates.first.exercises.first,
            completedSets: done)
      ]);
  void seed(DailyWorkout session) => SharedPreferences.setMockInitialValues({
        dailyWorkoutsKey: jsonEncode({session.date: session.toJson()})
      });
  Future<void> pump(WidgetTester tester, Widget page,
      {Size size = const Size(390, 844), double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true), home: Scaffold(body: page)));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 180);
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('reference remains separate and supports partial selection',
      (tester) async {
    await pump(tester, WorkoutPage(now: () => today));
    expect(find.text('腿 · 核心与肩补强'), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-block-0')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('use-suggestion')));
    await tester.tap(find.byKey(const ValueKey('pick_0_0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-picked-exercises')));
    await tester.pumpAndSettle();
    final session = (await loadDailyWorkouts())[dayKey(today)]!;
    expect(session.blocks.single.exercise.name, '倒蹬机');
    expect(session.completedSets, 0);
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
  });

  testWidgets('title taps never log sets; explicit completion and undo persist',
      (tester) async {
    seed(seeded());
    await pump(tester, WorkoutPage(now: () => today));
    await tapVisible(tester, find.text('平板卧推'));
    expect((await loadDailyWorkouts())[dayKey(today)]!.completedSets, 0);
    await tapVisible(tester, find.byKey(const ValueKey('complete-set-0')));
    expect((await loadDailyWorkouts())[dayKey(today)]!.completedSets, 1);
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('undo-set-0')));
    expect((await loadDailyWorkouts())[dayKey(today)]!.completedSets, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mixing blocks from different templates preserves earlier progress',
      (tester) async {
    seed(seeded(done: 2));
    await pump(tester, WorkoutPage(now: () => today));
    await tapVisible(tester, find.byKey(const Key('choose-blocks')));
    await tester.tap(find.byKey(const ValueKey('pick_0_0')));
    await tester.tap(find.byKey(const ValueKey('picker-template-pull')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick_1_0')));
    await tester.tap(find.byKey(const Key('add-picked-exercises')));
    await tester.pumpAndSettle();
    final blocks = (await loadDailyWorkouts())[dayKey(today)]!.blocks;
    expect(blocks, hasLength(3));
    expect(blocks.first.completedSets, 2);
    expect(blocks.last.exercise.name, '宽握高位下拉');
  });

  testWidgets(
      'library search keeps selection across templates and fits keyboard',
      (tester) async {
    await pump(tester, WorkoutPage(now: () => today),
        size: const Size(320, 568), scale: 1.3);
    await tapVisible(tester, find.byKey(const Key('choose-blocks')));
    await tester.enterText(find.byKey(const Key('exercise-search')), '侧平举');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('pick_0_3')));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.enterText(find.byKey(const Key('exercise-search')), '下拉');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick_1_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-picked-exercises')));
    await tester.pumpAndSettle();
    final blocks = (await loadDailyWorkouts())[dayKey(today)]!.blocks;
    expect(blocks.map((b) => b.exercise.name), ['哑铃侧平举', '宽握高位下拉']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timer start, expiry and dismissal never shift exercise cards',
      (tester) async {
    seed(seeded());
    var now = today;
    await pump(tester, WorkoutPage(now: () => now),
        size: const Size(320, 568), scale: 1.3);
    final block = find.byKey(const ValueKey('workout-block-0'));
    await tester.ensureVisible(block);
    await tester.pumpAndSettle();
    final before = tester.getRect(block);
    final pill = tester.getRect(find.byKey(const Key('rest-timer-pill')));
    await tester.tap(find.byKey(const ValueKey('start-rest-0')));
    await tester.pumpAndSettle();
    expect(tester.getRect(block), before);
    expect(tester.getRect(find.byKey(const Key('rest-timer-pill'))), pill);
    expect(pill.bottom, lessThanOrEqualTo(tester.getTopLeft(block).dy));
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
    expect(tester.getRect(block), before);
    await tester.tap(find.byKey(const ValueKey('start-rest-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rest-timer-dismiss')));
    await tester.pumpAndSettle();
    expect(tester.getRect(block), before);
    expect(tester.getRect(find.byKey(const Key('rest-timer-pill'))), pill);
    expect((await loadDailyWorkouts())[dayKey(today)]!.completedSets, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'manual countdown fits compact phone with large text without overlay',
      (tester) async {
    seed(seeded());
    var now = today;
    await pump(tester, WorkoutPage(now: () => now),
        size: const Size(320, 568), scale: 1.3);
    await tapVisible(tester, find.byKey(const ValueKey('start-rest-0')));
    final timer = find.byKey(const Key('rest-timer-panel'));
    await tester.ensureVisible(timer);
    await tester.pumpAndSettle();
    expect(find.text('1:30'), findsOneWidget);
    expect(find.ancestor(of: timer, matching: find.byType(Positioned)),
        findsNothing);
    await tapVisible(tester, find.byKey(const Key('rest-timer-add')));
    expect(find.text('2:00'), findsOneWidget);
    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(timer, findsNothing);
    expect((await loadDailyWorkouts())[dayKey(today)]!.completedSets, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto timer is opt in and stops starting after final set',
      (tester) async {
    seed(seeded(done: 2));
    await saveAutoRestTimer(true);
    await pump(tester, WorkoutPage(now: () => today));
    await tapVisible(tester, find.byKey(const ValueKey('complete-set-0')));
    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('rest-timer-dismiss')));
    await tapVisible(tester, find.byKey(const ValueKey('complete-set-0')));
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
    expect((await loadDailyWorkouts())[dayKey(today)]!.completedSets, 4);
  });

  testWidgets(
      'backdated actual training is independent from rest-day suggestion',
      (tester) async {
    final yesterday = today.subtract(const Duration(days: 1));
    seed(DailyWorkout(date: dayKey(yesterday), blocks: seeded().blocks));
    await saveAutoRestTimer(true);
    await pump(tester, WorkoutPage(now: () => today));
    await tapVisible(tester, find.byKey(const Key('previous-date')));
    expect(find.text('休息 / 恢复'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('complete-set-0')));
    expect(find.byKey(const Key('rest-timer-panel')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('next-date')));
    expect(find.byKey(const ValueKey('workout-block-0')), findsNothing);
    expect((await loadDailyWorkouts())[dayKey(yesterday)]!.completedSets, 1);
  });

  testWidgets('removal undo restores stable block identity and progress',
      (tester) async {
    seed(seeded(done: 2));
    await pump(tester, WorkoutPage(now: () => today));
    await tapVisible(tester, find.byKey(const ValueKey('block-menu-0')));
    await tester.tap(find.text('移除项目（可撤销）'));
    await tester.pumpAndSettle();
    expect((await loadDailyWorkouts())[dayKey(today)]!.blocks, isEmpty);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    final block = (await loadDailyWorkouts())[dayKey(today)]!.blocks.single;
    expect(block.id, 'bench');
    expect(block.completedSets, 2);
  });

  testWidgets('custom templates validate set counts and save their projects',
      (tester) async {
    await pump(tester, const TemplateManagerPage());
    await tapVisible(tester, find.text('新建模板'));
    await tapVisible(tester, find.text('自定义项目'));
    await tester.enterText(find.byKey(const Key('exercise-name')), '自由组合项目');
    await tester.enterText(find.byKey(const Key('exercise-sets')), '0');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.text('请输入 1–100 组'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('exercise-sets')), '3');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect((await loadWorkoutTemplates()).last.exercises.single.name, '自由组合项目');
    expect(
        await loadWeeklySchedule(), ['push', 'pull', '', 'legs', '', '', '']);
  });

  testWidgets('meal references are not logged until explicitly saved',
      (tester) async {
    await pump(tester, const NutritionPage());
    expect(find.text('已记录 0 餐'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('edit-meal-breakfast')));
    await tester.enterText(
        find.byKey(const Key('meal-actual-input')), '2 个鸡蛋 + 牛奶');
    await tester.enterText(find.byKey(const Key('meal-calories-input')), 'NaN');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('请输入非负数字，或留空'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('meal-calories-input')), '320');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect((await loadMeals()).values.single.actual, '2 个鸡蛋 + 牛奶');
    await tester.scrollUntilVisible(find.text('已记录 1 餐'), -180);
    expect(find.text('已记录 1 餐'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tab navigation preserves timer and refreshes actual-workout statistics',
      (tester) async {
    seed(DailyWorkout(date: dayKey(DateTime.now()), blocks: seeded().blocks));
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('complete-set-0')));
    await tapVisible(tester, find.byKey(const ValueKey('start-rest-0')));
    await tester.tap(find.text('饮食'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('训练'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('record-stat-已练项目')),
            matching: find.text('1')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
