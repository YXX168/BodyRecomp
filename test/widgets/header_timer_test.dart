import 'dart:ui' as ui;
import 'package:body_recomp/main.dart';
import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/services/daily_workout_service.dart';
import 'package:body_recomp/widgets/rest_timer_pill.dart';
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
    await tester.tap(find.byKey(const Key('quick-rest-90')));
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
    await tester.pumpAndSettle();
    expect(tester.getRect(block), cardBefore);
    expect((await loadDailyWorkouts()).values.single.completedSets, 0);
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
