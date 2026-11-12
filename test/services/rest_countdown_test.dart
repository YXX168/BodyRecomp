import 'package:body_recomp/services/rest_countdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('countdown extends the real deadline and can be stopped',
      (tester) async {
    var now = DateTime(2026, 11, 12, 20);
    final timer = RestCountdown(now: () => now);
    addTearDown(timer.dispose);
    timer.start(90, '卧推');
    now = now.add(const Duration(seconds: 40));
    await tester.pump(const Duration(seconds: 1));
    expect(timer.value!.remaining, 50);
    timer.addSeconds(30);
    expect(timer.value!.remaining, 80);
    expect(timer.value!.total, 120);
    timer.stop();
    expect(timer.value, isNull);
  });

  testWidgets('hidden timer catches up once and restarts cleanly after expiry',
      (tester) async {
    var now = DateTime(2026, 11, 12, 20);
    var finished = 0;
    final timer = RestCountdown(now: () => now, onFinished: () => finished++);
    addTearDown(timer.dispose);
    timer.start(60, '侧平举');
    timer.setActive(false);
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(timer.value!.remaining, 60);
    timer.setActive(true);
    expect(timer.value!.remaining, 0);
    expect(finished, 1);
    timer.refresh();
    expect(finished, 1);
    timer.addSeconds(30);
    expect(timer.value!.remaining, 30);
    expect(timer.value!.total, 30);
    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));
    expect(timer.value!.remaining, 0);
    expect(finished, 2);
  });

  testWidgets('starting another exercise replaces the previous timer',
      (tester) async {
    var now = DateTime(2026, 11, 12, 20);
    final timer = RestCountdown(now: () => now);
    addTearDown(timer.dispose);
    timer.start(60, '旧动作');
    now = now.add(const Duration(seconds: 20));
    timer.start(90, '新动作');
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(timer.value!.label, '新动作');
    expect(timer.value!.remaining, 60);
    timer.stop();
  });
}
