import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/main.dart';
import 'package:body_recomp/models/recomp_models.dart';
import 'package:body_recomp/pages/nutrition_page.dart';
import 'package:body_recomp/pages/profile_page.dart';
import 'package:body_recomp/pages/template_manager_page.dart';
import 'package:body_recomp/pages/trends_page.dart';
import 'package:body_recomp/services/data_service.dart';
import 'package:body_recomp/widgets/ambient_background.dart';
import 'package:body_recomp/widgets/exercise_picker.dart';
import 'package:body_recomp/widgets/smooth_trend_chart.dart';
import 'package:body_recomp/widgets/text_prompt.dart';
import 'package:body_recomp/widgets/weight_log_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void setCompactDoubleScale(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  group('showGlassMenu, showGlassDialog, showGlassConfirm & promptText', () {
    testWidgets(
        'showGlassMenu dismisses on barrier tap and flips above bottom anchor',
        (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? result = 'sentinel';
      await tester.pumpWidget(
        MaterialApp(
          theme: RecompApp.themeFor(AppTheme.orange),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Builder(
                  builder: (btnCtx) => ElevatedButton(
                    key: const Key('bottom-anchor'),
                    onPressed: () async {
                      result = await showGlassMenu<String>(
                        context: btnCtx,
                        anchorContext: btnCtx,
                        title: '底部菜单',
                        items: const [
                          GlassMenuItem(
                            value: 'a',
                            label: '选项一',
                            icon: Icons.check_rounded,
                          ),
                          GlassMenuItem(
                            value: 'b',
                            label: '选项二',
                            icon: Icons.edit_rounded,
                          ),
                          GlassMenuItem(
                            value: 'c',
                            label: '删除',
                            icon: Icons.delete_outline_rounded,
                            isDanger: true,
                            hasTopDivider: true,
                          ),
                        ],
                      );
                    },
                    child: const Text('打开'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final anchorRect = tester.getRect(find.byKey(const Key('bottom-anchor')));
      await tester.tap(find.byKey(const Key('bottom-anchor')));
      await tester.pumpAndSettle();

      expect(find.text('底部菜单'), findsOneWidget);
      final menuItemRect = tester.getRect(find.text('选项一'));
      // Menu flips above the bottom-edge anchor rather than clipping off-screen.
      expect(menuItemRect.bottom, lessThanOrEqualTo(anchorRect.top));

      // Tapping outside on barrier dismisses and returns null.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('底部菜单'), findsNothing);
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('showGlassMenu scrolls cleanly at 320x568 @ 2.0x textScale',
        (tester) async {
      setCompactDoubleScale(tester);
      int? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: RecompApp.themeFor(AppTheme.pink),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: TextButton(
                  onPressed: () async {
                    picked = await showGlassMenu<int>(
                      context: ctx,
                      title: '长菜单测试',
                      items: [
                        for (var i = 0; i < 12; i++)
                          GlassMenuItem(
                            value: i,
                            label: '操作项目 $i',
                            icon: Icons.star_border_rounded,
                          ),
                      ],
                    );
                  },
                  child: const Text('触发'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('触发'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final lastItem = find.text('操作项目 11');
      await tester.scrollUntilVisible(
        lastItem,
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(lastItem);
      await tester.pumpAndSettle();

      expect(picked, 11);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'showGlassConfirm, showGlassDialog & promptText work at 320x568 @ 2.0x',
        (tester) async {
      setCompactDoubleScale(tester);
      bool? confirmRes;
      String? promptRes;

      await tester.pumpWidget(
        MaterialApp(
          theme: RecompApp.themeFor(AppTheme.purple),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      confirmRes = await showGlassConfirm(
                        context: ctx,
                        title: '删除确认',
                        message: List.filled(14, '较长说明文字用于测试滚动与防溢出。').join(),
                        isDanger: true,
                        confirmLabel: '确认删除',
                      );
                    },
                    child: const Text('确认框'),
                  ),
                  TextButton(
                    onPressed: () async {
                      promptRes = await promptText(
                        ctx,
                        '重命名模板',
                        initial: '',
                        hint: '输入模板名',
                      );
                    },
                    child: const Text('输入框'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test barrier dismiss -> null
      await tester.tap(find.text('确认框'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(confirmRes, isNull);

      // Test explicit confirm -> true
      await tester.tap(find.text('确认框'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();
      expect(confirmRes, isTrue);

      // Test promptText empty validation, error clear, and trimmed return
      await tester.tap(find.text('输入框'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请输入名称'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '  推拉腿模板  ');
      await tester.pumpAndSettle();
      expect(find.text('请输入名称'), findsNothing);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(promptRes, '推拉腿模板');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('all 6 themes render all 4 tabs cleanly at 320x568 @ 2.0x',
      (tester) async {
    setCompactDoubleScale(tester);

    for (final mode in AppTheme.values) {
      final controller = ThemeController(mode);
      await tester.pumpWidget(
        ThemeState(controller: controller, child: const RecompApp()),
      );
      await tester.pumpAndSettle();
      for (final tab in [0, 1, 2, 3]) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'theme ${mode.name} tab $tab',
        );
      }
      controller.dispose();
    }
  });

  testWidgets(
      'TrendsPage renders all 3 segments at 320x568 @ 2.0x, charts latest 24 PRs & blocks future months',
      (tester) async {
    setCompactDoubleScale(tester);

    // Seed 28 rising bench logs so oldest 4 (weight 50..53) must drop off the
    // 24-point chart while newest (weight 77) stays visible.
    final baseDate = DateTime(2026, 9, 1);
    final logs = [
      for (var i = 0; i < 28; i++)
        ExerciseLog(
          exerciseName: '平板卧推',
          date: baseDate.add(Duration(days: i)),
          weightKg: 50.0 + i,
          sets: 4,
          reps: 8,
          rpe: 8,
        ),
    ];
    await saveExerciseLogs(logs);
    await saveWeightEntry(
      WeightEntry(date: DateTime(2026, 11, 10), weightKg: 71.0),
    );
    await saveWeightEntry(
      WeightEntry(date: DateTime(2026, 11, 12), weightKg: 70.4),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.dark),
        home: const Scaffold(body: TrendsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify future month tap is blocked when a future month exists this year.
    final now = DateTime.now();
    if (now.month < 12) {
      final futureMonth = now.month + 1;
      final tile = find.byKey(ValueKey('mini-month-$futureMonth'));
      final listScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(tile, 200, scrollable: listScroll);
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      // Scroll back to top and confirm current month did NOT switch to futureMonth.
      final monthHeader = find.text('${now.year}年 ${now.month}月');
      await tester.scrollUntilVisible(
        monthHeader,
        -250,
        scrollable: listScroll,
      );
      expect(monthHeader, findsOneWidget);
      expect(find.text('${now.year}年 $futureMonth月'), findsNothing);
    }

    // Segment 1: Strength PR shows latest 24 points (drops oldest 4: 50..53kg).
    await tester.tap(find.byKey(const ValueKey('trends-seg-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final chart =
        tester.widget<SmoothTrendChart>(find.byType(SmoothTrendChart));
    expect(chart.points, hasLength(24));
    expect(
      chart.points.first.value,
      closeTo(54.0 * (1 + 8 / 30.0), 0.01),
    );
    expect(
      chart.points.last.value,
      closeTo(77.0 * (1 + 8 / 30.0), 0.01),
    );

    // Segment 2: Body metrics renders cleanly at 2.0x.
    await tester.tap(find.byKey(const ValueKey('trends-seg-2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'NutritionPage info dialog & TemplateEditorPage fit 320x568 @ 2.0x',
      (tester) async {
    setCompactDoubleScale(tester);

    // 1. NutritionPage + glass info dialog with '知道了'
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.green),
        home: Scaffold(body: NutritionPage(now: () => DateTime(2026, 11, 12))),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('营养汇总说明'));
    await tester.pumpAndSettle();
    expect(find.text('知道了'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.text('知道了'), findsNothing);
    expect(tester.takeException(), isNull);

    // 2. TemplateEditorPage
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: TemplateEditorPage(
          template: defaultTemplates.first,
          library: defaultTemplates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ExercisePicker fits 320x568 @ 2.0x without overflow',
      (tester) async {
    setCompactDoubleScale(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.pink),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => pickExercises(ctx, defaultTemplates),
              child: const Text('开选动作'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('开选动作'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('picker-source-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('WeightLogSheet fits 320x568 @ 2.0x and previews live PR',
      (tester) async {
    setCompactDoubleScale(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.pink),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showWeightLogSheet(
                ctx,
                exerciseName: '平板卧推',
                personalRecord: ExerciseLog(
                  exerciseName: '平板卧推',
                  date: DateTime(2026, 11, 1),
                  weightKg: 70,
                  sets: 4,
                  reps: 8,
                ),
              ),
              child: const Text('开负重'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('开负重'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const Key('weight-log-kg')), '85');
    await tester.pumpAndSettle();
    expect(find.text('将刷新该动作个人纪录 (PR)！'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'ProfilePage damaged-profile recovery screen and 力量 PR tile deep-link work at 320x568 @ 2.0x',
      (tester) async {
    setCompactDoubleScale(tester);

    // 1. Corrupt profile key exposes recovery actions without locking user out.
    SharedPreferences.setMockInitialValues({profileKey: '{corrupt-profile'});
    await tester.pumpWidget(
      MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: const Scaffold(body: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('数据备份'), findsOneWidget);
    expect(find.text('查看原数据'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    await tester.tap(find.text('数据备份'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-json-btn')), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 2. Clean profile: 力量 PR tile deep-links straight to TrendsPage segment 1.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();

    final prTile = find.byKey(const Key('hub-strength-tile'));
    await tester.scrollUntilVisible(
      prTile,
      180,
      scrollable: find
          .descendant(
            of: find.byType(ProfilePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(prTile);
    await tester.pumpAndSettle();
    await tester.tap(prTile);
    await tester.pumpAndSettle();

    expect(find.text('力量进阶与 PR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
