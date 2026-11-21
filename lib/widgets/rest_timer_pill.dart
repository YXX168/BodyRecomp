import 'package:flutter/material.dart';
import '../services/rest_countdown.dart';
import '../theme/app_theme.dart';
import 'kinetic_ring.dart';
import 'sheet_frame.dart';

/// Header capsule for active rest countdown; keeps fixed size so layouts never jump.
class RestTimerPill extends StatefulWidget {
  final RestCountdown controller;
  const RestTimerPill({super.key, required this.controller});

  @override
  State<RestTimerPill> createState() => _RestTimerPillState();
}

class _RestTimerPillState extends State<RestTimerPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _visibility = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );
  late final CurvedAnimation _fade = CurvedAnimation(
    parent: _visibility,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<double> _idleFade =
      Tween<double>(begin: 1.0, end: 0.0).animate(_fade);
  late final Animation<double> _panelScale =
      Tween<double>(begin: 0.94, end: 1.0).animate(_fade);
  RestCountdownState? _face;
  bool _reduceMotion = false;
  bool get _running => (widget.controller.value?.remaining ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    if (_running) {
      _face = widget.controller.value;
      _visibility.value = 1;
    }
    widget.controller.addListener(_update);
    _visibility.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_running && _face != null) {
      setState(() => _face = null);
    }
  }

  void _update() {
    setState(() {
      if (_running) _face = widget.controller.value;
    });
    if (_reduceMotion) {
      _visibility.value = _running ? 1 : 0;
      if (!_running && _face != null) setState(() => _face = null);
    } else if (_running) {
      if (_visibility.status != AnimationStatus.completed) {
        _visibility.forward();
      }
    } else {
      _visibility.reverse();
    }
  }

  @override
  void didUpdateWidget(RestTimerPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
      _update();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _visibility.value = _running ? 1 : 0;
      if (!_running) _face = null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    _fade.dispose();
    _visibility.dispose();
    super.dispose();
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestTimerSheet(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: SizedBox(
        key: const Key('rest-timer-pill'),
        width: 178,
        height: 40,
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              ExcludeSemantics(
                excluding: _running,
                child: IgnorePointer(
                  ignoring: _running,
                  child: FadeTransition(
                    opacity: _idleFade,
                    child: Tooltip(
                      message: '组间休息计时',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('rest-timer-idle-btn'),
                          customBorder: const CircleBorder(),
                          onTap: () => _openSheet(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [p.glassFillTop, p.glassFillBottom],
                              ),
                              border: Border.all(color: p.borderSubtle),
                            ),
                            child: Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ExcludeSemantics(
                excluding: !_running,
                child: IgnorePointer(
                  ignoring: !_running,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      alignment: Alignment.centerRight,
                      scale: _panelScale,
                      child: _face == null
                          ? const SizedBox.shrink()
                          : _TimerFace(
                              controller: widget.controller,
                              state: _face!,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerFace extends StatelessWidget {
  final RestCountdown controller;
  final RestCountdownState state;
  const _TimerFace({required this.controller, required this.state});

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestTimerSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = p.primary;
    final progress = state.total <= 0
        ? 0.0
        : (state.remaining / state.total).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: ink.withValues(alpha: .42), width: 1.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ink.withValues(alpha: p.isDark ? .26 : .18),
              p.glassFillBottom,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 3),
          child: Row(
            key: const Key('rest-timer-panel'),
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _openSheet(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(
                    children: [
                      Tooltip(
                        message: state.label,
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.2,
                            strokeCap: StrokeCap.round,
                            color: ink,
                            backgroundColor: ink.withValues(alpha: .18),
                          ),
                        ),
                      ),
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
                                fontSize: 13.5,
                                color: ink,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 42,
                height: 40,
                child: TextButton(
                  key: const Key('rest-timer-add'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => controller.addSeconds(30),
                  child: Text(
                    '+30',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                height: 40,
                child: IconButton(
                  key: const Key('rest-timer-dismiss'),
                  padding: EdgeInsets.zero,
                  tooltip: '结束计时',
                  onPressed: controller.stop,
                  icon: Icon(Icons.close_rounded, size: 16, color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestTimerSheet extends StatelessWidget {
  final RestCountdown controller;
  const _RestTimerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ValueListenableBuilder<RestCountdownState?>(
      valueListenable: controller,
      builder: (context, state, _) {
        final isRunning = (state?.remaining ?? 0) > 0;
        final remaining = state?.remaining ?? 0;
        final total = state?.total ?? 60;
        final progress = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
        final clock =
            '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
        return SheetFrame(
          title: '组间休息计时',
          subtitle: state?.label ?? '选择时长开始倒计时',
          icon: Icons.timer_rounded,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KineticProgressRing(
                progress: progress,
                size: 146,
                strokeWidth: 10,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      clock,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: p.textPrimary,
                      ),
                    ),
                    Text(
                      state == null
                          ? '点击下方开始'
                          : (remaining == 0 ? '休息结束' : '恢复中'),
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final sec in const [30, 60, 90, 120, 180])
                    ActionChip(
                      label: Text(sec >= 60 && sec % 60 == 0
                          ? '${sec ~/ 60}分钟'
                          : '${sec}s'),
                      backgroundColor: p.surfaceMuted,
                      side: BorderSide(color: p.borderSubtle),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                      onPressed: () =>
                          controller.start(sec, state?.label ?? '自由休息'),
                    ),
                ],
              ),
            ],
          ),
          footer: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: isRunning
                      ? () => controller.addSeconds(30)
                      : () => Navigator.pop(context),
                  child: Text(isRunning ? '+30 秒' : '关闭'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: isRunning
                      ? () {
                          controller.stop();
                          Navigator.pop(context);
                        }
                      : () => controller.start(60, state?.label ?? '自由休息'),
                  child: Text(isRunning ? '结束计时' : '开始 60 秒'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
