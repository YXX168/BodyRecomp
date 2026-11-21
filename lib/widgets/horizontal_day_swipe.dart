import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Finger-following horizontal day switcher with damped rubber-band drag and
/// critically-damped incoming day glide.
class HorizontalDaySwipe extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final double triggerDistance;

  const HorizontalDaySwipe({
    super.key,
    required this.child,
    this.onPrevious,
    this.onNext,
    this.triggerDistance = 48,
  });

  @override
  State<HorizontalDaySwipe> createState() => _HorizontalDaySwipeState();
}

class _HorizontalDaySwipeState extends State<HorizontalDaySwipe>
    with SingleTickerProviderStateMixin {
  static const Curve _glideCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  double _rawDrag = 0.0;
  double _dragOffset = 0.0;
  double _animFromOffset = 0.0;
  double _animFromOpacity = 1.0;
  bool _animating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGlide({required double fromOffset, required double fromOpacity}) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
      setState(() {
        _dragOffset = 0.0;
        _animFromOffset = 0.0;
        _animFromOpacity = 1.0;
        _animating = false;
      });
      return;
    }
    setState(() {
      _dragOffset = 0.0;
      _animFromOffset = fromOffset;
      _animFromOpacity = fromOpacity;
      _animating = true;
    });
    _controller.forward(from: 0.0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _animFromOffset = 0.0;
        _animFromOpacity = 1.0;
        _animating = false;
      });
    });
  }

  void _handleDragStart(DragStartDetails details) {
    _controller.stop();
    _rawDrag = 0.0;
    if (_dragOffset != 0.0 || _animating) {
      setState(() {
        _dragOffset = 0.0;
        _animFromOffset = 0.0;
        _animFromOpacity = 1.0;
        _animating = false;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _rawDrag += details.delta.dx;
    final goingPrev = _rawDrag > 0;
    final canMove =
        goingPrev ? widget.onPrevious != null : widget.onNext != null;
    final nextOffset = canMove
        ? (_rawDrag * 0.42).clamp(-80.0, 80.0).toDouble()
        : (_rawDrag * 0.14).clamp(-20.0, 20.0).toDouble();
    if (nextOffset != _dragOffset) {
      setState(() => _dragOffset = nextOffset);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    final triggerNext = widget.onNext != null &&
        (_rawDrag <= -widget.triggerDistance || (vx < -460 && _rawDrag < -14));
    final triggerPrev = widget.onPrevious != null &&
        (_rawDrag >= widget.triggerDistance || (vx > 460 && _rawDrag > 14));

    _rawDrag = 0.0;

    if (triggerNext) {
      HapticFeedback.selectionClick();
      widget.onNext!.call();
      _startGlide(fromOffset: 36.0, fromOpacity: 0.55);
      return;
    }
    if (triggerPrev) {
      HapticFeedback.selectionClick();
      widget.onPrevious!.call();
      _startGlide(fromOffset: -36.0, fromOpacity: 0.55);
      return;
    }

    if (_dragOffset.abs() > 0.5) {
      final currentOpacity =
          (1.0 - (_dragOffset.abs() / 80.0) * 0.12).clamp(0.88, 1.0);
      _startGlide(fromOffset: _dragOffset, fromOpacity: currentOpacity);
    } else if (_dragOffset != 0.0) {
      setState(() => _dragOffset = 0.0);
    }
  }

  void _handleDragCancel() {
    _rawDrag = 0.0;
    if (_dragOffset.abs() > 0.5) {
      final currentOpacity =
          (1.0 - (_dragOffset.abs() / 80.0) * 0.12).clamp(0.88, 1.0);
      _startGlide(fromOffset: _dragOffset, fromOpacity: currentOpacity);
    } else if (_dragOffset != 0.0) {
      setState(() => _dragOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          HorizontalDragGestureRecognizer.new,
          (recognizer) {
            recognizer.onStart = _handleDragStart;
            recognizer.onUpdate = _handleDragUpdate;
            recognizer.onEnd = _handleDragEnd;
            recognizer.onCancel = _handleDragCancel;
          },
        ),
      },
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final double currentX;
          final double currentOpacity;
          if (_animating) {
            final t = _glideCurve.transform(_controller.value.clamp(0.0, 1.0));
            currentX = _animFromOffset * (1.0 - t);
            currentOpacity = (_animFromOpacity + (1.0 - _animFromOpacity) * t)
                .clamp(0.0, 1.0);
          } else {
            currentX = _dragOffset;
            currentOpacity = currentX == 0.0
                ? 1.0
                : (1.0 - (currentX.abs() / 80.0) * 0.12).clamp(0.88, 1.0);
          }

          if (currentX == 0.0 && currentOpacity >= 0.999) {
            return child!;
          }

          Widget transformed = Transform.translate(
            offset: Offset(currentX, 0),
            child: child,
          );
          if (currentOpacity < 0.999) {
            transformed = Opacity(
              opacity: currentOpacity,
              child: transformed,
            );
          }
          return transformed;
        },
      ),
    );
  }
}
