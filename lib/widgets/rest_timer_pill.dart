import 'package:flutter/material.dart';
import '../services/rest_countdown.dart';

/// A stable header control. Ticks rebuild this pill, never the workout list.
class RestTimerPill extends StatelessWidget {
  final RestCountdown controller;
  const RestTimerPill({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: SizedBox(
            key: const Key('rest-timer-pill'),
            width: 174,
            height: 40,
            child: ValueListenableBuilder<RestCountdownState?>(
                valueListenable: controller,
                builder: (context, state, _) {
                  final active = state != null;
                  final finished = state?.remaining == 0;
                  final ink = active
                      ? colors.primary
                      : colors.onSurface.withValues(alpha: .5);
                  return Material(
                      color:
                          colors.primary.withValues(alpha: active ? .1 : .045),
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: state == null
                          ? InkWell(
                              key: const Key('quick-rest-90'),
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => controller.start(90, '自由休息'),
                              child: Row(
                                  key: const Key('rest-timer-idle'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: 16, color: ink),
                                    const SizedBox(width: 7),
                                    Flexible(
                                        child: Text('休息 90秒',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: ink))),
                                    const SizedBox(width: 8),
                                    Icon(Icons.add_rounded,
                                        size: 15, color: ink),
                                  ]))
                          : Padding(
                              padding:
                                  const EdgeInsets.only(left: 11, right: 3),
                              child: Row(
                                  key: const Key('rest-timer-panel'),
                                  children: [
                                    Tooltip(
                                        message:
                                            '${state.label}${finished ? ' · 休息结束' : ''}',
                                        child: SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: finished
                                                ? Icon(Icons.check_rounded,
                                                    size: 15, color: ink)
                                                : CircularProgressIndicator(
                                                    value: (state.remaining /
                                                            state.total)
                                                        .clamp(0, 1),
                                                    strokeWidth: 2,
                                                    color: ink,
                                                    backgroundColor:
                                                        ink.withValues(
                                                            alpha: .15)))),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Semantics(
                                            label: finished
                                                ? '休息结束'
                                                : '剩余 ${state.remaining} 秒',
                                            child: Text(
                                                finished
                                                    ? '休息结束'
                                                    : '${state.remaining ~/ 60}:${(state.remaining % 60).toString().padLeft(2, '0')}',
                                                maxLines: 1,
                                                style: TextStyle(
                                                    fontSize:
                                                        finished ? 10 : 13,
                                                    color: ink,
                                                    fontWeight: FontWeight.w700,
                                                    fontFeatures: const [
                                                      FontFeature
                                                          .tabularFigures()
                                                    ])))),
                                    SizedBox(
                                        width: 42,
                                        height: 40,
                                        child: TextButton(
                                            key: const Key('rest-timer-add'),
                                            style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20))),
                                            onPressed: () =>
                                                controller.addSeconds(30),
                                            child: const Text('+30',
                                                style:
                                                    TextStyle(fontSize: 10)))),
                                    SizedBox(
                                        width: 32,
                                        height: 40,
                                        child: IconButton(
                                            key:
                                                const Key('rest-timer-dismiss'),
                                            padding: EdgeInsets.zero,
                                            tooltip: '结束计时',
                                            onPressed: controller.stop,
                                            icon: Icon(Icons.close_rounded,
                                                size: 16, color: ink))),
                                  ])));
                })));
  }
}
