import 'package:body_recomp/main.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/pages/template_manager_page.dart';
import 'package:body_recomp/pages/workout_page.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:body_recomp/services/exercise_library_service.dart';
import 'package:body_recomp/widgets/app_navigation_bar.dart';
import 'package:body_recomp/widgets/muscle_body_graphic.dart';
import 'package:body_recomp/widgets/week_strip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> tapVisible(WidgetTester tester, Finder finder,
      {Finder? scrollable}) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        180,
        scrollable: scrollable ?? find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('future weekday preview is read-only and blocks打卡',
      (tester) async {
    // 2026-11-19 is Thursday; Friday 2026-11-20 is future in same week
    final thursday = DateTime(2026, 11, 19, 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: Scaffold(body: WorkoutPage(now: () => thursday)),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Friday (index 4) on WeekStripBar
    await tester.tap(find.byKey(const ValueKey('week-strip-day-4')));
    await tester.pumpAndSettle();

    expect(find.textContaining('未来日期预览'), findsOneWidget);
    expect(find.text('上肢 · 泵感与手臂'), findsOneWidget);
    expect(find.byKey(const ValueKey('complete-set-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'plan hub allows deleting template cleanly with schedule cleanup and undo',
      (tester) async {
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();

    // Go to Templates tab (nav-1)
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();

    // Delete 'push' template (bound to Monday)
    final templateScroll = find
        .descendant(
          of: find.byType(WeeklyTemplatesView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tapVisible(
      tester,
      find.byKey(const ValueKey('template-menu-push')),
      scrollable: templateScroll,
    );
    await tester.tap(find.text('删除模板'));
    await tester.pumpAndSettle();
    expect(find.textContaining('周一'), findsWidgets);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect((await loadWorkoutTemplates()).any((t) => t.id == 'push'), isFalse);
    expect((await loadWeeklySchedule())[0], '');

    // Undo restores both template and Monday binding
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect((await loadWorkoutTemplates()).any((t) => t.id == 'push'), isTrue);
    expect((await loadWeeklySchedule())[0], 'push');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'exercise library supports adding, filtering, adding to today, and deleting with undo',
      (tester) async {
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();

    // Go directly to Exercise Library tab (nav-2)
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();

    // Add a custom exercise
    await tester.tap(find.byKey(const Key('add-library-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('exercise-name')), '保加利亚分腿蹲');
    await tapVisible(tester, find.byKey(const ValueKey('category-chip-腿臀')));
    await tapVisible(tester, find.byKey(const Key('save-exercise')));

    final items = await loadExerciseLibrary();
    final created = items.firstWhere((e) => e.exercise.name == '保加利亚分腿蹲');
    expect(created.category, '腿臀');

    // Search for it and add to today's workout
    await tester.enterText(find.byKey(const Key('library-search')), '保加利亚');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('add-today-library-${created.id}')));
    await tester.pumpAndSettle();

    final todaySession = (await loadDailyWorkouts())[dayKey(DateTime.now())]!;
    expect(
      todaySession.blocks.any((b) => b.exercise.name == '保加利亚分腿蹲'),
      isTrue,
    );

    // Delete from library with undo
    await tester.tap(find.byKey(ValueKey('delete-library-${created.id}')));
    await tester.pumpAndSettle();
    expect(
      (await loadExerciseLibrary()).any((e) => e.id == created.id),
      isFalse,
    );
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(
      (await loadExerciseLibrary()).any((e) => e.id == created.id),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'logging exercise weight updates workout badge and Trends PR view',
      (tester) async {
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const ValueKey('log-weight-0')));
    await tester.enterText(find.byKey(const Key('weight-log-kg')), '80');
    await tester.tap(find.byKey(const Key('save-weight-log')));
    await tester.pumpAndSettle();

    final logs = await loadExerciseLogs();
    expect(logs, hasLength(1));
    expect(logs.single.weightKg, 80);

    // Navigate to Profile hub (nav-3) -> open Trends -> Strength PR segment
    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('open-trends-btn')));
    await tester.tap(find.byKey(const ValueKey('trends-seg-1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('最佳 PR: 80.0kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'muscle body graphic renders inferred active groups on workout and templates',
      (tester) async {
    final thursday = DateTime(2026, 11, 19, 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: Scaffold(body: WorkoutPage(now: () => thursday)),
      ),
    );
    await tester.pumpAndSettle();

    final workoutGraphic =
        tester.widget<MuscleBodyGraphic>(find.byType(MuscleBodyGraphic));
    expect(workoutGraphic.activeGroups, contains('legs'));
    expect(workoutGraphic.activeGroups, contains('core'));

    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: const TemplateManagerPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('schedule-day-0')));
    await tester.pumpAndSettle();
    var tplGraphic =
        tester.widget<MuscleBodyGraphic>(find.byType(MuscleBodyGraphic));
    expect(tplGraphic.activeGroups, contains('chest'));

    await tester.tap(find.byKey(const ValueKey('schedule-day-1')));
    await tester.pumpAndSettle();
    tplGraphic =
        tester.widget<MuscleBodyGraphic>(find.byType(MuscleBodyGraphic));
    expect(tplGraphic.activeGroups, contains('back'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'workout date bar hides on downward scroll while overview card stays pinned',
      (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final thursday = DateTime(2026, 11, 19, 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: Scaffold(body: WorkoutPage(now: () => thursday)),
      ),
    );
    await tester.pumpAndSettle();

    final scrollFinder = find.byType(CustomScrollView);
    final weekFinder = find.byType(WeekStripBar);
    final heroFinder = find.byKey(const Key('daily-suggestion'));
    final block0Finder = find.byKey(const ValueKey('workout-block-0'));

    final heroBefore = tester.getRect(heroFinder);
    final blockBefore = tester.getRect(block0Finder);

    // Small downward drag moves WeekStripBar, HeroCard and blocks 1:1 together
    // (~30px after 18px touch slop) with zero abrupt height-collapse jump.
    await tester.drag(scrollFinder, const Offset(0, -48));
    await tester.pumpAndSettle();

    final heroMid = tester.getRect(heroFinder);
    final blockMid = tester.getRect(block0Finder);
    final heroDelta = heroBefore.top - heroMid.top;
    final blockDelta = blockBefore.top - blockMid.top;
    expect(heroDelta, inInclusiveRange(18.0, 42.0));
    expect((heroDelta - blockDelta).abs(), lessThan(2.0));
    expect(weekFinder, findsOneWidget);

    // Larger downward drag scrolls WeekStripBar out while HeroCard pins cleanly.
    await tester.drag(scrollFinder, const Offset(0, -240));
    await tester.pumpAndSettle();

    final scrollTop = tester.getRect(scrollFinder).top;
    final heroDocked = tester.getRect(heroFinder);
    expect(heroDocked.top - scrollTop, inInclusiveRange(0.0, 12.0));
    if (weekFinder.evaluate().isNotEmpty) {
      expect(tester.getRect(weekFinder).bottom,
          lessThanOrEqualTo(scrollTop + 4.0));
    }

    // Small upward drag mid-list keeps HeroCard calmly pinned at the top.
    await tester.drag(scrollFinder, const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(heroFinder).top - scrollTop,
      inInclusiveRange(0.0, 12.0),
    );

    // Tapping the pinned HeroCard smoothly scrolls back to reveal WeekStripBar.
    await tester.tap(heroFinder);
    await tester.pumpAndSettle();
    expect(tester.getRect(weekFinder).top, greaterThanOrEqualTo(scrollTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation droplet supports horizontal swipe switching',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();

    final navRect = tester.getRect(find.byType(AppNavigationBar));
    await tester.dragFrom(
      Offset(navRect.left + navRect.width * 0.14, navRect.center.dy),
      Offset(navRect.width * 0.50, 0),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<AppNavigationBar>(find.byType(AppNavigationBar)).index,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });
}
