import 'package:body_recomp/main.dart';
import 'package:body_recomp/models/recomp_models.dart';
import 'package:body_recomp/widgets/muscle_body_graphic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exercise ex(
    String name, {
    List<String> muscles = const [],
    String target = '',
  }) =>
      Exercise(
        name: name,
        muscles: muscles,
        muscleTarget: target,
        sets: 4,
        reps: '10-12',
        rest: '60s',
      );

  group('inferMuscleGroups', () {
    test('bicep curls map to arms only and never falsely match legs', () {
      expect(inferMuscleGroups([ex('哑铃弯举')]), {'arms'});
      expect(inferMuscleGroups([ex('哑铃交替弯举')]), {'arms'});
      expect(inferMuscleGroups([ex('哑铃锤式弯举')]), {'arms'});
      expect(
        inferMuscleGroups([
          ex('哑铃交替弯举', muscles: const ['肱二头'])
        ]),
        {'arms'},
      );
    });

    test('leg curls map to legs only and never falsely match arms', () {
      expect(inferMuscleGroups([ex('俯卧腿弯举')]), {'legs'});
      expect(inferMuscleGroups([ex('坐姿腿弯举')]), {'legs'});
      expect(inferMuscleGroups([ex('Seated Leg Curl')]), {'legs'});
    });

    test('leg raises map to core only and never falsely match legs', () {
      expect(inferMuscleGroups([ex('仰卧举腿')]), {'core'});
      expect(inferMuscleGroups([ex('悬垂举腿')]), {'core'});
      expect(inferMuscleGroups([ex('Hanging Leg Raises')]), {'core'});
    });

    test('single-arm row and straight-arm pulldown map to back, not arms', () {
      expect(inferMuscleGroups([ex('单臂哑铃划船')]), {'back'});
      expect(inferMuscleGroups([ex('直臂下压')]), {'back'});
    });

    test('rowing machine maps to cardio, not back', () {
      expect(inferMuscleGroups([ex('划船机')]), {'cardio'});
      expect(inferMuscleGroups([ex('Rowing Machine')]), {'cardio'});
    });

    test('reverse fly maps to shoulders and ASCII uses word boundaries', () {
      expect(inferMuscleGroups([ex('蝴蝶机反向飞鸟')]), contains('shoulders'));
      // "warm" contains "arm", "plate" contains "lat" — neither should match.
      expect(inferMuscleGroups([ex('Warm Plate Prep')]), isEmpty);
    });

    test('explicit muscle tags take precedence and fallback works for 其他', () {
      expect(
        inferMuscleGroups([
          ex('自定义动作', muscles: const ['胸部', '肩部'])
        ]),
        {'chest', 'shoulders'},
      );
      expect(
        inferMuscleGroups([
          ex('哑铃侧平举', muscles: const ['其他'])
        ]),
        {'shoulders'},
      );
    });
  });

  testWidgets('MuscleBodyGraphic renders across themes, empty & cardio states',
      (tester) async {
    for (final mode in [AppTheme.blue, AppTheme.green, AppTheme.pink]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: RecompApp.themeFor(mode),
          home: const Scaffold(
            body: Row(
              children: [
                MuscleBodyGraphic(activeGroups: {}),
                MuscleBodyGraphic(
                  activeGroups: {
                    'chest',
                    'back',
                    'shoulders',
                    'arms',
                    'core',
                    'legs',
                    'cardio',
                  },
                ),
                MuscleBodyGraphic(
                  activeGroups: {'chest'},
                  size: 48,
                  showHalo: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'theme ${mode.name}');
    }
  });
}
