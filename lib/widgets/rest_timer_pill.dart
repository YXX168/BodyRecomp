import 'package:flutter/material.dart';
import '../services/rest_countdown.dart';

/// The header keeps its height while only the running pill fades in or out.
class RestTimerPill extends StatelessWidget {
  final RestCountdown controller;
  const RestTimerPill({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: SizedBox(
            key: const Key('rest-timer-pill'),
            width: 174,
            height: 40,
            child: ValueListenableBuilder<RestCountdownState?>(
                valueListenable: controller,
                builder: (context, state, _) {
                  final running = state != null && state.remaining > 0;
                  return ExcludeSemantics(
                      excluding: !running,
                      child: IgnorePointer(
                          ignoring: !running,
                          child: AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              reverseDuration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                          alignment: Alignment.centerRight,
                                          scale:
                                              Tween<double>(begin: .94, end: 1)
                                                  .animate(animation),
                                          child: child)),
                              child: running
                                  ? _TimerFace(
                                      key: const ValueKey('running'),
                                      controller: controller,
                                      state: state)
                                  : const SizedBox.shrink(
                                      key: ValueKey('hidden')))));
                })));
  }
}

class _TimerFace extends StatelessWidget {
  final RestCountdown controller;
  final RestCountdownState state;
  const _TimerFace({super.key, required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = colors.primary;
    return Material(
        color: ink.withValues(alpha: .1),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Padding(
            padding: const EdgeInsets.only(left: 11, right: 3),
            child: Row(key: const Key('rest-timer-panel'), children: [
              Tooltip(
                  message: state.label,
                  child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          value: (state.remaining / state.total).clamp(0, 1),
                          strokeWidth: 2,
                          color: ink,
                          backgroundColor: ink.withValues(alpha: .15)))),
              const SizedBox(width: 6),
              Expanded(
                  child: Semantics(
                      label: '剩余 ${state.remaining} 秒',
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                              '${state.remaining ~/ 60}:${(state.remaining % 60).toString().padLeft(2, '0')}',
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ]))))),
              SizedBox(
                  width: 42,
                  height: 40,
                  child: TextButton(
                      key: const Key('rest-timer-add'),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      onPressed: () => controller.addSeconds(30),
                      child:
                          const Text('+30', style: TextStyle(fontSize: 10)))),
              SizedBox(
                  width: 32,
                  height: 40,
                  child: IconButton(
                      key: const Key('rest-timer-dismiss'),
                      padding: EdgeInsets.zero,
                      tooltip: '结束计时',
                      onPressed: controller.stop,
                      icon: Icon(Icons.close_rounded, size: 16, color: ink))),
            ])));
  }
}
