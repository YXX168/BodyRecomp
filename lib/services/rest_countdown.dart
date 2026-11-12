import 'dart:async';
import 'package:flutter/foundation.dart';
import 'rest_timer_service.dart';

class RestCountdownState {
  final DateTime deadline;
  final String label;
  final int remaining;
  final int total;
  const RestCountdownState(
      {required this.deadline,
      required this.label,
      required this.remaining,
      required this.total});
}

/// Only the header pill listens to ticks; exercise cards keep their layout and state.
class RestCountdown extends ValueNotifier<RestCountdownState?> {
  final DateTime Function() now;
  final VoidCallback? onFinished;
  Timer? _ticker;
  bool _active = true;
  RestCountdown({required this.now, this.onFinished}) : super(null);

  void start(int seconds, String label) {
    _ticker?.cancel();
    value = RestCountdownState(
        deadline: now().add(Duration(seconds: seconds)),
        label: label,
        remaining: seconds,
        total: seconds);
    _run();
  }

  void addSeconds(int seconds) {
    final previous = value;
    if (previous == null) return;
    final current = now();
    final wasExpired = !previous.deadline.isAfter(current);
    final deadline = (wasExpired ? current : previous.deadline)
        .add(Duration(seconds: seconds));
    value = RestCountdownState(
        deadline: deadline,
        label: previous.label,
        remaining: restSecondsUntil(deadline, now: current),
        total: wasExpired ? seconds : previous.total + seconds);
    _run();
  }

  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (active) {
      refresh();
      _run();
    } else {
      _ticker?.cancel();
    }
  }

  void refresh() {
    final previous = value;
    if (!_active || previous == null) return;
    final remaining = restSecondsUntil(previous.deadline, now: now());
    if (remaining == previous.remaining) return;
    value = RestCountdownState(
        deadline: previous.deadline,
        label: previous.label,
        remaining: remaining,
        total: previous.total);
    if (remaining == 0) {
      _ticker?.cancel();
      onFinished?.call();
    }
  }

  void _run() {
    _ticker?.cancel();
    if (_active && (value?.remaining ?? 0) > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
    }
  }

  void stop() {
    _ticker?.cancel();
    value = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
