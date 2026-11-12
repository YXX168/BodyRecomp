import 'package:flutter/material.dart';
import '../services/rest_countdown.dart';

class RestTimerDock extends StatelessWidget {
  final RestCountdown controller;
  const RestTimerDock({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .48);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return SizedBox(
        key: const Key('rest-timer-dock'),
        height: 68 + (scale - 1) * 14,
        child: ValueListenableBuilder<RestCountdownState?>(
          valueListenable: controller,
          builder: (context, state, _) => Material(
              color: colors.surface,
              child: Column(children: [
                SizedBox(
                    height: 2,
                    child: state == null
                        ? ColoredBox(
                            color: colors.onSurface.withValues(alpha: .05))
                        : LinearProgressIndicator(
                            value: (state.remaining / state.total).clamp(0, 1),
                            minHeight: 2,
                            color: colors.primary,
                            backgroundColor:
                                colors.primary.withValues(alpha: .08))),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 10, 6),
                        child: Row(
                            key: state == null
                                ? const Key('rest-timer-idle')
                                : const Key('rest-timer-panel'),
                            children: [
                              Icon(
                                  state?.remaining == 0
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.timer_outlined,
                                  size: 21,
                                  color:
                                      state == null ? muted : colors.primary),
                              const SizedBox(width: 11),
                              Expanded(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        state == null
                                            ? '组间休息'
                                            : state.remaining == 0
                                                ? '休息结束'
                                                : '${state.remaining ~/ 60}:${(state.remaining % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                            fontSize: state == null ? 12 : 19,
                                            height: 1.1,
                                            fontWeight: FontWeight.w600,
                                            color: colors.onSurface)),
                                    const SizedBox(height: 4),
                                    Text(state?.label ?? '点动作旁的计时按钮，按需开始',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 9, color: muted)),
                                  ])),
                              if (state == null)
                                TextButton(
                                    key: const Key('quick-rest-90'),
                                    onPressed: () =>
                                        controller.start(90, '自由休息'),
                                    child: const Text('90 秒',
                                        style: TextStyle(fontSize: 11))),
                              if (state != null) ...[
                                TextButton(
                                    key: const Key('rest-timer-add'),
                                    onPressed: () => controller.addSeconds(30),
                                    child: const Text('+30秒',
                                        style: TextStyle(fontSize: 11))),
                                IconButton(
                                    key: const Key('rest-timer-dismiss'),
                                    tooltip: '结束计时',
                                    onPressed: controller.stop,
                                    icon: Icon(Icons.close_rounded,
                                        size: 18, color: muted)),
                              ],
                            ]))),
              ])),
        ));
  }
}
