import 'dart:async';

import 'package:flutter/material.dart';

import '../models/recomp_models.dart';

/// Keeps the displayed day in sync while preserving an explicit history date.
mixin DailyRecordDate<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  DateTime get now;
  late DateTime today = dateOnly(now);
  late DateTime recordDate = today;
  bool _followToday = true;
  bool _pageVisible = true;
  bool _foreground = true;
  bool get pageActive => _pageVisible && _foreground;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageVisible = TickerMode.valuesOf(context).enabled;
    if (_pageVisible) _updateToday();
    _scheduleMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (pageActive) setState(_updateToday);
    _scheduleMidnight();
  }

  void selectRecordDate(DateTime date) {
    setState(() {
      recordDate = dateOnly(date);
      _followToday = recordDate == today;
    });
  }

  void _updateToday() {
    final selected = recordDate;
    today = dateOnly(now);
    if (_followToday || selected.isAfter(today)) {
      recordDate = today;
      _followToday = true;
    }
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    if (!pageActive) return;
    final current = now;
    final nextDay = DateTime(current.year, current.month, current.day + 1);
    _midnight = Timer(nextDay.difference(current), () {
      setState(_updateToday);
      _scheduleMidnight();
    });
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
