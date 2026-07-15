import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

class _HorizontalDaySwipeState extends State<HorizontalDaySwipe> {
  double _distance = 0;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          HorizontalDragGestureRecognizer.new,
          (recognizer) {
            recognizer.onStart = (_) => _distance = 0;
            recognizer.onUpdate = (details) => _distance += details.delta.dx;
            recognizer.onEnd = (_) {
              if (_distance <= -widget.triggerDistance) {
                widget.onNext?.call();
              } else if (_distance >= widget.triggerDistance) {
                widget.onPrevious?.call();
              }
              _distance = 0;
            };
            recognizer.onCancel = () => _distance = 0;
          },
        ),
      },
      child: widget.child,
    );
  }
}
