import 'package:body_recomp/widgets/horizontal_day_swipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testApp({VoidCallback? onPrevious, VoidCallback? onNext}) {
    return MaterialApp(
      home: Scaffold(
        body: HorizontalDaySwipe(
          onPrevious: onPrevious,
          onNext: onNext,
          child: const SizedBox.expand(child: Text('训练日')),
        ),
      ),
    );
  }

  testWidgets('left swipe selects the next day', (tester) async {
    var nextCount = 0;
    var previousCount = 0;
    await tester.pumpWidget(
      testApp(onNext: () => nextCount++, onPrevious: () => previousCount++),
    );

    await tester.drag(find.text('训练日'), const Offset(-100, 0));
    await tester.pump();

    expect(nextCount, 1);
    expect(previousCount, 0);
  });

  testWidgets('right swipe selects the previous day', (tester) async {
    var nextCount = 0;
    var previousCount = 0;
    await tester.pumpWidget(
      testApp(onNext: () => nextCount++, onPrevious: () => previousCount++),
    );

    await tester.drag(find.text('训练日'), const Offset(100, 0));
    await tester.pump();

    expect(previousCount, 1);
    expect(nextCount, 0);
  });

  testWidgets('drag below threshold does not change day', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      testApp(onNext: () => changes++, onPrevious: () => changes++),
    );

    await tester.drag(find.text('训练日'), const Offset(30, 0));
    await tester.pump();

    expect(changes, 0);
  });
}
