import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/main.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/pages/workout_page.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:body_recomp/services/rest_countdown.dart';
import 'package:body_recomp/widgets/rest_timer_pill.dart';
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
    // Saturday 2026-11-14 loads the built-in cardio template whose first block
    // ('爬坡快走') includes a coaching note.
    final saturday = DateTime(2026, 11, 14, 12);
    await pumpWorkout(tester, WorkoutPage(now: () => saturday));

    const expectedNote = '参考坡度 8–12，速度 4.5–5.0 km/h；不慢跑。';
    expect(find.text(expectedNote), findsNothing);

    await tester.tap(find.text('爬坡快走'));
    await tester.pumpAndSettle();
    expect(find.text(expectedNote), findsOneWidget);

    // Still unmaterialized (preview mode) until the user logs or edits.
    expect((await loadDailyWorkouts())[dayKey(saturday)], isNull);
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
      '_SliverClipOverlap blocks bleed-through taps on scrolled-under controls',
      (tester) async {
    final today = DateTime(2026, 11, 12, 12);
    await saveDailyWorkout(
      DailyWorkout(
        date: dayKey(today),
        blocks: [
          for (var i = 0; i < 6; i++)
            WorkoutBlock(
              id: 'b-$i',
              exercise: defaultTemplates.first.exercises.first
                  .copyWith(name: '动作 $i'),
            ),
        ],
      ),
    );
    await pumpWorkout(
      tester,
      WorkoutPage(now: () => today),
      size: const Size(390, 620),
    );

    // Scroll so block-0's complete-set-0 moves directly behind the pinned
    // HeroCard while still mounted in the sliver list.
    final scrollFinder = find.byType(CustomScrollView);
    final heroFinder = find.byKey(const Key('daily-suggestion'));
    final block0SetFinder = find.byKey(const ValueKey('complete-set-0'));
    final scrollTop = tester.getRect(scrollFinder).top;
    final heroHeight = tester.getRect(heroFinder).height;
    final setCenterBefore = tester.getCenter(block0SetFinder).dy;
    final targetY = scrollTop + heroHeight * 0.55;
    final dragDelta = setCenterBefore - targetY + 18.0; // +18 touch slop

    await tester.drag(scrollFinder, Offset(0, -dragDelta));
    await tester.pumpAndSettle();

    final heroRect = tester.getRect(heroFinder);
    expect(block0SetFinder.evaluate(), isNotEmpty);
    final clippedSetCenter = tester.getCenter(block0SetFinder);
    expect(heroRect.contains(clippedSetCenter), isTrue);

    // Tapping right over the scrolled-under complete-set button must NOT log a set.
    await tester.tapAt(clippedSetCenter);
    await tester.pumpAndSettle();

    final session = (await loadDailyWorkouts())[dayKey(today)]!;
    expect(session.completedSets, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'future-date preview works via next arrow and survives tab visibility toggle',
      (tester) async {
    final thursday = DateTime(2026, 11, 19, 12);
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
              child: Scaffold(body: WorkoutPage(now: () => thursday)),
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
    expect(find.text('上肢 · 泵感与手臂'), findsOneWidget);

    // Switching tab away and back keeps the chosen future date intact.
    setVisible(() => visible = false);
    await tester.pump();
    setVisible(() => visible = true);
    await tester.pumpAndSettle();

    expect(find.text('未来日期预览'), findsOneWidget);
    expect(find.text('上肢 · 泵感与手臂'), findsOneWidget);
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
}
