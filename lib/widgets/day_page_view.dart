import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native 1:1 finger-following horizontal day pager backed by [PageView.builder],
/// publishing continuous fractional page progress for synced headers.
class DayPageView extends StatefulWidget {
  final DateTime date;
  final DateTime minDate;
  final DateTime maxDate;
  final Widget Function(BuildContext context, DateTime date) pageBuilder;
  final ValueChanged<DateTime> onDateChanged;
  final ValueNotifier<double>? pageProgressNotifier;
  final bool enabled;

  const DayPageView({
    super.key,
    required this.date,
    required this.minDate,
    required this.maxDate,
    required this.pageBuilder,
    required this.onDateChanged,
    this.pageProgressNotifier,
    this.enabled = true,
  });

  static final DateTime epochUtc = DateTime.utc(2000, 1, 1);

  /// Converts a local calendar date into a DST-safe UTC day offset from [epochUtc].
  static int dateToPageIndex(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).difference(epochUtc).inDays;

  /// Converts a UTC day offset from [epochUtc] back into a local date-only [DateTime].
  static DateTime pageIndexToDate(int index) {
    final utc = epochUtc.add(Duration(days: index));
    return DateTime(utc.year, utc.month, utc.day);
  }

  @override
  State<DayPageView> createState() => _DayPageViewState();
}

class _SilkyDayPagePhysics extends PageScrollPhysics {
  const _SilkyDayPagePhysics({super.parent});

  @override
  _SilkyDayPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _SilkyDayPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 1.0, stiffness: 145.0, damping: 24.4);
}

class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _DayPageViewState extends State<DayPageView> {
  static const Curve _programmaticCurve = Cubic(0.32, 0.72, 0.0, 1.0);

  late int _minIndex;
  late int _maxIndex;
  late int _settledDayIndex;
  int? _programmaticTargetDayIndex;
  int _programmaticEpoch = 0;
  late PageController _controller;

  int get _itemCount => math.max(1, _maxIndex - _minIndex + 1);

  int _clampedIndexFor(DateTime date) =>
      DayPageView.dateToPageIndex(date).clamp(_minIndex, _maxIndex);

  void _syncBounds() {
    _minIndex = DayPageView.dateToPageIndex(widget.minDate);
    _maxIndex =
        math.max(_minIndex, DayPageView.dateToPageIndex(widget.maxDate));
  }

  void _publishCurrentProgress() {
    final notifier = widget.pageProgressNotifier;
    if (notifier == null) return;
    if (_controller.hasClients && _controller.position.haveDimensions) {
      final page = _controller.page;
      if (page != null) {
        final absolute = _minIndex + page;
        if ((notifier.value - absolute).abs() > 1e-4) {
          notifier.value = absolute;
        }
        return;
      }
    }
    final fallback = _settledDayIndex.toDouble();
    if ((notifier.value - fallback).abs() > 1e-4) {
      notifier.value = fallback;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncBounds();
    _settledDayIndex = _clampedIndexFor(widget.date);
    _controller = PageController(initialPage: _settledDayIndex - _minIndex);
    _controller.addListener(_publishCurrentProgress);
    widget.pageProgressNotifier?.value = _settledDayIndex.toDouble();
  }

  @override
  void didUpdateWidget(DayPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prevMin = _minIndex;
    _syncBounds();
    if (_minIndex != prevMin && _controller.hasClients) {
      final shiftedLocal =
          (_settledDayIndex - _minIndex).clamp(0, _itemCount - 1);
      _controller.jumpToPage(shiftedLocal);
    }

    if (widget.pageProgressNotifier != oldWidget.pageProgressNotifier) {
      _publishCurrentProgress();
    }

    final target = _clampedIndexFor(widget.date);
    final activeTarget = _programmaticTargetDayIndex ?? _settledDayIndex;
    if (target == activeTarget) return;

    final targetLocal = target - _minIndex;
    if (!_controller.hasClients || !_controller.position.haveDimensions) {
      _programmaticTargetDayIndex = null;
      _settledDayIndex = target;
      widget.pageProgressNotifier?.value = target.toDouble();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.jumpToPage(
            (_settledDayIndex - _minIndex).clamp(0, _itemCount - 1));
        _publishCurrentProgress();
      });
      return;
    }

    final currentAbs = _minIndex +
        (_controller.page ?? (_settledDayIndex - _minIndex).toDouble());
    final dist = (target - currentAbs).abs();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    if (dist <= 7.0 && !disableAnimations) {
      _programmaticTargetDayIndex = target;
      final epoch = ++_programmaticEpoch;
      final ms = (360 + ((dist - 1.0).clamp(0.0, 6.0) * 28)).round();
      _controller
          .animateToPage(
        targetLocal,
        duration: Duration(milliseconds: ms),
        curve: _programmaticCurve,
      )
          .whenComplete(() {
        if (!mounted || _programmaticEpoch != epoch) return;
        _programmaticTargetDayIndex = null;
        _settledDayIndex = target;
        _publishCurrentProgress();
      });
    } else {
      _programmaticTargetDayIndex = target;
      _programmaticEpoch++;
      _controller.jumpToPage(targetLocal);
      _programmaticTargetDayIndex = null;
      _settledDayIndex = target;
      widget.pageProgressNotifier?.value = target.toDouble();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_publishCurrentProgress)
      ..dispose();
    super.dispose();
  }

  void _onPageChanged(int localIndex) {
    final dayIndex = _minIndex + localIndex;
    if (_programmaticTargetDayIndex != null) {
      if (dayIndex == _programmaticTargetDayIndex) {
        _programmaticTargetDayIndex = null;
        _settledDayIndex = dayIndex;
      }
      return;
    }
    if (_settledDayIndex == dayIndex &&
        DayPageView.dateToPageIndex(widget.date) == dayIndex) {
      return;
    }
    _settledDayIndex = dayIndex;
    HapticFeedback.selectionClick();
    widget.onDateChanged(DayPageView.pageIndexToDate(dayIndex));
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      if (_programmaticTargetDayIndex != null) {
        _programmaticTargetDayIndex = null;
        _programmaticEpoch++;
      }
    } else if (notification is ScrollEndNotification &&
        _programmaticTargetDayIndex == null &&
        _controller.hasClients &&
        _controller.position.haveDimensions) {
      final roundedLocal =
          (_controller.page ?? 0.0).round().clamp(0, _itemCount - 1);
      final dayIndex = _minIndex + roundedLocal;
      final widgetDayIndex = _clampedIndexFor(widget.date);
      if (dayIndex != widgetDayIndex) {
        _settledDayIndex = dayIndex;
        widget.onDateChanged(DayPageView.pageIndexToDate(dayIndex));
      } else {
        _settledDayIndex = dayIndex;
      }
      _publishCurrentProgress();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoOverscrollBehavior(),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: PageView.builder(
          controller: _controller,
          allowImplicitScrolling: false,
          physics: widget.enabled
              ? const _SilkyDayPagePhysics(parent: BouncingScrollPhysics())
              : const NeverScrollableScrollPhysics(),
          itemCount: _itemCount,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, localIndex) {
            final pageDate =
                DayPageView.pageIndexToDate(_minIndex + localIndex);
            return RepaintBoundary(
              child: widget.pageBuilder(context, pageDate),
            );
          },
        ),
      ),
    );
  }
}
