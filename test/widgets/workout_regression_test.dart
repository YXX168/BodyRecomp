import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/main.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/pages/nutrition_page.dart';
import 'package:body_recomp/pages/template_manager_page.dart';
import 'package:body_recomp/pages/workout_page.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:body_recomp/services/nutrition_service.dart';
import 'package:body_recomp/services/rest_countdown.dart';
import 'package:body_recomp/widgets/ambient_background.dart';
import 'package:body_recomp/widgets/day_page_view.dart';
import 'package:body_recomp/widgets/horizontal_day_swipe.dart';
import 'package:body_recomp/widgets/rest_timer_pill.dart';
import 'package:body_recomp/widgets/week_strip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpWorkout(
    WidgetTester tester,
    Widget child, {
    AppTheme theme = AppTheme.blue,
    Size size = const Size(390, 700),
    double scale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(theme),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('coaching note expands reliably on an unmodified scheduled day',
      (tester) async {
    // Monday 2026-11-16 loads the built-in push template whose first block
    // ('平板卧推') includes a coaching note.
    final monday = DateTime(2026, 11, 16, 12);
    await pumpWorkout(tester, WorkoutPage(now: () => monday));

    const expectedNote = '沉肩锁背，杠铃下放至下胸附近控制离心，双脚蹬地稳定核心。';
    expect(find.text(expectedNote), findsNothing);

    await tester.tap(find.text('平板卧推'));
    await tester.pumpAndSettle();
    expect(find.text(expectedNote), findsOneWidget);

    // Still unmaterialized (preview mode) until the user logs or edits.
    expect((await loadDailyWorkouts())[dayKey(monday)], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'logging weight persists once with backdated date and updates weight chip',
      (tester) async {
    final thursday = DateTime(2026, 11, 12, 18, 30);
    final wednesday = DateTime(2026, 11, 11, 18, 30);
    await saveDailyWorkout(
      DailyWorkout(
        date: dayKey(wednesday),
        blocks: [
          WorkoutBlock(
            id: 'bench-wed',
            exercise: defaultTemplates.first.exercises.first,
          ),
        ],
      ),
    );

    await pumpWorkout(tester, WorkoutPage(now: () => thursday));
    await tester.tap(find.byKey(const Key('previous-date')));
    await tester.pumpAndSettle();

    final weightBtn = find.byKey(const ValueKey('log-weight-0'));
    await tester.ensureVisible(weightBtn);
    await tester.tap(weightBtn);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('weight-log-kg')), '80');
    await tester.tap(find.byKey(const Key('save-weight-log')));
    await tester.pumpAndSettle();

    // Must save exactly once (no duplicate save) and carry the backdated date.
    final logs = await loadExerciseLogs();
    expect(logs, hasLength(1));
    expect(logs.single.weightKg, 80);
    expect(dayKey(logs.single.date), dayKey(wednesday));
    expect(
      find.descendant(of: weightBtn, matching: find.text('80kg')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'WorkoutPage horizontal DayPageView swipes 1:1 with stationary WeekStripBar and cross-week sync',
      (tester) async {
    final sunday = DateTime(2026, 11, 22, 12);
    await pumpWorkout(tester, WorkoutPage(now: () => sunday));

    final weekFinder = find.byType(WeekStripBar);
    final weekBefore = tester.getRect(weekFinder);
    expect(find.text('准备开练'), findsOneWidget);

    // Mid-drag left toward Monday: adjacent day pages render 1:1 side-by-side
    // while WeekStripBar stays horizontally anchored.
    final gesture = await tester.startGesture(const Offset(340, 350));
    await gesture.moveBy(const Offset(-25, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();

    expect(
      tester.getRect(weekFinder).center.dx,
      closeTo(weekBefore.center.dx, 0.1),
    );
    expect(find.text('准备开练'), findsOneWidget);
    expect(find.text('推 · 胸肩三头'), findsOneWidget);

    await gesture.moveBy(const Offset(-90, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.textContaining('11月23日 周一'), findsOneWidget);
    expect(find.text('推 · 胸肩三头'), findsOneWidget);
    expect(find.text('准备开练'), findsNothing);

    // Tapping Thursday on WeekStripBar smoothly animates to Thursday's page.
    await tester.tap(find.byKey(const ValueKey('week-strip-day-3')));
    await tester.pumpAndSettle();
    expect(find.textContaining('11月26日 周四'), findsOneWidget);
    expect(find.text('上肢 · 轮廓与代谢'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'WorkoutPage scroll hides WeekStripBar + HeroCard and cross-swipe reveals WeekStripBar cleanly',
      (tester) async {
    final thursday = DateTime(2026, 11, 19, 12);
    await pumpWorkout(
      tester,
      WorkoutPage(now: () => thursday),
      size: const Size(390, 620),
    );

    final scrollFinder = find.byType(CustomScrollView);
    final weekFinder = find.byType(WeekStripBar);
    final heroFinder = find.byKey(const Key('daily-suggestion'));
    final viewportTop = tester.getRect(scrollFinder).top;

    await tester.drag(scrollFinder, const Offset(0, -280));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(of: weekFinder, matching: find.byType(IgnorePointer))
                .first,
          )
          .ignoring,
      isTrue,
    );
    expect(
      heroFinder.evaluate().isEmpty ||
          tester.getRect(heroFinder).bottom <= viewportTop + 4.0,
      isTrue,
    );

    // Swiping right to unscrolled Wednesday smoothly reveals WeekStripBar.
    await tester.drag(find.byType(DayPageView), const Offset(280, 0));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IgnorePointer>(
            find
                .ancestor(of: weekFinder, matching: find.byType(IgnorePointer))
                .first,
          )
          .ignoring,
      isFalse,
    );
    expect(
        tester.getRect(weekFinder).top, greaterThanOrEqualTo(viewportTop - 1));
    expect(find.text('腿臀 · 核心塑形'), findsOneWidget);
    expect(
      tester.getRect(heroFinder).top,
      greaterThanOrEqualTo(tester.getRect(weekFinder).bottom - 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'NutritionPage horizontal DayPageView switches to yesterday and blocks future swipe',
      (tester) async {
    final thursday = DateTime(2026, 11, 19, 12);
    final yesterday = DateTime(2026, 11, 18, 12);
    await saveMealEntry(
      '${dayKey(yesterday)}|breakfast',
      MealEntry(
        date: dayKey(yesterday),
        meal: 'breakfast',
        actual: '燕麦鸡蛋',
      ),
    );

    await pumpWorkout(tester, NutritionPage(now: () => thursday));
    expect(find.textContaining('今天 · 11月19日 周四'), findsOneWidget);

    // Swiping left cannot navigate into future beyond today.
    await tester.drag(find.byType(DayPageView), const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('今天 · 11月19日 周四'), findsOneWidget);
    expect(find.text('燕麦鸡蛋'), findsNothing);

    // Swiping right smoothly moves to yesterday and shows its meal.
    await tester.drag(find.byType(DayPageView), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('11月18日 周三'), findsOneWidget);
    expect(find.text('燕麦鸡蛋'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'future-date preview works via next arrow and survives tab visibility toggle',
      (tester) async {
    final wednesday = DateTime(2026, 11, 18, 12);
    var visible = true;
    late StateSetter setVisible;

    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: StatefulBuilder(
          builder: (context, setState) {
            setVisible = setState;
            return TickerMode(
              enabled: visible,
              child: Scaffold(body: WorkoutPage(now: () => wednesday)),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // '>' next-date arrow steps into tomorrow's future preview.
    final nextBtn = find.byKey(const Key('next-date'));
    expect(tester.widget<IconButton>(nextBtn).onPressed, isNotNull);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    expect(find.text('未来日期预览'), findsOneWidget);
    expect(find.text('上肢 · 轮廓与代谢'), findsOneWidget);

    // Switching tab away and back keeps the chosen future date intact.
    setVisible(() => visible = false);
    await tester.pump();
    setVisible(() => visible = true);
    await tester.pumpAndSettle();

    expect(find.text('未来日期预览'), findsOneWidget);
    expect(find.text('上肢 · 轮廓与代谢'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unscheduled day displays 未排计划 when empty and 自由训练 with blocks',
      (tester) async {
    final thursday = DateTime(2026, 11, 12, 12);
    await saveWeeklySchedule(['', '', '', '', '', '', '']);

    await pumpWorkout(
      tester,
      WorkoutPage(
          key: const ValueKey('empty-unscheduled'), now: () => thursday),
    );
    expect(find.text('未排计划'), findsOneWidget);

    await saveDailyWorkout(
      DailyWorkout(
        date: dayKey(thursday),
        blocks: [
          WorkoutBlock(
            id: 'free-0',
            exercise: defaultTemplates.first.exercises.first,
          ),
        ],
      ),
    );
    await pumpWorkout(
      tester,
      WorkoutPage(key: const ValueKey('free-unscheduled'), now: () => thursday),
    );
    expect(find.text('自由训练'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'RestTimerPill idle trigger opens sheet and starts timer without shifting layout',
      (tester) async {
    var now = DateTime(2026, 11, 12, 19);
    final controller = RestCountdown(now: () => now);
    addTearDown(controller.dispose);

    await pumpWorkout(
      tester,
      Column(
        children: [
          RestTimerPill(controller: controller),
          const SizedBox(key: Key('anchor-below'), width: 200, height: 60),
        ],
      ),
    );

    final pillFinder = find.byKey(const Key('rest-timer-pill'));
    final anchorFinder = find.byKey(const Key('anchor-below'));
    final pillBefore = tester.getRect(pillFinder);
    final anchorBefore = tester.getRect(anchorFinder);

    await tester.tap(find.byKey(const Key('rest-timer-idle-btn')));
    await tester.pumpAndSettle();
    expect(find.text('组间休息计时'), findsOneWidget);
    expect(find.text('开始 60 秒'), findsOneWidget);

    await tester.tap(find.text('开始 60 秒'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rest-timer-panel')), findsOneWidget);
    expect(find.text('1:00'), findsOneWidget);
    expect(tester.getRect(pillFinder), pillBefore);
    expect(tester.getRect(anchorFinder), anchorBefore);

    controller.stop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'WorkoutPage HeroCard & blocks fit 320x568 @ 2.0x across future, rested, and >6-set states',
      (tester) async {
    final thursday = DateTime(2026, 11, 19, 12);
    await saveDailyWorkout(
      DailyWorkout(
        date: dayKey(thursday),
        blocks: [
          WorkoutBlock(
            id: 'many-sets',
            exercise: defaultTemplates.first.exercises.first.copyWith(sets: 8),
            completedSets: 4,
          ),
        ],
      ),
    );
    await saveDailyWorkout(
      const DailyWorkout(date: '2026-11-18', rested: true),
    );

    await pumpWorkout(
      tester,
      WorkoutPage(now: () => thursday),
      theme: AppTheme.green,
      size: const Size(320, 568),
      scale: 2.0,
    );
    expect(tester.takeException(), isNull);

    // Future date preview pill ('未来日期预览') at 320x568 @ 2.0x.
    await tester.tap(find.byKey(const Key('next-date')));
    await tester.pumpAndSettle();
    expect(find.text('未来日期预览'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Rested state ('今日休整') at 320x568 @ 2.0x.
    await tester.tap(find.byKey(const Key('return-today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('previous-date')));
    await tester.pumpAndSettle();
    expect(find.text('今日休整'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeekStripBar slides selection smoothly between days',
      (tester) async {
    var selected = DateTime(2026, 11, 18); // Wednesday
    final today = DateTime(2026, 11, 19); // Thursday
    late StateSetter rebuild;

    await pumpWorkout(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return WeekStripBar(
            date: selected,
            today: today,
            allowFutureSelection: true,
            statusForDay: (_) => DayStripStatus.planned,
            onChanged: (d) => setState(() => selected = d),
          );
        },
      ),
    );

    final wedRect =
        tester.getRect(find.byKey(const ValueKey('week-strip-day-2')));
    await tester.tap(find.byKey(const ValueKey('week-strip-day-0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(selected, DateTime(2026, 11, 16));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('week-strip-day-2'))).height,
      closeTo(wedRect.height, 0.01),
    );

    // Jumping across week boundary resets cleanly without errors.
    rebuild(() => selected = DateTime(2026, 11, 10));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'HorizontalDaySwipe tracks finger drag smoothly and glides on switch',
      (tester) async {
    var day = 18;
    await pumpWorkout(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 390,
          height: 300,
          child: HorizontalDaySwipe(
            onPrevious: () => setState(() => day--),
            onNext: () => setState(() => day++),
            child: Center(child: Text('Day $day')),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(260, 150));
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    // Follows finger smoothly with rubber-band damping before release.
    expect(tester.getCenter(find.text('Day 18')).dx, lessThan(195));

    await gesture.moveBy(const Offset(-70, 0));
    await gesture.up();
    await tester.pump();
    expect(find.text('Day 19'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Day 19')).dx, closeTo(195, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('QingranBrandMark renders cleanly across light and dark themes',
      (tester) async {
    for (final mode in [AppTheme.blue, AppTheme.green]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: RecompApp.themeFor(mode),
          home: const Scaffold(body: Center(child: QingranBrandMark())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QingranBrandMark), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('TemplateManagerPage resets schedule to Mon-Thu 4-day preset',
      (tester) async {
    await saveWeeklySchedule(['', '', '', '', 'cardio', 'cardio', 'recovery']);

    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: const TemplateManagerPage(),
      ),
    );
    await tester.pumpAndSettle();

    final resetBtn = find.byKey(const Key('reset-default-templates'));
    await tester.scrollUntilVisible(
      resetBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(resetBtn);
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    expect(find.text('恢复默认 4 练课表？'), findsOneWidget);
    await tester.tap(find.text('恢复默认'));
    await tester.pumpAndSettle();

    expect(await loadWeeklySchedule(), defaultSchedule);
    expect(tester.takeException(), isNull);
  });
}
