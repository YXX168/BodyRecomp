import 'package:body_recomp/main.dart';
import 'package:body_recomp/pages/workout_page.dart';
import 'package:body_recomp/pages/nutrition_page.dart';
import 'package:body_recomp/widgets/daily_date_bar.dart';
import 'package:body_recomp/widgets/body_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final nutrition in [false, true]) {
    for (final history in [false, true]) {
      testWidgets(
          '${nutrition ? "nutrition" : "training"} keeps date intent across midnight (history=$history)',
          (tester) async {
        var now = DateTime(2026, 11, 12, 23, 59);
        var visible = true;
        late StateSetter update;
        await tester.pumpWidget(
            MaterialApp(home: StatefulBuilder(builder: (context, set) {
          update = set;
          return TickerMode(
              enabled: visible,
              child: Scaffold(
                  body: nutrition
                      ? NutritionPage(now: () => now)
                      : WorkoutPage(now: () => now)));
        })));
        await tester.pumpAndSettle();
        if (history) {
          await tester.tap(find.byKey(const Key('previous-date')));
          await tester.pumpAndSettle();
        }
        update(() => visible = false);
        await tester.pump();
        now = DateTime(2026, 11, 13, 0, 1);
        update(() => visible = true);
        await tester.pumpAndSettle();
        expect(tester.widget<DailyDateBar>(find.byType(DailyDateBar)).date,
            DateTime(2026, 11, history ? 11 : 13));
      });
    }
  }

  testWidgets('all main cards support small screens and double text size',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ThemeState(child: RecompApp()));
    await tester.pumpAndSettle();
    for (final tab in [0, 1, 2, 3]) {
      await tester.tap(find.byKey(ValueKey('nav-$tab')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
  });

  testWidgets('body editor remains reachable in landscape with keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
        theme: RecompApp.themeFor(AppTheme.blue),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => editBodyValues(context,
                        title: '记录围度',
                        fields: const {'waist': '腰围 · cm'},
                        initial: const {}),
                    child: const Text('记录'))))));
    await tester.tap(find.text('记录'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('body-value-waist'));
    await tester.enterText(field, '8');
    final editingState =
        tester.state<EditableTextState>(find.byType(EditableText));
    tester.view.viewInsets = const FakeViewPadding(bottom: 160);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.state<EditableTextState>(find.byType(EditableText)),
        same(editingState));
    expect(tester.widget<TextFormField>(field).controller!.text, '8');
    await tester.ensureVisible(find.byKey(const ValueKey('body-value-waist')));
    await tester.enterText(
        find.byKey(const ValueKey('body-value-waist')), '80');
    await tester.ensureVisible(find.byKey(const Key('save-body-values')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-body-values')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save-body-values')), findsNothing);
  });
}
