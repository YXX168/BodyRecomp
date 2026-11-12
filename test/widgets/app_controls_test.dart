import 'dart:convert';
import 'package:body_recomp/main.dart';
import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/pages/template_manager_page.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/widgets/exercise_editor.dart';
import 'package:body_recomp/widgets/daily_date_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> visible(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) await tester.scrollUntilVisible(finder, 200);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'editor preserves a snapshot, presets and edits while keyboard is open',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final original = defaultTemplates.first.exercises[3];
    dynamic result;
    await tester.pumpWidget(MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async =>
                        result = await editExercise(context, initial: original),
                    child: const Text('编辑'))))));
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await visible(tester, find.byKey(const Key('exercise-sets-plus')));
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('exercise-sets')))
            .controller!
            .text,
        '6');
    await visible(tester, find.byKey(const ValueKey('rest-preset-90')));
    await tester.enterText(find.byKey(const Key('exercise-name')), '侧平举 · 器械');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('save-exercise'));
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(568 - 260));
    expect(tester.takeException(), isNull);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(result.name, '侧平举 · 器械');
    expect(result.sets, 6);
    expect(result.rest, '90s');
    expect(result.muscles, original.muscles);
    expect(result.isStar, original.isStar);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'weekly schedule selector persists selection and cancel is harmless',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: const TemplateManagerPage()));
    await tester.pumpAndSettle();
    await visible(tester, find.byKey(const ValueKey('schedule-day-0')));
    await visible(tester, find.byKey(const ValueKey('schedule-option-pull')));
    expect((await loadWeeklySchedule()).first, 'pull');
    await visible(tester, find.byKey(const ValueKey('schedule-day-0')));
    expect(find.text('周一安排'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect((await loadWeeklySchedule()).first, 'pull');
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact date selector opens on demand and can return to today',
      (tester) async {
    var date = DateTime(2026, 11, 12);
    final today = date;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
                builder: (context, update) => DailyDateBar(
                    date: date,
                    today: today,
                    onChanged: (value) => update(() => date = value))))));
    expect(find.byType(CalendarDatePicker), findsNothing);
    await tester.tap(find.byKey(const Key('choose-date')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
            .lastDate,
        today);
    await tester.tap(find.descendant(
        of: find.byType(CalendarDatePicker), matching: find.text('11')));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(date, DateTime(2026, 11, 11));
    await tester.tap(find.byKey(const Key('choose-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(CalendarDatePicker), matching: find.text('10')));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(date, DateTime(2026, 11, 11));
    await tester.tap(find.byKey(const Key('return-today')));
    await tester.pumpAndSettle();
    expect(date, today);
    expect(
        tester.widget<IconButton>(find.byKey(const Key('next-date'))).onPressed,
        isNull);
  });

  testWidgets('theme changes isolate hidden tabs and retain workout and timer',
      (tester) async {
    final date = dayKey(DateTime.now());
    final session = DailyWorkout(date: date, blocks: [
      WorkoutBlock(
          id: 'stable',
          exercise: defaultTemplates.first.exercises.first,
          completedSets: 1)
    ]);
    SharedPreferences.setMockInitialValues({
      dailyWorkoutsKey: jsonEncode({date: session.toJson()})
    });
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    await visible(tester, find.byKey(const ValueKey('start-rest-0')));
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    final hidden = tester.element(find.byType(RecordPage));
    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    expect(TickerMode.valuesOf(hidden).enabled, isFalse);
    await tester.tap(find.byTooltip('切换主题'));
    await tester.pumpAndSettle();
    await visible(tester, find.byKey(const ValueKey('theme-option-dark')));
    expect(Theme.of(tester.element(find.byType(MainPage))).brightness,
        Brightness.dark);
    expect(Theme.of(hidden).brightness, Brightness.light);
    expect((await SharedPreferences.getInstance()).getInt('recomp_theme_v6'),
        AppTheme.dark.index);
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    expect(Theme.of(hidden).brightness, Brightness.dark);
    expect(TickerMode.valuesOf(hidden).enabled, isTrue);
    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect((await loadDailyWorkouts())[date]!.completedSets, 1);
    final controller = ThemeInherited.of(tester.element(find.byType(MainPage)));
    await Future.wait([
      controller.setTheme(AppTheme.purple),
      controller.setTheme(AppTheme.dark),
      controller.setTheme(AppTheme.blue),
    ]);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(MainPage))).brightness,
        Brightness.light);
    expect((await SharedPreferences.getInstance()).getInt('recomp_theme_v6'),
        AppTheme.blue.index);
    expect(tester.takeException(), isNull);
  });
}
