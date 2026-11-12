import 'package:body_recomp/main.dart';
import 'package:body_recomp/pages/nutrition_page.dart';
import 'package:body_recomp/pages/template_manager_page.dart';
import 'package:body_recomp/pages/workout_page.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/models/recomp_models.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:body_recomp/services/nutrition_service.dart';
import 'package:body_recomp/widgets/body_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> open(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue), home: Scaffold(body: page)));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) await tester.scrollUntilVisible(finder, 180);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'template back protects note edits, save and discard are distinct',
      (tester) async {
    await open(tester, const TemplateManagerPage());
    await tap(tester, find.text('新建模板'));
    await tester.enterText(find.byType(TextField), '新安排');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('模板有未保存的修改'), findsOneWidget);
    await tap(tester, find.text('继续编辑'));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '新安排');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text('保存并返回'));
    expect((await loadWorkoutTemplates()).last.note, '新安排');
    await tap(tester, find.text('我的训练模板'));
    await tester.enterText(find.byType(TextField), '不保存这次修改');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(tester, find.text('放弃修改'));
    expect((await loadWorkoutTemplates()).last.note, '新安排');
    expect(tester.takeException(), isNull);
  });

  testWidgets('template removal can be undone before save', (tester) async {
    final original = (await loadWorkoutTemplates()).first.exercises;
    await open(tester, const TemplateManagerPage());
    await tap(tester, find.text('推 · 胸肩三头').first);
    await tap(tester, find.text('移除').first);
    await tap(tester, find.text('撤销'));
    await tap(tester, find.byKey(const Key('save-template')));
    expect((await loadWorkoutTemplates()).first.exercises.map((e) => e.name),
        original.map((e) => e.name));
  });

  testWidgets('body editor rejects invalid values and stays above keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    Map<String, double>? result;
    await open(
        tester,
        Builder(
            builder: (context) => TextButton(
                onPressed: () async => result = await editBodyValues(context,
                    title: '记录围度',
                    fields: const {'waist': '腰围 · cm', 'arm': '臂围 · cm'},
                    initial: const {}),
                child: const Text('记录'))));
    await tap(tester, find.text('记录'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('save-body-values')));
    expect(find.text('请至少填写一项围度'), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('body-value-waist')), '80');
    await tester.enterText(find.byKey(const ValueKey('body-value-arm')), '-1');
    await tap(tester, find.byKey(const Key('save-body-values')));
    expect(find.text('请输入大于 0 的有效数字'), findsOneWidget);
    expect(result, isNull);
    await tester.enterText(find.byKey(const ValueKey('body-value-arm')), 'NaN');
    await tap(tester, find.byKey(const Key('save-body-values')));
    expect(result, isNull);
    await tester.enterText(find.byKey(const ValueKey('body-value-arm')), '32');
    expect(tester.getBottomRight(find.byKey(const Key('save-body-values'))).dy,
        lessThanOrEqualTo(308));
    await tap(tester, find.byKey(const Key('save-body-values')));
    expect(result, {'waist': 80, 'arm': 32});
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale meal undo cannot replace a new record', (tester) async {
    final date = dayKey(DateTime.now());
    final id = '$date|breakfast';
    await saveMealEntry(
        id, MealEntry(date: date, meal: 'breakfast', actual: '旧早餐'));
    await open(tester, const NutritionPage());
    await tap(tester, find.byKey(const ValueKey('edit-meal-breakfast')));
    await tap(tester, find.byKey(const Key('clear-meal')));
    final staleUndo =
        tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed;
    await tap(tester, find.byKey(const ValueKey('edit-meal-breakfast')));
    await tester.enterText(find.byKey(const Key('meal-actual-input')), '新早餐');
    await tap(tester, find.byKey(const Key('save-meal')));
    staleUndo();
    await tester.pumpAndSettle();
    expect((await loadMeals())[id]!.actual, '新早餐');
  });

  testWidgets('meal sheet validates nutrition on a small screen with keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester, const NutritionPage());
    await tap(tester, find.byKey(const ValueKey('edit-meal-breakfast')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('meal-actual-input')), '鸡蛋和牛奶');
    await tap(tester, find.byKey(const Key('save-meal')));
    expect((await loadMeals()).values.single.actual, '鸡蛋和牛奶');
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest marker can be cancelled without logging training',
      (tester) async {
    await open(tester, const WorkoutPage());
    await tap(tester, find.byKey(const Key('record-rest')));
    expect((await loadDailyWorkouts())[dayKey(DateTime.now())]!.rested, isTrue);
    await tap(tester, find.text('取消休息标记'));
    final session = (await loadDailyWorkouts())[dayKey(DateTime.now())]!;
    expect(session.rested, isFalse);
    expect(session.completedSets, 0);
  });

  testWidgets('damaged body data offers recovery without replacing it',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(weightHistoryKey, '[damaged');
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('nav-3')));
    expect(find.text('身体数据读取失败，原记录已保留。'), findsOneWidget);
    expect(find.text('导出原数据'), findsOneWidget);
    expect(find.text('导入备份'), findsOneWidget);
    expect(prefs.getString(weightHistoryKey), '[damaged');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'profile weight edit persists profile and same-day history together',
      (tester) async {
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('nav-3')));
    await tap(tester, find.text('个人资料').first);
    await tap(tester, find.text('当前体重'));
    await tester.enterText(
        find.byKey(const ValueKey('body-value-weight')), '-70');
    await tap(tester, find.byKey(const Key('save-body-values')));
    expect(find.text('请输入大于 0 的有效数字'), findsOneWidget);
    expect(await loadWeightHistory(), isEmpty);
    await tester.enterText(
        find.byKey(const ValueKey('body-value-weight')), '70.2');
    await tap(tester, find.byKey(const Key('save-body-values')));
    expect((await loadProfile()).weightKg, 70.2);
    expect((await loadWeightHistory()).single.weightKg, 70.2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('body trend chart fills the available card width',
      (tester) async {
    await saveWeightEntry(WeightEntry(
        date: DateTime.now().subtract(const Duration(days: 1)), weightKg: 72));
    await saveWeightEntry(WeightEntry(date: DateTime.now(), weightKg: 71.5));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('nav-3')));
    expect(tester.getSize(find.byType(MiniTrendChart)).width, greaterThan(280));
    expect(tester.takeException(), isNull);
  });
}
