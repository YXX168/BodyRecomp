import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Floating Liquid Glass bottom dock with a critically-damped (zero-bounce)
/// liquid-droplet sliding capsule that responds to both taps and horizontal drags.
class AppNavigationBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const AppNavigationBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  static const labels = ['训练', '模板', '动作库', '我的'];
  static const activeIcons = [
    Icons.bolt_rounded,
    Icons.calendar_view_week_rounded,
    Icons.grid_view_rounded,
    Icons.person_rounded,
  ];
  static const inactiveIcons = [
    Icons.bolt_outlined,
    Icons.calendar_view_week_outlined,
    Icons.grid_view_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar>
    with SingleTickerProviderStateMixin {
  // Critically-damped smooth liquid deceleration curve — zero overshoot/bounce.
  static const Curve _liquidCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late double _fromPos = widget.index.toDouble();
  late double _toPos = widget.index.toDouble();

  bool _dragging = false;
  double _dragPos = 0.0;
  double _dragStretch = 0.0;

  double get _currentAnimatedPos {
    final t = _liquidCurve.transform(_controller.value.clamp(0.0, 1.0));
    return lerpDouble(_fromPos, _toPos, t) ?? _toPos;
  }

  @override
  void initState() {
    super.initState();
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AppNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index &&
        !_dragging &&
        _toPos != widget.index.toDouble()) {
      _animateTo(widget.index.toDouble());
    }
  }

  void _animateTo(double target) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _fromPos = target;
      _toPos = target;
      _controller.value = 1.0;
      setState(() {});
      return;
    }
    _fromPos = _dragging ? _dragPos : _currentAnimatedPos;
    _toPos = target;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details, double slotWidth) {
    _controller.stop();
    setState(() {
      _dragging = true;
      _dragPos = _currentAnimatedPos.clamp(
        0.0,
        (AppNavigationBar.labels.length - 1).toDouble(),
      );
      _dragStretch = 0.0;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details, double slotWidth) {
    if (!_dragging || slotWidth <= 0) return;
    final maxIdx = (AppNavigationBar.labels.length - 1).toDouble();
    final nextPos =
        (_dragPos + details.delta.dx / slotWidth).clamp(0.0, maxIdx);
    final stretch = (details.delta.dx.abs() / 28.0).clamp(0.0, 0.16);
    final nearest = nextPos.round();
    if (nearest != widget.index) {
      widget.onChanged(nearest);
    }
    setState(() {
      _dragPos = nextPos;
      _dragStretch = stretch;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    final maxIdx = AppNavigationBar.labels.length - 1;
    var target = _dragPos.round().clamp(0, maxIdx);
    final vx = details.velocity.pixelsPerSecond.dx;
    if (vx.abs() > 380) {
      target = (vx > 0 ? _dragPos.ceil() : _dragPos.floor()).clamp(0, maxIdx);
    }
    final releasePos = _dragPos;
    setState(() {
      _dragging = false;
      _dragStretch = 0.0;
      _fromPos = releasePos;
      _toPos = target.toDouble();
    });
    if (target != widget.index) {
      widget.onChanged(target);
    } else {
      HapticFeedback.selectionClick();
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labelHeight = MediaQuery.textScalerOf(context).scale(10.5) * 1.4;
    final itemHeight = 35 + labelHeight;
    final count = AppNavigationBar.labels.length;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? .34 : .08),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12,
                  sigmaY: 12,
                  tileMode: TileMode.clamp,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          Colors.white.withValues(alpha: p.isDark ? .07 : .28),
                          p.dockBg,
                        ),
                        p.dockBg,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: p.glassRimBright.withValues(alpha: .60),
                      width: 0.9,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.5),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final slotWidth = totalWidth / count;
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: (d) =>
                              _handleDragStart(d, slotWidth),
                          onHorizontalDragUpdate: (d) =>
                              _handleDragUpdate(d, slotWidth),
                          onHorizontalDragEnd: _handleDragEnd,
                          onHorizontalDragCancel: () {
                            if (!_dragging) return;
                            _handleDragEnd(DragEndDetails());
                          },
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final double pos;
                              final double stretchX;
                              final double squishY;
                              if (_dragging) {
                                pos = _dragPos;
                                stretchX = 1.0 + _dragStretch;
                                squishY = 1.0 - _dragStretch * 0.28;
                              } else {
                                final rawT = _controller.value.clamp(0.0, 1.0);
                                final dist =
                                    (_toPos - _fromPos).abs().clamp(0.0, 3.0);
                                final pulse = dist > 0.05
                                    ? math.sin(math.pi * rawT)
                                    : 0.0;
                                pos = _currentAnimatedPos.clamp(
                                  0.0,
                                  (count - 1).toDouble(),
                                );
                                stretchX = 1.0 + 0.14 * pulse * math.sqrt(dist);
                                squishY = 1.0 - 0.05 * pulse;
                              }

                              final pillWidth = (slotWidth * stretchX)
                                  .clamp(slotWidth, totalWidth);
                              final pillHeight = itemHeight * squishY;
                              final centerX = (pos + 0.5) * slotWidth;
                              final left = (centerX - pillWidth / 2)
                                  .clamp(
                                    0.0,
                                    math.max(0.0, totalWidth - pillWidth),
                                  )
                                  .toDouble();
                              final top = (itemHeight - pillHeight) / 2;

                              return SizedBox(
                                height: itemHeight,
                                child: Stack(
                                  children: [
                                    // Smooth zero-bounce translucent liquid droplet capsule
                                    Positioned(
                                      left: left,
                                      top: top,
                                      width: pillWidth,
                                      height: pillHeight,
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color.alphaBlend(
                                                  Colors.white.withValues(
                                                    alpha: p.isDark ? .14 : .62,
                                                  ),
                                                  p.primary.withValues(
                                                    alpha: p.isDark ? .20 : .15,
                                                  ),
                                                ),
                                                p.primary.withValues(
                                                  alpha: p.isDark ? .10 : .08,
                                                ),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(23),
                                            border: Border.all(
                                              color: Color.alphaBlend(
                                                Colors.white.withValues(
                                                  alpha: p.isDark ? .20 : .70,
                                                ),
                                                p.primary.withValues(
                                                  alpha: p.isDark ? .38 : .26,
                                                ),
                                              ),
                                              width: 0.95,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: p.primary.withValues(
                                                  alpha: p.isDark ? .18 : .12,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                top: 2,
                                                left: 16,
                                                right: 16,
                                              ),
                                              height: 1.8,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.white.withValues(
                                                      alpha:
                                                          p.isDark ? .34 : .82,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        for (var i = 0; i < count; i++)
                                          Expanded(
                                            child: Builder(
                                              builder: (context) {
                                                final focus =
                                                    (1.0 - (i - pos).abs())
                                                        .clamp(0.0, 1.0);
                                                final isSelected =
                                                    i == widget.index;
                                                final ink = Color.lerp(
                                                  p.textSecondary,
                                                  p.primary,
                                                  focus,
                                                )!;
                                                return Semantics(
                                                  selected: isSelected,
                                                  button: true,
                                                  label: AppNavigationBar
                                                      .labels[i],
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      key: ValueKey('nav-$i'),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              23),
                                                      splashColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () =>
                                                          widget.onChanged(i),
                                                      child: SizedBox(
                                                        height: itemHeight,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Transform.scale(
                                                              scale: 1.0 +
                                                                  0.05 * focus,
                                                              child: Icon(
                                                                focus > 0.5
                                                                    ? AppNavigationBar
                                                                            .activeIcons[
                                                                        i]
                                                                    : AppNavigationBar
                                                                        .inactiveIcons[i],
                                                                size: 20,
                                                                color: ink,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 2),
                                                            Text(
                                                              AppNavigationBar
                                                                  .labels[i],
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 10.5,
                                                                height: 1.3,
                                                                fontWeight: focus >
                                                                        0.5
                                                                    ? FontWeight
                                                                        .w700
                                                                    : FontWeight
                                                                        .w500,
                                                                color: ink,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
