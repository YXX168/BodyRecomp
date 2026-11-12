import 'package:flutter/material.dart';
import '../services/rest_countdown.dart';

/// The header keeps its height while only the running pill fades in or out.
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
      reverseDuration: const Duration(milliseconds: 180));
  late final CurvedAnimation _fade = CurvedAnimation(
      parent: _visibility,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic);
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
      // Continue an interrupted exit instead of painting a second timer face.
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

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.4,
        child: SizedBox(
            key: const Key('rest-timer-pill'),
            width: 174,
            height: 40,
            child: RepaintBoundary(
                child: ExcludeSemantics(
                    excluding: !_running,
                    child: IgnorePointer(
                        ignoring: !_running,
                        child: FadeTransition(
                            opacity: _fade,
                            child: ScaleTransition(
                                alignment: Alignment.centerRight,
                                scale: Tween<double>(begin: .94, end: 1)
                                    .animate(_fade),
                                child: _face == null
                                    ? const SizedBox.shrink()
                                    : _TimerFace(
                                        controller: widget.controller,
                                        state: _face!))))))));
  }
}

class _TimerFace extends StatelessWidget {
  final RestCountdown controller;
  final RestCountdownState state;
  const _TimerFace({required this.controller, required this.state});

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
