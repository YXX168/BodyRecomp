import 'package:body_recomp/data/exercise_library.dart';
import 'package:body_recomp/data/workout_templates.dart';
import 'package:body_recomp/models/daily_workout.dart';
import 'package:body_recomp/models/recomp_models.dart';
import 'package:body_recomp/widgets/exercise_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester,
      {List<WorkoutTemplate> templates = defaultTemplates,
      void Function(List<Exercise>?)? result}) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () async {
                      final values = await pickExercises(context, templates);
                      result?.call(values);
                    },
                    child: const Text('选动作'))))));
    await tester.tap(find.text('选动作'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'select all toggles the current category and keeps other selections',
      (tester) async {
    List<Exercise>? result;
    await open(tester, result: (values) => result = values);
    await tap(tester, 'picker-template-pull');
    await tap(tester, 'pick_1_0');
    await tap(tester, 'picker-template-push');
    await tap(tester, 'toggle-visible-selection');
    expect(find.text('6 项已选'), findsOneWidget);
    expect(find.text('取消全选'), findsOneWidget);
    await tap(tester, 'toggle-visible-selection');
    expect(find.text('1 项已选'), findsOneWidget);
    expect(find.text('全选'), findsOneWidget);
    await tap(tester, 'add-picked-exercises');
    expect(result!.map((e) => e.name), ['宽握高位下拉']);
  });

  testWidgets(
      'search all and cancel preserve unrelated choices, clear removes everything',
      (tester) async {
    await open(tester);
    await tap(tester, 'pick_0_0');
    await tester.enterText(find.byKey(const Key('exercise-search')), '弯举');
    await tester.pumpAndSettle();
    await tap(tester, 'toggle-visible-selection');
    expect(find.text('取消全选'), findsOneWidget);
    await tap(tester, 'toggle-visible-selection');
    expect(find.text('1 项已选'), findsOneWidget);
    await tap(tester, 'clear-exercise-search');
    await tap(tester, 'clear-picked-exercises');
    expect(find.text('0 项已选'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('add-picked-exercises')))
            .onPressed,
        isNull);
  });

  testWidgets(
      'category switching resets scroll without losing other-category choices',
      (tester) async {
    List<Exercise>? result;
    await open(tester, result: (values) => result = values);
    await tap(tester, 'picker-source-1');
    await tap(tester, 'pick-library_chest-1');
    await tester.drag(find.byKey(const ValueKey('picker-exercise-grid')),
        const Offset(0, -500));
    await tester.pumpAndSettle();
    await tap(tester, 'picker-template-library_back');
    expect(find.byKey(const ValueKey('pick-library_back-0')), findsOneWidget);
    final scrollable = find.descendant(
        of: find.byKey(const ValueKey('picker-exercise-grid')),
        matching: find.byType(Scrollable));
    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
    await tester
        .tap(find.byKey(const ValueKey('picker-template-library_chest')));
    await tester.pump(const Duration(milliseconds: 40));
    await tester
        .tap(find.byKey(const ValueKey('picker-template-library_back')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    await tap(tester, 'pick-library_back-0');
    await tap(tester, 'add-picked-exercises');
    expect(result!.map((e) => e.name), ['哑铃平板卧推', '宽握高位下拉']);
  });

  testWidgets(
      'library is available without saved templates and cancel does not add anything',
      (tester) async {
    var finished = false;
    List<Exercise>? result;
    await open(tester, templates: [], result: (values) {
      finished = true;
      result = values;
    });
    expect(libraryExerciseCount, 52);
    await tap(tester, 'toggle-visible-selection');
    expect(find.text('8 项已选'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
    expect(result, isNull);
  });

  testWidgets(
      'search keeps different prescriptions and shares identical selections',
      (tester) async {
    final exercise = defaultTemplates.first.exercises.first;
    await open(tester, templates: [
      WorkoutTemplate(id: 'a', name: 'A', exercises: [exercise]),
      WorkoutTemplate(
          id: 'b',
          name: 'B',
          exercises: [exercise, exercise.copyWith(sets: 7)]),
    ]);
    await tap(tester, 'pick_0_0');
    await tap(tester, 'picker-template-b');
    expect(find.text('1 项已选'), findsOneWidget);
    final first = tester.widget<Semantics>(find
        .ancestor(
            of: find.byKey(const ValueKey('pick_1_0')),
            matching: find.byType(Semantics))
        .first);
    expect(first.properties.selected, isTrue);
    await tester.enterText(
        find.byKey(const Key('exercise-search')), exercise.name);
    await tester.pumpAndSettle();
    expect(find.text('7 组 × ${exercise.reps}'), findsOneWidget);
    expect(find.byKey(const ValueKey('pick_1_0')), findsNothing);
    await tap(tester, 'pick_1_1');
    expect(find.text('2 项已选'), findsOneWidget);
  });
}
