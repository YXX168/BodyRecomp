import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../data/workout_templates.dart';
import '../models/daily_workout.dart';
import '../models/library_exercise.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../services/data_service.dart';
import '../services/exercise_library_service.dart';
import '../services/rest_countdown.dart';
import '../services/rest_timer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/daily_record_date.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/exercise_mark.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/horizontal_day_swipe.dart';
import '../widgets/loading_view.dart';
import '../widgets/muscle_body_graphic.dart';
import '../widgets/rest_timer_pill.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/text_prompt.dart';
import '../widgets/undo_notice.dart';
import '../widgets/week_strip_bar.dart';
import '../widgets/weight_log_sheet.dart';
import 'template_manager_page.dart';

class WorkoutPage extends StatefulWidget {
  final DateTime Function()? now;
  final RestCountdown? restController;
  final bool showRestTimer;

  const WorkoutPage({
    super.key,
    this.now,
    this.restController,
    this.showRestTimer = true,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with WidgetsBindingObserver, DailyRecordDate, TickerProviderStateMixin {
  static final DateTime _minDate = DateTime(2000);
  static const Curve _dayCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  @override
  DateTime get now => (widget.now ?? DateTime.now)();

  @override
  bool get allowFutureRecordDate => true;

  RestCountdown? _ownedRest;
  RestCountdown get _rest => widget.restController ?? _ownedRest!;

  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _scrollOffsets = {};
  String? _activeScrollDateKey;
  bool _restoringScroll = false;
  final Map<String, String> _selectedTemplateByDate = {};
  final Set<String> _expandedNotes = {};

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  int _loadGeneration = 0;
  int _sessionsGeneration = 0;
  int _planGeneration = 0;
  int _logsGeneration = 0;
  int _autoRestGeneration = 0;
  int _suppressOwnHistoryReload = 0;
  int _suppressOwnPlanReload = 0;

  Map<String, DailyWorkout> _sessions = {};
  List<WorkoutTemplate> _templates = [];
  List<String> _schedule = List.filled(7, '');
  Map<String, ExerciseLog> _latestLogByExercise = {};
  Map<String, ExerciseLog> _prByExercise = {};
  bool _autoRest = false;

  late final AnimationController _dayAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 190),
    value: 1.0,
  );
  int _dayTransitionDir = 0;
  bool _skipNextDayAnim = false;

  @override
  void selectRecordDate(DateTime date) {
    final prev = dateOnly(recordDate);
    final next = dateOnly(date);
    super.selectRecordDate(next);
    if (next == prev) return;
    if (_skipNextDayAnim || MediaQuery.disableAnimationsOf(context)) {
      _skipNextDayAnim = false;
      _dayTransitionDir = 0;
      _dayAnim.value = 1.0;
      return;
    }
    _dayTransitionDir = next.isAfter(prev) ? 1 : -1;
    _dayAnim.forward(from: 0.0).whenComplete(() {
      if (mounted) _dayTransitionDir = 0;
    });
  }

  Widget _dayTransitionWrap(Widget child) {
    if (_dayTransitionDir == 0 && !_dayAnim.isAnimating) return child;
    return AnimatedBuilder(
      animation: _dayAnim,
      child: child,
      builder: (context, inner) {
        final raw = _dayAnim.value.clamp(0.0, 1.0);
        if (raw >= 0.999) return inner!;
        final t = _dayCurve.transform(raw);
        final dx = _dayTransitionDir * 16.0 * (1.0 - t);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(
            opacity: (0.72 + 0.28 * t).clamp(0.0, 1.0),
            child: inner,
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.restController == null) {
      _ownedRest = RestCountdown(
        now: () => now,
        onFinished: () => HapticFeedback.heavyImpact(),
      );
    }
    workoutDataRevision.addListener(_loadAll);
    workoutHistoryRevision.addListener(_onHistoryRevision);
    workoutPlanRevision.addListener(_onPlanRevision);
    exerciseLogsRevision.addListener(_loadLogsOnly);
    restTimerPreferenceRevision.addListener(_loadAutoRestOnly);
    _scrollController.addListener(_onScrollChanged);
    _loadAll();
  }

  void _rebuildLogCaches(List<ExerciseLog> logs) {
    final latest = <String, ExerciseLog>{};
    final pr = <String, ExerciseLog>{};
    for (final log in logs) {
      final existingLatest = latest[log.exerciseName];
      if (existingLatest == null || log.date.isAfter(existingLatest.date)) {
        latest[log.exerciseName] = log;
      }
      final existingPr = pr[log.exerciseName];
      if (existingPr == null || log.estimated1RM > existingPr.estimated1RM) {
        pr[log.exerciseName] = log;
      }
    }
    _latestLogByExercise = latest;
    _prByExercise = pr;
  }

  void _notifyHistoryChanged() {
    _suppressOwnHistoryReload++;
    try {
      workoutHistoryRevision.value++;
    } finally {
      if (_suppressOwnHistoryReload > 0) _suppressOwnHistoryReload--;
    }
  }

  void _notifyPlanChanged() {
    _suppressOwnPlanReload++;
    try {
      workoutPlanRevision.value++;
    } finally {
      if (_suppressOwnPlanReload > 0) _suppressOwnPlanReload--;
    }
  }

  void _onHistoryRevision() {
    if (_suppressOwnHistoryReload > 0) return;
    _loadSessionsOnly();
  }

  void _onPlanRevision() {
    if (_suppressOwnPlanReload > 0) return;
    _loadPlanOnly();
  }

  void _onScrollChanged() {
    if (_restoringScroll ||
        _activeScrollDateKey == null ||
        !_scrollController.hasClients) {
      return;
    }
    _scrollOffsets[_activeScrollDateKey!] = _scrollController.offset;
  }

  Future<void> _showHeroMenu(
    BuildContext btnContext,
    DateTime targetDate,
    DailyWorkout session,
    DailyWorkout? existingSession,
    WorkoutTemplate? scheduledTpl,
  ) async {
    final p = context.palette;
    final action = await showGlassMenu<String>(
      context: context,
      anchorContext: btnContext,
      title: '今日方案操作',
      items: [
        GlassMenuItem(
          value: 'switch',
          label: '切换模板',
          icon: Icons.swap_horiz_rounded,
          color: p.primary,
        ),
        GlassMenuItem(
          value: 'pick_template',
          label: '从模板库挑动作',
          icon: Icons.playlist_add_rounded,
          color: p.accent,
        ),
        if (scheduledTpl != null && (existingSession != null || session.rested))
          GlassMenuItem(
            value: 'restore',
            label: '恢复今日固定模板',
            icon: Icons.restart_alt_rounded,
            color: p.primary,
          ),
        if (!session.rested)
          GlassMenuItem(
            value: 'rest',
            label: '标记为休息日',
            icon: Icons.self_improvement_rounded,
            color: p.warning,
          ),
        if (session.blocks.isNotEmpty)
          GlassMenuItem(
            value: 'save_tpl',
            label: '存为新模板',
            icon: Icons.bookmark_add_outlined,
            color: p.accent,
          ),
        const GlassMenuItem(
          value: 'schedule',
          label: '编排每周固定模板',
          icon: Icons.calendar_view_week_rounded,
          hasTopDivider: true,
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'switch':
        await _switchTemplate(targetDate);
      case 'pick_template':
        await _addFromPicker(targetDate, initialSource: 0);
      case 'restore':
        await _restoreFixedTemplate(targetDate);
      case 'rest':
        await _markRest(targetDate);
      case 'save_tpl':
        await _saveCurrentAsTemplate(targetDate);
      case 'schedule':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TemplateManagerPage(),
          ),
        );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ownedRest != null) {
      _ownedRest!.setActive(pageActive);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_ownedRest != null) {
      _ownedRest!.setActive(pageActive);
    }
  }

  @override
  void dispose() {
    workoutDataRevision.removeListener(_loadAll);
    workoutHistoryRevision.removeListener(_onHistoryRevision);
    workoutPlanRevision.removeListener(_onPlanRevision);
    exerciseLogsRevision.removeListener(_loadLogsOnly);
    restTimerPreferenceRevision.removeListener(_loadAutoRestOnly);
    _scrollController
      ..removeListener(_onScrollChanged)
      ..dispose();
    _dayAnim.dispose();
    _ownedRest?.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final gen = ++_loadGeneration;
    _sessionsGeneration++;
    _planGeneration++;
    _logsGeneration++;
    _autoRestGeneration++;
    try {
      final sessions = await loadDailyWorkouts();
      final templates = await loadWorkoutTemplates();
      final schedule = await loadWeeklySchedule();
      final logs = await loadExerciseLogs();
      final autoRest = await loadAutoRestTimer();
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _sessions = sessions;
        _templates = templates;
        _schedule = schedule;
        _rebuildLogCaches(logs);
        _autoRest = autoRest;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (mounted && gen == _loadGeneration) {
        setState(() {
          _loading = false;
          _loadError = '训练记录读取失败，本地数据未被覆盖。';
        });
      }
    }
  }

  Future<void> _loadSessionsOnly() async {
    final gen = ++_sessionsGeneration;
    final fullGen = _loadGeneration;
    try {
      final sessions = await loadDailyWorkouts();
      if (!mounted ||
          gen != _sessionsGeneration ||
          fullGen != _loadGeneration) {
        return;
      }
      setState(() {
        _sessions = sessions;
        _loadError = null;
      });
    } catch (_) {
      // Preserve last valid in-memory state if a background refresh fails.
    }
  }

  Future<void> _loadPlanOnly() async {
    final gen = ++_planGeneration;
    final fullGen = _loadGeneration;
    try {
      final templates = await loadWorkoutTemplates();
      final schedule = await loadWeeklySchedule();
      if (!mounted || gen != _planGeneration || fullGen != _loadGeneration) {
        return;
      }
      setState(() {
        _templates = templates;
        _schedule = schedule;
      });
    } catch (_) {
      // Preserve last valid templates/schedule on transient read failure.
    }
  }

  Future<void> _loadLogsOnly() async {
    final gen = ++_logsGeneration;
    final fullGen = _loadGeneration;
    try {
      final logs = await loadExerciseLogs();
      if (!mounted || gen != _logsGeneration || fullGen != _loadGeneration) {
        return;
      }
      setState(() => _rebuildLogCaches(logs));
    } catch (_) {
      // Keep last known weight/PR badges on transient read failure.
    }
  }

  Future<void> _loadAutoRestOnly() async {
    final gen = ++_autoRestGeneration;
    final fullGen = _loadGeneration;
    try {
      final autoRest = await loadAutoRestTimer();
      if (!mounted ||
          gen != _autoRestGeneration ||
          fullGen != _loadGeneration) {
        return;
      }
      setState(() => _autoRest = autoRest);
    } catch (_) {
      // Keep last known auto-rest preference on transient read failure.
    }
  }

  WorkoutTemplate? _scheduledTemplate(DateTime day) {
    final idx = day.weekday - 1;
    if (idx < 0 || idx >= _schedule.length) return null;
    final id = _schedule[idx];
    if (id.isEmpty) return null;
    for (final t in _templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  WorkoutTemplate? _templateById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final t in _templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  DailyWorkout _effectiveSession(DateTime day) {
    final key = dayKey(day);
    final saved = _sessions[key];
    if (saved != null) return saved;
    final tpl = _scheduledTemplate(day);
    if (tpl != null) {
      return DailyWorkout(
        date: key,
        blocks: instantiateTemplateBlocks(tpl, key, preview: true),
        templateId: tpl.id,
        templateName: tpl.name,
      );
    }
    return DailyWorkout(date: key, rested: false);
  }

  bool _isDateEditable(DateTime date) =>
      !dateOnly(date).isAfter(dateOnly(today));

  DayStripStatus _statusForDay(DateTime day) {
    final saved = _sessions[dayKey(day)];
    if (saved != null) {
      if (saved.rested) return DayStripStatus.rest;
      if (saved.blocks.isEmpty) return DayStripStatus.rest;
      if (saved.plannedSets > 0 && saved.completedSets >= saved.plannedSets) {
        return DayStripStatus.completed;
      }
      if (saved.completedSets > 0) return DayStripStatus.partial;
      return DayStripStatus.planned;
    }
    final scheduled = _scheduledTemplate(day);
    return scheduled == null ? DayStripStatus.rest : DayStripStatus.planned;
  }

  Future<bool> _saveSession(DailyWorkout next) async {
    final parsed = DateTime.tryParse(next.date);
    if (_saving || (parsed != null && !_isDateEditable(parsed))) return false;
    setState(() => _saving = true);
    try {
      await saveDailyWorkout(next);
      if (mounted) {
        setState(() => _sessions[next.date] = next);
      }
      _notifyHistoryChanged();
      return true;
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '保存训练失败，请重试', isError: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _deleteSessionForDate(
    String key, {
    String errorMessage = '恢复模板失败，请重试',
  }) async {
    if (_saving) return false;
    setState(() => _saving = true);
    try {
      await deleteDailyWorkout(key);
      if (mounted) {
        setState(() {
          _sessions.remove(key);
          _selectedTemplateByDate.remove(key);
        });
      }
      _notifyHistoryChanged();
      return true;
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, errorMessage, isError: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restoreFixedTemplate(DateTime targetDate) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final key = dayKey(targetDate);
    final previous = _sessions[key];
    final previousTplId = _selectedTemplateByDate[key];
    final removed = await _deleteSessionForDate(
      key,
      errorMessage: '恢复模板失败，请重试',
    );
    if (!removed || !mounted || previous == null) return;
    showUndoNotice(context, '已恢复当日固定模板', onUndo: () async {
      if (!mounted || _saving || _sessions.containsKey(key)) return;
      final restored = await _saveSession(previous);
      if (restored && mounted && previousTplId != null) {
        setState(() => _selectedTemplateByDate[key] = previousTplId);
      }
    });
  }

  Future<void> _switchTemplate(DateTime targetDate) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final key = dayKey(targetDate);
    final current = _effectiveSession(targetDate);
    final activeId = current.templateId ??
        _selectedTemplateByDate[key] ??
        _scheduledTemplate(targetDate)?.id;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
        title: '切换今日模板',
        icon: Icons.swap_horiz_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tpl in _templates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectionOption(
                  key: ValueKey('switch-template-${tpl.id}'),
                  title: tpl.name,
                  subtitle:
                      '${tpl.exercises.length} 动作 · ${tpl.exercises.fold<int>(0, (s, e) => s + e.sets)} 组',
                  leading: ExerciseMark(
                    tpl.exercises.isEmpty ? '平板卧推' : tpl.exercises.first.name,
                    size: 40,
                  ),
                  selected: activeId == tpl.id && !current.rested,
                  onTap: () => Navigator.pop(ctx, tpl.id),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final tpl = _templateById(picked);
    if (tpl == null) return;
    final saved = await _saveSession(
      DailyWorkout(
        date: key,
        rested: false,
        blocks: instantiateTemplateBlocks(tpl, key),
        templateId: tpl.id,
        templateName: tpl.name,
      ),
    );
    if (saved && mounted) {
      setState(() => _selectedTemplateByDate[key] = tpl.id);
    }
  }

  Future<void> _applyScheduledNow(DateTime targetDate) async {
    final scheduled = _scheduledTemplate(targetDate);
    if (scheduled == null) {
      await _switchTemplate(targetDate);
      return;
    }
    final key = dayKey(targetDate);
    final saved = await _saveSession(
      DailyWorkout(
        date: key,
        rested: false,
        blocks: instantiateTemplateBlocks(scheduled, key),
        templateId: scheduled.id,
        templateName: scheduled.name,
      ),
    );
    if (saved && mounted) {
      setState(() => _selectedTemplateByDate[key] = scheduled.id);
    }
  }

  Future<void> _markRest(DateTime targetDate) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final key = dayKey(targetDate);
    final previous = _sessions[key];
    final previousTplId = _selectedTemplateByDate[key];
    final saved = await _saveSession(
      DailyWorkout(
        date: key,
        rested: true,
        blocks: const [],
      ),
    );
    if (!saved || !mounted) return;
    setState(() => _selectedTemplateByDate.remove(key));
    showUndoNotice(context, '已标记今日休息', onUndo: () async {
      if (!mounted || _saving) return;
      final latest = _sessions[key];
      if (latest == null || !latest.rested) return;
      if (previous == null) {
        await _deleteSessionForDate(key, errorMessage: '恢复训练失败，请重试');
      } else {
        final ok = await _saveSession(previous);
        if (ok && mounted && previousTplId != null) {
          setState(() => _selectedTemplateByDate[key] = previousTplId);
        }
      }
    });
  }

  Future<void> _cancelRest(DateTime targetDate) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    await _deleteSessionForDate(
      dayKey(targetDate),
      errorMessage: '取消休息失败，请重试',
    );
  }

  Future<void> _addFromPicker(
    DateTime targetDate, {
    int initialSource = 1,
  }) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final picked = await pickExercises(
      context,
      _templates,
      initialSource: initialSource,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    final current = _effectiveSession(targetDate);
    final seed = DateTime.now().microsecondsSinceEpoch;
    final added = [
      for (var i = 0; i < picked.length; i++)
        WorkoutBlock(id: 'blk_${seed}_$i', exercise: picked[i]),
    ];
    await _saveSession(
      current.copyWith(
        rested: false,
        blocks: [...current.blocks, ...added],
      ),
    );
  }

  Future<void> _addCustomExercise(DateTime targetDate) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final res = await editExerciseDetailed(
      context,
      offerSaveToLibrary: true,
    );
    if (res == null || !mounted) return;
    final current = _effectiveSession(targetDate);
    final block = WorkoutBlock(
      id: 'blk_${DateTime.now().microsecondsSinceEpoch}',
      exercise: res.exercise,
    );
    final saved = await _saveSession(
      current.copyWith(
        rested: false,
        blocks: [...current.blocks, block],
      ),
    );
    if (saved && res.saveToLibrary) {
      try {
        await addLibraryExercise(
          LibraryExercise(
            id: 'lib_${DateTime.now().microsecondsSinceEpoch}',
            category: res.category,
            exercise: res.exercise,
          ),
        );
        exerciseLibraryRevision.value++;
      } catch (_) {
        if (mounted) {
          showGlassNotice(context, '动作已加入训练，但保存到动作库失败', isError: true);
        }
      }
    }
  }

  Future<void> _saveCurrentAsTemplate(DateTime targetDate) async {
    if (_saving) return;
    final session = _effectiveSession(targetDate);
    if (session.blocks.isEmpty) return;
    final key = dayKey(targetDate);
    final activeTpl = _templateById(session.templateId) ??
        _templateById(_selectedTemplateByDate[key]) ??
        _scheduledTemplate(targetDate);
    final name = await promptText(
      context,
      '存为训练模板',
      initial: activeTpl?.name ?? session.templateName ?? '我的自定义训练',
    );
    if (name == null || name.trim().isEmpty || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      final latestTemplates = await loadWorkoutTemplates();
      final created = WorkoutTemplate(
        id: 'tpl_${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        exercises: [for (final b in session.blocks) b.exercise],
      );
      final next = List<WorkoutTemplate>.from(latestTemplates)..add(created);
      await saveWorkoutTemplates(next);
      if (mounted) {
        setState(() => _templates = next);
      }
      _notifyPlanChanged();
      if (mounted) {
        showGlassNotice(context, '已保存模板「${created.name}」');
      }
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '保存模板失败，请重试', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completeSet(
    DateTime targetDate,
    int index, {
    int? targetCount,
  }) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final current = _effectiveSession(targetDate);
    if (index < 0 || index >= current.blocks.length) return;
    final block = current.blocks[index];
    final nextDone = targetCount ?? (block.completedSets + 1);
    final clamped = nextDone.clamp(0, block.exercise.sets);
    if (clamped == block.completedSets) return;

    final increasing = clamped > block.completedSets;
    final wasComplete =
        current.plannedSets > 0 && current.completedSets >= current.plannedSets;
    final blocks = List<WorkoutBlock>.from(current.blocks)
      ..[index] = block.copyWith(completedSets: clamped);
    final nextSession = current.copyWith(rested: false, blocks: blocks);
    final nowComplete = nextSession.plannedSets > 0 &&
        nextSession.completedSets >= nextSession.plannedSets;
    if (!wasComplete && nowComplete) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    final saved = await _saveSession(nextSession);

    if (saved &&
        dateOnly(targetDate) == dateOnly(today) &&
        increasing &&
        _autoRest &&
        clamped < block.exercise.sets) {
      final sec = parseRestSeconds(block.exercise.rest);
      if (sec != null) {
        _rest.start(sec, block.exercise.name);
      }
    }
  }

  Future<void> _undoSet(DateTime targetDate, int index) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final current = _effectiveSession(targetDate);
    if (index < 0 || index >= current.blocks.length) return;
    final block = current.blocks[index];
    if (block.completedSets <= 0) return;
    final blocks = List<WorkoutBlock>.from(current.blocks)
      ..[index] = block.copyWith(completedSets: block.completedSets - 1);
    await _saveSession(current.copyWith(blocks: blocks));
  }

  int _parseDefaultReps(String raw) =>
      int.tryParse(RegExp(r'\d+').firstMatch(raw)?.group(0) ?? '') ?? 10;

  Future<void> _logWeight(DateTime targetDate, int index) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final current = _effectiveSession(targetDate);
    if (index < 0 || index >= current.blocks.length) return;
    final block = current.blocks[index];
    final name = block.exercise.name;
    final latest = _latestLogByExercise[name];
    final pr = _prByExercise[name];
    final currentClock = now;
    final logDate = dateOnly(targetDate) == dateOnly(today)
        ? currentClock
        : DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            currentClock.hour,
            currentClock.minute,
            currentClock.second,
          );
    final logged = await showWeightLogSheet(
      context,
      exerciseName: name,
      defaultSets: block.exercise.sets,
      defaultReps: _parseDefaultReps(block.exercise.reps),
      latestLog: latest,
      personalRecord: pr,
      logDate: logDate,
    );
    if (logged == null || !mounted) return;
    await _loadLogsOnly();
    if (mounted) {
      showGlassNotice(
        context,
        '已记录 $name ${_fmtWeight(logged.weightKg)}kg',
        icon: Icons.fitness_center_rounded,
      );
    }
  }

  void _startRestForBlock(Exercise ex) {
    final sec = parseRestSeconds(ex.rest) ?? 90;
    _rest.start(sec, ex.name);
  }

  Future<void> _editBlock(DateTime targetDate, int index) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final current = _effectiveSession(targetDate);
    if (index < 0 || index >= current.blocks.length) return;
    final edited = await editExercise(
      context,
      initial: current.blocks[index].exercise,
    );
    if (edited == null || !mounted) return;
    final blocks = List<WorkoutBlock>.from(current.blocks);
    blocks[index] = blocks[index].copyWith(
      exercise: edited,
      completedSets: blocks[index].completedSets.clamp(0, edited.sets),
    );
    await _saveSession(current.copyWith(blocks: blocks));
  }

  Future<void> _moveBlock(DateTime targetDate, int index, int delta) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final current = _effectiveSession(targetDate);
    final target = index + delta;
    if (target < 0 || target >= current.blocks.length) return;
    final blocks = List<WorkoutBlock>.from(current.blocks);
    final item = blocks.removeAt(index);
    blocks.insert(target, item);
    await _saveSession(current.copyWith(blocks: blocks));
  }

  Future<void> _removeBlock(DateTime targetDate, int index) async {
    if (_saving || !_isDateEditable(targetDate)) return;
    final current = _effectiveSession(targetDate);
    if (index < 0 || index >= current.blocks.length) return;
    final removed = current.blocks[index];
    final blocks = List<WorkoutBlock>.from(current.blocks)..removeAt(index);
    final saved = await _saveSession(current.copyWith(blocks: blocks));
    if (!saved || !mounted) return;
    showUndoNotice(context, '已移除 ${removed.exercise.name}', onUndo: () async {
      if (!mounted || _saving) return;
      final latest = _effectiveSession(targetDate);
      if (latest.rested || latest.blocks.any((b) => b.id == removed.id)) {
        return;
      }
      final restored = List<WorkoutBlock>.from(latest.blocks)
        ..insert(index.clamp(0, latest.blocks.length), removed);
      await _saveSession(latest.copyWith(rested: false, blocks: restored));
    });
  }

  Future<void> _showBlockMenu(
    BuildContext btnContext,
    DateTime targetDate,
    int index,
    int totalBlocks,
  ) async {
    final p = context.palette;
    final action = await showGlassMenu<String>(
      context: context,
      anchorContext: btnContext,
      title: '第 ${index + 1} 项 · 动作操作',
      items: [
        GlassMenuItem(
          value: 'edit',
          label: '编辑组次',
          icon: Icons.tune_rounded,
          color: p.primary,
        ),
        GlassMenuItem(
          value: 'weight',
          label: '记录负重',
          icon: Icons.fitness_center_rounded,
          color: p.accent,
        ),
        if (index > 0)
          const GlassMenuItem(
            value: 'up',
            label: '上移',
            icon: Icons.arrow_upward_rounded,
          ),
        if (index < totalBlocks - 1)
          const GlassMenuItem(
            value: 'down',
            label: '下移',
            icon: Icons.arrow_downward_rounded,
          ),
        const GlassMenuItem(
          value: 'remove',
          label: '移除项目（可撤销）',
          icon: Icons.delete_outline_rounded,
          isDanger: true,
          hasTopDivider: true,
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        await _editBlock(targetDate, index);
      case 'weight':
        await _logWeight(targetDate, index);
      case 'up':
        await _moveBlock(targetDate, index, -1);
      case 'down':
        await _moveBlock(targetDate, index, 1);
      case 'remove':
        await _removeBlock(targetDate, index);
    }
  }

  String _fmtWeight(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_loading) return const LoadingView();
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, style: TextStyle(color: p.textPrimary)),
              const SizedBox(height: 10),
              TextButton(onPressed: _loadAll, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final currentDate = recordDate;
    final currentKey = dayKey(currentDate);
    if (_activeScrollDateKey != currentKey) {
      _activeScrollDateKey = currentKey;
      _restoringScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (!mounted ||
              _activeScrollDateKey != currentKey ||
              !_scrollController.hasClients) {
            return;
          }
          final target = _scrollOffsets[currentKey] ?? 0.0;
          final max = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(target.clamp(0.0, max));
        } finally {
          if (_activeScrollDateKey == currentKey) {
            _restoringScroll = false;
          }
        }
      });
    }
    final existingSession = _sessions[currentKey];
    final session = _effectiveSession(currentDate);
    final scheduledTpl = _scheduledTemplate(currentDate);
    final persistedTpl = _templateById(session.templateId);
    final selectedTpl = _templateById(_selectedTemplateByDate[currentKey]);
    final activeTpl = persistedTpl ??
        (session.templateName != null ? null : (selectedTpl ?? scheduledTpl));
    final resolvedTplName =
        persistedTpl?.name ?? session.templateName ?? activeTpl?.name;
    final isFuture = !_isDateEditable(currentDate);
    final blocks = session.blocks;
    final planned = session.plannedSets;
    final completed = session.completedSets;
    final progress = session.rested
        ? 1.0
        : planned > 0
            ? (completed / planned).clamp(0.0, 1.0)
            : 0.0;

    final muscles = session.rested || blocks.isEmpty
        ? const <String>{}
        : inferMuscleGroups(blocks.map((b) => b.exercise));

    final heroTitle = session.rested
        ? '今日休整'
        : (resolvedTplName ?? (blocks.isNotEmpty ? '自由训练' : '未排计划'));

    void stepDate(int delta) {
      if (_saving) return;
      final d = dateOnly(currentDate);
      final target = DateTime(d.year, d.month, d.day + delta);
      if (target.isBefore(_minDate)) return;
      selectRecordDate(target);
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final hasProgress = !session.rested && planned > 0;
    final futurePillHeight =
        isFuture ? textScaler.scale(11.0) * 1.45 + 10.0 : 0.0;
    final row1Height = math.max(
      28.0,
      math.max(textScaler.scale(17.5) * 1.32, futurePillHeight) + 2.0,
    );
    final row2Height = textScaler.scale(hasProgress ? 15.0 : 12.0) * 1.38 + 2.0;
    final progressHeight = hasProgress ? 12.0 : 0.0;
    final heroContentHeight =
        math.max(60.0, row1Height + 6.0 + row2Height + progressHeight);
    final heroHeaderExtent = (heroContentHeight + 44.0).ceilToDouble();

    return Column(
      children: [
        if (widget.showRestTimer)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [RestTimerPill(controller: _rest)],
            ),
          ),
        Expanded(
          child: HorizontalDaySwipe(
            onPrevious: () {
              _skipNextDayAnim = true;
              stepDate(-1);
            },
            onNext: () {
              _skipNextDayAnim = true;
              stepDate(1);
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: WeekStripBar(
                      date: currentDate,
                      today: today,
                      enabled: !_saving,
                      allowFutureSelection: true,
                      statusForDay: _statusForDay,
                      onChanged: selectRecordDate,
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeroHeaderDelegate(
                    extent: heroHeaderExtent,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_scrollController.hasClients &&
                            _scrollController.offset > 12) {
                          _scrollController.animateTo(
                            0,
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: _dayTransitionWrap(
                        _buildHeroCard(
                          context: context,
                          targetDate: currentDate,
                          heroTitle: heroTitle,
                          completed: completed,
                          planned: planned,
                          progress: progress,
                          muscles: muscles,
                          session: session,
                          existingSession: existingSession,
                          scheduledTpl: scheduledTpl,
                          isFuture: isFuture,
                        ),
                      ),
                    ),
                  ),
                ),
                _SliverClipOverlap(
                  child: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 112),
                    sliver: blocks.isEmpty
                        ? SliverToBoxAdapter(
                            child: _dayTransitionWrap(
                              _buildEmptyOrRestCard(
                                context: context,
                                targetDate: currentDate,
                                rested: session.rested,
                                hasScheduled: scheduledTpl != null,
                                isFuture: isFuture,
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildListDelegate([
                              for (var i = 0; i < blocks.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _dayTransitionWrap(
                                    _buildBlockCard(
                                      context: context,
                                      targetDate: currentDate,
                                      dateKeyStr: currentKey,
                                      index: i,
                                      block: blocks[i],
                                      totalBlocks: blocks.length,
                                      isFuture: isFuture,
                                    ),
                                  ),
                                ),
                              if (!isFuture) ...[
                                const SizedBox(height: 2),
                                _dayTransitionWrap(
                                  _buildBottomAddBar(context, currentDate),
                                ),
                              ],
                            ]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required DateTime targetDate,
    required String heroTitle,
    required int completed,
    required int planned,
    required double progress,
    required Set<String> muscles,
    required DailyWorkout session,
    required DailyWorkout? existingSession,
    required WorkoutTemplate? scheduledTpl,
    required bool isFuture,
  }) {
    final p = context.palette;
    final percent = (progress * 100).round();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final blockCount = session.blocks.length;

    return SurfaceCard(
      key: const Key('daily-suggestion'),
      elevated: true,
      highlighted: !session.rested && planned > 0 && completed >= planned,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MuscleBodyGraphic(activeGroups: muscles, size: 60),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        heroTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    if (isFuture) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        flex: 2,
                        child: StatusPill(label: '未来日期预览', color: p.accent),
                      ),
                    ],
                    if (!isFuture) ...[
                      const SizedBox(width: 6),
                      Builder(
                        builder: (btnCtx) => Tooltip(
                          message: '今日方案操作',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: const Key('hero-menu'),
                              customBorder: const CircleBorder(),
                              onTap: _saving
                                  ? null
                                  : () => _showHeroMenu(
                                        btnCtx,
                                        targetDate,
                                        session,
                                        existingSession,
                                        scheduledTpl,
                                      ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.isDark
                                      ? Colors.white.withValues(alpha: .07)
                                      : Colors.black.withValues(alpha: .045),
                                  border: Border.all(
                                    color: p.borderSubtle,
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 16,
                                  color: p.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: session.rested || planned == 0
                          ? Text(
                              session.rested ? '主动恢复充能' : '点击下方添加训练动作',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                                color: p.textSecondary,
                              ),
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$completed',
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                      color: completed > 0
                                          ? p.primary
                                          : p.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / $planned 组 · $blockCount 动作',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.25,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                    if (!session.rested && planned > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        completed >= planned ? '✓ 已完成' : '$percent%',
                        style: TextStyle(
                          fontSize: completed >= planned ? 12.5 : 13,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color:
                              completed >= planned ? p.primary : p.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!session.rested && planned > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      height: 6,
                      width: double.infinity,
                      color: p.isDark
                          ? Colors.white.withValues(alpha: .09)
                          : Colors.black.withValues(alpha: .065),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: progress),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value.clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: p.primaryGradient,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrRestCard({
    required BuildContext context,
    required DateTime targetDate,
    required bool rested,
    required bool hasScheduled,
    required bool isFuture,
  }) {
    final p = context.palette;
    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: p.isDark ? .16 : .11),
              shape: BoxShape.circle,
              border: Border.all(color: p.primary.withValues(alpha: .32)),
            ),
            child: Icon(
              rested ? Icons.spa_rounded : Icons.bolt_rounded,
              color: p.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rested ? '今日主动恢复' : '准备开练',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          if (recoveryNotes[targetDate.weekday - 1].isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              recoveryNotes[targetDate.weekday - 1],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: p.textSecondary,
              ),
            ),
          ],
          if (!isFuture) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (rested)
                  OutlinedButton(
                    onPressed: _saving ? null : () => _cancelRest(targetDate),
                    child: const Text('取消休息标记'),
                  ),
                if (rested && hasScheduled)
                  FilledButton.icon(
                    key: const Key('use-suggestion'),
                    onPressed:
                        _saving ? null : () => _applyScheduledNow(targetDate),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('载入今日模板'),
                  )
                else if (rested)
                  FilledButton.icon(
                    key: const Key('switch-template'),
                    onPressed:
                        _saving ? null : () => _switchTemplate(targetDate),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('选择训练模板'),
                  ),
                FilledButton.icon(
                  key: const Key('choose-blocks'),
                  onPressed: _saving
                      ? null
                      : () => _addFromPicker(targetDate, initialSource: 1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('添加动作'),
                ),
                if (!rested)
                  OutlinedButton(
                    key: const Key('record-rest'),
                    onPressed: _saving ? null : () => _markRest(targetDate),
                    child: const Text('标记休息'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockCard({
    required BuildContext context,
    required DateTime targetDate,
    required String dateKeyStr,
    required int index,
    required WorkoutBlock block,
    required int totalBlocks,
    required bool isFuture,
  }) {
    final p = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final ex = block.exercise;
    final done = block.completedSets;
    final total = ex.sets;
    final allDone = total > 0 && done >= total;
    final latestLog = _latestLogByExercise[ex.name];
    final pr = _prByExercise[ex.name];
    final displayWeight = latestLog ?? pr;
    final isPrWeight = latestLog != null &&
        pr != null &&
        latestLog.estimated1RM >= pr.estimated1RM;
    final restSec = parseRestSeconds(ex.rest);
    final noteKey = '$dateKeyStr|${block.id}';
    final noteText = ex.note?.trim() ?? '';
    final hasNote = noteText.isNotEmpty;
    final isNoteExpanded = hasNote && _expandedNotes.contains(noteKey);

    Widget buildSetPill(int s, {required bool expanded}) {
      final active = s < done;
      final pill = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: isFuture || _saving
              ? null
              : () => _completeSet(
                    targetDate,
                    index,
                    targetCount: active && s + 1 == done ? s : s + 1,
                  ),
          child: Container(
            height: 34,
            width: expanded ? null : 38,
            decoration: BoxDecoration(
              gradient: active ? p.primaryGradient : null,
              color: active
                  ? null
                  : (p.isDark
                      ? Colors.white.withValues(alpha: .06)
                      : Colors.black.withValues(alpha: .04)),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color:
                    active ? p.primary.withValues(alpha: .65) : p.borderSubtle,
                width: 0.85,
              ),
            ),
            child: Center(
              child: active
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: p.onPrimary,
                    )
                  : Text(
                      '${s + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: p.textSecondary,
                      ),
                    ),
            ),
          ),
        ),
      );
      return expanded ? Expanded(child: pill) : pill;
    }

    return SurfaceCard(
      key: ValueKey('workout-block-$index'),
      highlighted: allDone,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExerciseMark(ex.name, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: !hasNote
                          ? null
                          : () => setState(() {
                                if (!_expandedNotes.add(noteKey)) {
                                  _expandedNotes.remove(noteKey);
                                }
                              }),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              ex.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                          if (hasNote) ...[
                            const SizedBox(width: 3),
                            AnimatedRotation(
                              turns: isNoteExpanded ? 0.5 : 0.0,
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.expand_more_rounded,
                                size: 15,
                                color: p.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ex.sets} 组 × ${ex.reps}${ex.rest.isNotEmpty ? ' · 休 ${ex.rest}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.textSecondary,
                      ),
                    ),
                    if (isNoteExpanded) ...[
                      const SizedBox(height: 6),
                      Text(
                        noteText,
                        style: TextStyle(
                          fontSize: 12,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isFuture)
                Builder(
                  builder: (btnCtx) => IconButton(
                    key: ValueKey('block-menu-$index'),
                    tooltip: '动作操作',
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    constraints:
                        const BoxConstraints.tightFor(width: 34, height: 34),
                    padding: EdgeInsets.zero,
                    onPressed: _saving
                        ? null
                        : () => _showBlockMenu(
                              btnCtx,
                              targetDate,
                              index,
                              totalBlocks,
                            ),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: p.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (total <= 6)
            Row(
              children: [
                for (var s = 0; s < total; s++) ...[
                  if (s > 0) const SizedBox(width: 6),
                  buildSetPill(s, expanded: true),
                ],
              ],
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var s = 0; s < total; s++)
                  buildSetPill(s, expanded: false),
              ],
            ),
          if (!isFuture) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 290 ||
                    MediaQuery.textScalerOf(context).scale(12) > 17;
                return Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (done > 0)
                            _miniActionChip(
                              key: ValueKey('undo-set-$index'),
                              tooltip: '撤销一组',
                              icon: Icons.undo_rounded,
                              label: null,
                              color: p.textSecondary,
                              onTap: _saving
                                  ? null
                                  : () => _undoSet(targetDate, index),
                              p: p,
                            ),
                          _miniActionChip(
                            key: ValueKey('log-weight-$index'),
                            tooltip: '记负重',
                            icon: isPrWeight
                                ? Icons.emoji_events_rounded
                                : Icons.monitor_weight_outlined,
                            label: displayWeight != null
                                ? '${_fmtWeight(displayWeight.weightKg)}kg'
                                : (compact ? null : '记负重'),
                            color: displayWeight != null
                                ? p.warning
                                : p.textSecondary,
                            tinted: displayWeight != null,
                            onTap: _saving
                                ? null
                                : () => _logWeight(targetDate, index),
                            p: p,
                          ),
                          if (restSec != null)
                            _miniActionChip(
                              key: ValueKey('start-rest-$index'),
                              tooltip: '开始休息计时',
                              icon: Icons.timer_outlined,
                              label: compact ? null : ex.rest,
                              color: p.accent,
                              onTap: () => _startRestForBlock(ex),
                              p: p,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('complete-set-$index'),
                        borderRadius: BorderRadius.circular(999),
                        onTap: allDone || _saving
                            ? null
                            : () => _completeSet(targetDate, index),
                        child: Ink(
                          height: 36,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 12 : 15,
                          ),
                          decoration: BoxDecoration(
                            gradient: allDone ? null : p.primaryGradient,
                            color: allDone
                                ? p.primary.withValues(
                                    alpha: p.isDark ? .18 : .13,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(999),
                            border: allDone
                                ? Border.all(
                                    color: p.primary.withValues(alpha: .48),
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allDone
                                    ? Icons.done_all_rounded
                                    : Icons.check_rounded,
                                size: 17,
                                color: allDone ? p.primary : p.onPrimary,
                              ),
                              if (!compact) ...[
                                const SizedBox(width: 5),
                                Text(
                                  allDone ? '已完成' : '记一组',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: allDone ? p.primary : p.onPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniActionChip({
    required Key key,
    required String tooltip,
    required IconData icon,
    required String? label,
    required Color color,
    required VoidCallback? onTap,
    required AppPalette p,
    bool tinted = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 34,
            padding: EdgeInsets.symmetric(horizontal: label == null ? 9 : 11),
            decoration: BoxDecoration(
              color: tinted
                  ? color.withValues(alpha: p.isDark ? .14 : .10)
                  : (p.isDark
                      ? Colors.white.withValues(alpha: .06)
                      : Colors.black.withValues(alpha: .04)),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: tinted
                    ? color.withValues(alpha: p.isDark ? .34 : .26)
                    : p.borderSubtle,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15.5, color: color),
                if (label != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAddBar(BuildContext context, DateTime targetDate) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: SurfaceCard(
            key: const Key('choose-blocks'),
            radius: 18,
            onTap: _saving
                ? null
                : () => _addFromPicker(targetDate, initialSource: 1),
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 18, color: p.primary),
                const SizedBox(width: 6),
                Text(
                  '添加动作',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SurfaceCard(
          radius: 18,
          onTap: _saving ? null : () => _addCustomExercise(targetDate),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Tooltip(
            message: '自定义动作',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 17, color: p.accent),
                const SizedBox(width: 5),
                Text(
                  '自建',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PinnedHeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  const _PinnedHeroHeaderDelegate({
    required this.extent,
    required this.child,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final p = context.palette;
    final pinned = shrinkOffset > 0.5 || overlapsContent;
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Align(
          alignment: Alignment.center,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: pinned
                  ? [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: p.isDark ? .26 : .07),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeroHeaderDelegate oldDelegate) =>
      oldDelegate.extent != extent || oldDelegate.child != child;
}

class _SliverClipOverlap extends SingleChildRenderObjectWidget {
  const _SliverClipOverlap({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverClipOverlap();
}

class _RenderSliverClipOverlap extends RenderProxySliver {
  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || !(child.geometry?.visible ?? false)) {
      layer = null;
      return;
    }
    final overlap = constraints.overlap;
    if (overlap <= 2.0) {
      layer = null;
      context.paintChild(child, offset);
      return;
    }
    final clipTop = overlap - 2.0;
    final clipBottom = math.max(clipTop, constraints.remainingPaintExtent);
    layer = context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTRB(0.0, clipTop, constraints.crossAxisExtent, clipBottom),
      super.paint,
      clipBehavior: Clip.hardEdge,
      oldLayer: layer as ClipRectLayer?,
    );
  }

  @override
  Rect? describeApproximatePaintClip(covariant RenderObject child) {
    final overlap = constraints.overlap;
    if (overlap <= 2.0) return super.describeApproximatePaintClip(child);
    final clipTop = overlap - 2.0;
    final clipBottom = math.max(clipTop, constraints.remainingPaintExtent);
    return Rect.fromLTRB(0.0, clipTop, constraints.crossAxisExtent, clipBottom);
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (constraints.overlap > 2.0 &&
        mainAxisPosition < constraints.overlap - 2.0) {
      return false;
    }
    return super.hitTestChildren(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }
}
