import 'package:flutter/material.dart';
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
import '../widgets/kinetic_ring.dart';
import '../widgets/loading_view.dart';
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
    with WidgetsBindingObserver, DailyRecordDate<WorkoutPage> {
  @override
  DateTime get now => widget.now?.call() ?? DateTime.now();

  Map<String, DailyWorkout> _sessions = {};
  List<WorkoutTemplate> _templates = [];
  List<String> _schedule = List.from(defaultSchedule);
  List<ExerciseLog> _logs = [];
  bool _loading = true;
  bool _busy = false;
  bool _autoRest = false;
  String? _error;
  int _generation = 0;
  int _nextId = 0;
  late final RestCountdown _rest;

  @override
  void initState() {
    super.initState();
    _rest = widget.restController ??
        RestCountdown(
          now: () => now,
          onFinished: () => HapticFeedback.heavyImpact(),
        );
    workoutDataRevision.addListener(_reload);
    workoutPlanRevision.addListener(_reload);
    restTimerPreferenceRevision.addListener(_reload);
    exerciseLogsRevision.addListener(_reloadLogsOnly);
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.restController == null) _rest.setActive(pageActive);
  }

  @override
  void dispose() {
    workoutDataRevision.removeListener(_reload);
    workoutPlanRevision.removeListener(_reload);
    restTimerPreferenceRevision.removeListener(_reload);
    exerciseLogsRevision.removeListener(_reloadLogsOnly);
    if (widget.restController == null) _rest.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (widget.restController == null) _rest.setActive(pageActive);
  }

  Future<void> _reloadLogsOnly() async {
    try {
      final logs = await loadExerciseLogs();
      if (mounted) setState(() => _logs = logs);
    } catch (_) {}
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    try {
      final sessions = await loadDailyWorkouts();
      final templates = await loadWorkoutTemplates();
      final schedule = await loadWeeklySchedule();
      final autoRest = await loadAutoRestTimer();
      final logs = await loadExerciseLogs();
      if (!mounted || generation != _generation) return;
      setState(() {
        _sessions = sessions;
        _templates = templates;
        _schedule = schedule;
        _autoRest = autoRest;
        _logs = logs;
        _loading = false;
        _error = null;
      });
      workoutHistoryRevision.value++;
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = '训练数据读取失败，原记录未被覆盖。请重试或先到设置导出备份。';
          _loading = false;
        });
      }
    }
  }

  WorkoutTemplate? _templateForDate(DateTime date) {
    final id = _schedule[date.weekday - 1];
    if (id.isEmpty) return null;
    for (final t in _templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Resolves the effective session for a date: saved custom record or auto-loaded fixed template.
  (DailyWorkout session, bool isAutoTemplate) _resolveDay(DateTime date) {
    final key = dayKey(date);
    final saved = _sessions[key];
    if (saved != null) return (saved, false);

    final template = _templateForDate(date);
    if (template != null && template.exercises.isNotEmpty) {
      return (
        DailyWorkout(
          date: key,
          blocks: [
            for (var i = 0; i < template.exercises.length; i++)
              WorkoutBlock(
                id: 'auto_${key}_$i',
                exercise: template.exercises[i],
              ),
          ],
        ),
        true,
      );
    }
    return (DailyWorkout(date: key), false);
  }

  DayStripStatus _statusForDay(DateTime day) {
    final (session, _) = _resolveDay(day);
    if (session.rested || session.blocks.isEmpty) return DayStripStatus.rest;
    if (session.plannedSets > 0 &&
        session.completedSets >= session.plannedSets) {
      return DayStripStatus.completed;
    }
    if (session.completedSets > 0) return DayStripStatus.partial;
    return DayStripStatus.planned;
  }

  bool get _isFuture => dateOnly(recordDate).isAfter(today);

  DailyWorkout _materializeForDate(DateTime date) {
    final (resolved, isAuto) = _resolveDay(date);
    if (!isAuto) return resolved;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return DailyWorkout(
      date: resolved.date,
      blocks: [
        for (var i = 0; i < resolved.blocks.length; i++)
          WorkoutBlock(
            id: 'block_${stamp}_${_nextId++}_$i',
            exercise: resolved.blocks[i].exercise,
            completedSets: resolved.blocks[i].completedSets,
          ),
      ],
      rested: resolved.rested,
    );
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<bool> _save(DailyWorkout session) async {
    if (_busy) return false;
    setState(() => _busy = true);
    _generation++;
    try {
      await saveDailyWorkout(session);
      if (mounted) setState(() => _sessions[session.date] = session);
      workoutHistoryRevision.value++;
      return true;
    } catch (_) {
      _message('保存失败，请重试；页面保留上一次成功保存的记录。');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(List<Exercise> exercises, DailyWorkout target) async {
    if (!mounted || exercises.isEmpty) return;
    final next = List<WorkoutBlock>.from(target.blocks);
    for (final exercise in exercises) {
      next.add(
        WorkoutBlock(
          id: 'block_${DateTime.now().microsecondsSinceEpoch}_${_nextId++}',
          exercise: exercise,
        ),
      );
    }
    await _save(target.copyWith(blocks: next, rested: false));
  }

  Future<void> _pick() async {
    if (_isFuture) return;
    final target = _materializeForDate(recordDate);
    final values = await pickExercises(context, _templates, initialSource: 1);
    if (values != null && mounted) await _add(values, target);
  }

  Future<void> _pickSuggestion() async {
    if (_isFuture) return;
    final suggestion = _templateForDate(recordDate);
    if (suggestion == null) return;
    final target = _materializeForDate(recordDate);
    final values = await pickExercises(context, [suggestion]);
    if (values != null && mounted) await _add(values, target);
  }

  Future<void> _custom({DailyWorkout? session, int? blockIndex}) async {
    if (_isFuture && session == null) return;
    final target = session ?? _materializeForDate(recordDate);
    final existingBlock = blockIndex == null ? null : target.blocks[blockIndex];
    final res = await editExerciseDetailed(
      context,
      initial: existingBlock?.exercise,
      offerSaveToLibrary: existingBlock == null,
    );
    if (!mounted || res == null) return;

    if (res.saveToLibrary) {
      try {
        await addLibraryExercise(
          LibraryExercise(
            id: 'lib_${DateTime.now().microsecondsSinceEpoch}',
            category: res.category,
            exercise: res.exercise,
          ),
        );
        exerciseLibraryRevision.value++;
      } catch (_) {}
    }

    if (existingBlock == null) {
      await _add([res.exercise], target);
      return;
    }
    if (res.exercise.sets < existingBlock.completedSets) {
      _message('计划组数不能小于已完成组数，请先撤销多余的组。');
      return;
    }
    await _save(
      target.copyWith(
        blocks: target.blocks
            .map((e) => e.id == existingBlock.id
                ? e.copyWith(exercise: res.exercise)
                : e)
            .toList(),
      ),
    );
  }

  Future<void> _complete(int index, {bool undo = false}) async {
    if (_isFuture || _busy) return;
    final target = _materializeForDate(recordDate);
    if (index < 0 || index >= target.blocks.length) return;
    final block = target.blocks[index];
    final count =
        (block.completedSets + (undo ? -1 : 1)).clamp(0, block.exercise.sets);
    if (count == block.completedSets) return;

    final success = await _save(
      target.copyWith(
        blocks: target.blocks
            .map((e) => e.id == block.id ? e.copyWith(completedSets: count) : e)
            .toList(),
      ),
    );
    if (!success || !mounted) return;
    HapticFeedback.lightImpact();

    if (!undo &&
        _autoRest &&
        target.date == dayKey(now) &&
        count < block.exercise.sets) {
      _startTimer(block.exercise);
    }
  }

  Future<void> _remove(DailyWorkout target, int index) async {
    final block = target.blocks[index];
    final updated = target.copyWith(
      blocks: target.blocks.where((e) => e.id != block.id).toList(),
    );
    if (!await _save(updated) || !mounted) return;

    showUndoNotice(context, '已移除 ${block.exercise.name}', onUndo: () async {
      if (!mounted) return;
      if (_busy) {
        _message('正在保存，请稍后重试');
        return;
      }
      final latest = _sessions[target.date];
      if (latest == null || latest.blocks.any((e) => e.id == block.id)) {
        return;
      }
      final blocks = List<WorkoutBlock>.from(latest.blocks)
        ..insert(index.clamp(0, latest.blocks.length), block);
      await _save(latest.copyWith(blocks: blocks, rested: false));
    });
  }

  Future<void> _move(DailyWorkout target, int index, int offset) async {
    final destination = index + offset;
    if (destination < 0 || destination >= target.blocks.length) return;
    final blocks = List<WorkoutBlock>.from(target.blocks);
    final block = blocks.removeAt(index);
    blocks.insert(destination, block);
    await _save(target.copyWith(blocks: blocks));
  }

  Future<void> _toggleRest(DailyWorkout session) async {
    if (_isFuture || _busy) return;
    final bound = _templateForDate(recordDate);
    if (session.rested) {
      if (bound != null && bound.exercises.isNotEmpty) {
        setState(() => _busy = true);
        try {
          await deleteDailyWorkout(session.date);
          if (mounted) setState(() => _sessions.remove(session.date));
          workoutHistoryRevision.value++;
        } catch (_) {
          _message('恢复模板失败，请重试');
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      } else {
        await _save(session.copyWith(rested: false));
      }
      return;
    }

    if (session.completedSets > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('标记今日为休息日？'),
          content: Text(
            '当天已有 ${session.completedSets} 组训练记录，标记休息将清空当天的训练项目。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认休息'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    await _save(
        DailyWorkout(date: session.date, blocks: const [], rested: true));
  }

  Future<void> _restoreFixedTemplate() async {
    if (_isFuture || _busy) return;
    final key = dayKey(recordDate);
    final saved = _sessions[key];
    if (saved == null) return;
    if (saved.completedSets > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('恢复当日固定模板？'),
          content: Text(
            '当天已有 ${saved.completedSets} 组完成记录，恢复固定模板将重置今天的动作与完成进度。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认恢复'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await deleteDailyWorkout(key);
      if (mounted) setState(() => _sessions.remove(key));
      workoutHistoryRevision.value++;
      _message('已恢复当日固定模板');
    } catch (_) {
      _message('恢复模板失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switchDayTemplate(DailyWorkout currentSession) async {
    if (_isFuture || _busy) return;
    final chosen = await showModalBottomSheet<WorkoutTemplate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
        title: '切换今日模板',
        subtitle: '仅影响今天训练内容，不修改每周固定安排',
        icon: Icons.swap_horiz_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in _templates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectionOption(
                  title: t.name,
                  subtitle:
                      '${t.exercises.length} 个动作 · ${t.exercises.fold<int>(0, (s, e) => s + e.sets)} 组',
                  leading: ExerciseMark(
                    t.exercises.isEmpty ? '' : t.exercises.first.name,
                    size: 38,
                  ),
                  selected: _templateForDate(recordDate)?.id == t.id,
                  onTap: () => Navigator.pop(ctx, t),
                ),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;

    var append = false;
    if (currentSession.completedSets > 0) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('应用「${chosen.name}」'),
          content: Text('今天已完成 ${currentSession.completedSets} 组训练，请选择应用方式：'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'append'),
              child: const Text('追加到当前'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: const Text('替换今日计划'),
            ),
          ],
        ),
      );
      if (action == null || !mounted) return;
      append = action == 'append';
    }

    final key = dayKey(recordDate);
    final newBlocks = instantiateTemplateBlocks(chosen, key, seed: _nextId++);
    if (append) {
      final base = _materializeForDate(recordDate);
      await _save(
        base.copyWith(blocks: [...base.blocks, ...newBlocks], rested: false),
      );
    } else {
      await _save(DailyWorkout(date: key, blocks: newBlocks, rested: false));
    }
  }

  Future<void> _saveAsTemplate(DailyWorkout session) async {
    final blocks = List<WorkoutBlock>.from(session.blocks);
    final name = await promptText(context, '把这组积木存成模板');
    if (name == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final templates = await loadWorkoutTemplates();
      templates.add(
        WorkoutTemplate(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          exercises: blocks.map((e) => e.exercise).toList(),
        ),
      );
      await saveWorkoutTemplates(templates);
      workoutPlanRevision.value++;
      _message('已保存为模板，可在「计划」页绑定到任意星期');
    } catch (_) {
      _message('模板保存失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveBlockToLibrary(Exercise exercise) async {
    try {
      final category =
          exercise.muscles.isNotEmpty ? exercise.muscles.first : '其他';
      await addLibraryExercise(
        LibraryExercise(
          id: 'lib_${DateTime.now().microsecondsSinceEpoch}',
          category: category,
          exercise: exercise,
        ),
      );
      exerciseLibraryRevision.value++;
      _message('已将「${exercise.name}」收入动作库');
    } catch (_) {
      _message('收入动作库失败，请重试');
    }
  }

  Future<void> _logWeight(Exercise exercise) async {
    final latest = exerciseHistory(_logs, exercise.name).firstOrNull;
    final pr = exercisePersonalRecord(_logs, exercise.name);
    final repMatch = RegExp(r'\d+').firstMatch(exercise.reps);
    final defaultReps = int.tryParse(repMatch?.group(0) ?? '') ?? 10;
    final saved = await showWeightLogSheet(
      context,
      exerciseName: exercise.name,
      defaultSets: exercise.sets,
      defaultReps: defaultReps,
      latestLog: latest,
      personalRecord: pr,
    );
    if (saved != null && mounted) {
      _message(
          '已记录 ${exercise.name} · ${_fmtWeight(saved.weightKg)}kg × ${saved.reps}');
    }
  }

  void _startTimer(Exercise exercise) {
    final seconds = parseRestSeconds(exercise.rest);
    if (seconds != null) {
      _rest.start(
        seconds,
        '${recordDate.month}/${recordDate.day} · ${exercise.name}',
      );
    }
  }

  static String _fmtWeight(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_loading) return const LoadingView();
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: p.textPrimary)),
              const SizedBox(height: 10),
              TextButton(onPressed: _reload, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final (session, isAutoTemplate) = _resolveDay(recordDate);
    final suggestion = _templateForDate(recordDate);
    final isFuture = _isFuture;
    final hasSavedOverride = _sessions.containsKey(session.date);
    final progress = session.plannedSets == 0
        ? 0.0
        : (session.completedSets / session.plannedSets).clamp(0.0, 1.0);
    final allDone = session.plannedSets > 0 && progress >= 1.0;

    return Column(
      children: [
        if (widget.showRestTimer)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: RestTimerPill(controller: _rest),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: WeekStripBar(
            date: recordDate,
            today: today,
            enabled: !_busy,
            allowFutureSelection: true,
            statusForDay: _statusForDay,
            onChanged: selectRecordDate,
          ),
        ),
        Expanded(
          child: HorizontalDaySwipe(
            onPrevious: () {
              final prev = DateTime(
                  recordDate.year, recordDate.month, recordDate.day - 1);
              if (!prev.isBefore(DateTime(2000))) selectRecordDate(prev);
            },
            onNext: () {
              final next = DateTime(
                  recordDate.year, recordDate.month, recordDate.day + 1);
              if (!next.isAfter(today)) selectRecordDate(next);
            },
            child: ListView(
              key: PageStorageKey('daily-workout-scroll-${dayKey(recordDate)}'),
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
              children: [
                if (isFuture) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    backgroundColor:
                        p.accent.withValues(alpha: p.isDark ? .14 : .08),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 18, color: p.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '未来日期预览 · 仅展示当日固定模板，不可打卡记录',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _buildHeroCard(
                  context,
                  session: session,
                  suggestion: suggestion,
                  isAutoTemplate: isAutoTemplate,
                  hasSavedOverride: hasSavedOverride,
                  progress: progress,
                  allDone: allDone,
                  isFuture: isFuture,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.rested ? '恢复安排' : '今日动作',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    if (!isFuture && !session.rested)
                      TextButton.icon(
                        key: const Key('choose-blocks'),
                        onPressed: _busy ? null : _pick,
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('从动作库添加'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (session.blocks.isEmpty)
                  _buildEmptyCard(
                    context,
                    session: session,
                    suggestion: suggestion,
                    isFuture: isFuture,
                  ),
                for (var i = 0; i < session.blocks.length; i++)
                  Padding(
                    key: ValueKey('${session.date}-${session.blocks[i].id}'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _blockCard(session, i, isAutoTemplate, isFuture),
                  ),
                if (!isFuture && !session.rested) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: _busy ? null : () => _custom(),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('自定义项目'),
                      ),
                      if (session.blocks.isNotEmpty) ...[
                        Container(
                          height: 14,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: p.borderSubtle,
                        ),
                        TextButton.icon(
                          onPressed:
                              _busy ? null : () => _saveAsTemplate(session),
                          icon:
                              const Icon(Icons.bookmark_add_outlined, size: 15),
                          label: const Text('存为新模板'),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required DailyWorkout session,
    required WorkoutTemplate? suggestion,
    required bool isAutoTemplate,
    required bool hasSavedOverride,
    required double progress,
    required bool allDone,
    required bool isFuture,
  }) {
    final p = context.palette;
    final tagLabel = session.rested
        ? '已标记休息'
        : isAutoTemplate
            ? '周${[
                '一',
                '二',
                '三',
                '四',
                '五',
                '六',
                '日'
              ][recordDate.weekday - 1]}固定模板'
            : suggestion == null
                ? '休息 / 恢复'
                : '今日已定制';

    return SurfaceCard(
      key: const Key('daily-suggestion'),
      highlighted: allDone,
      elevated: true,
      gradient: allDone
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                p.primary.withValues(alpha: p.isDark ? .18 : .12),
                p.surfaceElevated,
              ],
            )
          : null,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: StatusPill(
                            label: allDone ? '今日训练达成' : tagLabel,
                            color: allDone
                                ? p.success
                                : session.rested
                                    ? p.accent
                                    : p.primary,
                            icon: allDone
                                ? Icons.check_circle_rounded
                                : session.rested
                                    ? Icons.spa_outlined
                                    : Icons.auto_awesome_rounded,
                          ),
                        ),
                        if (suggestion != null &&
                            suggestion.note.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(99),
                            onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(suggestion.name),
                                content: Text(suggestion.note),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('知道了'),
                                  ),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: p.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.rested
                          ? '主动休息恢复日'
                          : suggestion?.name ??
                              (session.blocks.isEmpty ? '自由安排 / 休息' : '自由组合训练'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _heroMetric('${session.blocks.length}', '个项目', p),
                        _heroMetric(
                          '${session.completedSets}/${session.plannedSets}',
                          '完成组数',
                          p,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              KineticProgressRing(
                progress: progress,
                size: 76,
                strokeWidth: 7.5,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: p.borderSubtle),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!isFuture)
                  _heroChip(
                    key: const Key('switch-template'),
                    icon: Icons.swap_horiz_rounded,
                    label: '切换模板',
                    onTap: _busy ? null : () => _switchDayTemplate(session),
                    p: p,
                  ),
                if (!isFuture && suggestion != null) ...[
                  const SizedBox(width: 8),
                  _heroChip(
                    key: const Key('use-suggestion'),
                    icon: Icons.playlist_add_check_rounded,
                    label: '挑选模板动作',
                    onTap: _busy ? null : _pickSuggestion,
                    p: p,
                  ),
                ],
                if (!isFuture && hasSavedOverride && suggestion != null) ...[
                  const SizedBox(width: 8),
                  _heroChip(
                    key: const Key('restore-template'),
                    icon: Icons.restart_alt_rounded,
                    label: '恢复固定模板',
                    onTap: _busy ? null : _restoreFixedTemplate,
                    p: p,
                  ),
                ],
                if (!isFuture && session.blocks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _heroChip(
                    key: const Key('record-rest'),
                    icon: Icons.spa_outlined,
                    label: '标记休息',
                    onTap: _busy ? null : () => _toggleRest(session),
                    p: p,
                  ),
                ],
                const SizedBox(width: 8),
                _heroChip(
                  icon: Icons.tune_rounded,
                  label: '编排每周模板',
                  onTap: _busy
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TemplateManagerPage(),
                            ),
                          ),
                  p: p,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String value, String label, AppPalette p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: p.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: p.textSecondary),
          ),
        ],
      );

  Widget _heroChip({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required AppPalette p,
  }) =>
      Material(
        color: p.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: p.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: key,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: p.primary),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildEmptyCard(
    BuildContext context, {
    required DailyWorkout session,
    required WorkoutTemplate? suggestion,
    required bool isFuture,
  }) {
    final p = context.palette;
    final recNote = recoveryNotes[recordDate.weekday - 1];
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: -.12,
                child: const ExerciseMark('平板卧推', size: 44),
              ),
              const SizedBox(width: 10),
              Transform.translate(
                offset: const Offset(0, -8),
                child: const ExerciseMark('腿', size: 50),
              ),
              const SizedBox(width: 10),
              Transform.rotate(
                angle: .12,
                child: const ExerciseMark('散步', size: 44),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            session.rested ? '今日已标记休息' : '暂无训练项目',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recNote.isNotEmpty ? recNote : '今天没有固定安排，你可以随时挑选模板或从动作库添加项目。',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12.5, height: 1.5, color: p.textSecondary),
          ),
          if (!isFuture) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (suggestion != null && suggestion.exercises.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _busy ? null : _restoreFixedTemplate,
                    icon: const Icon(Icons.restart_alt_rounded, size: 17),
                    label: const Text('载入今日固定模板'),
                  ),
                OutlinedButton(
                  key: const Key('record-rest'),
                  onPressed: _busy ? null : () => _toggleRest(session),
                  child: Text(session.rested ? '取消休息标记' : '标记休息'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _blockCard(
    DailyWorkout session,
    int index,
    bool isAutoTemplate,
    bool isFuture,
  ) {
    final p = context.palette;
    final block = session.blocks[index];
    final exercise = block.exercise;
    final complete = block.completedSets == exercise.sets;
    final latestLog = exerciseHistory(_logs, exercise.name).firstOrNull;
    final prLog = exercisePersonalRecord(_logs, exercise.name);
    final repsText =
        '${exercise.sets} 组 · ${exercise.reps}${RegExp(r'[a-zA-Z分钟秒]').hasMatch(exercise.reps) ? '' : ' 次'}'
        '${exercise.rest.isNotEmpty ? ' · 休 ${exercise.rest}' : ''}';

    return SurfaceCard(
      key: ValueKey('workout-block-$index'),
      highlighted: complete,
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 12),
      child: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: ExpansionTile(
              key: PageStorageKey(
                  'exercise-details-${session.date}-${block.id}'),
              minTileHeight: 58,
              tilePadding: EdgeInsets.zero,
              dense: true,
              shape: const Border(),
              collapsedShape: const Border(),
              leading: ExerciseMark(exercise.name, size: 44),
              trailing:
                  isFuture ? null : _blockMenu(session, index, isAutoTemplate),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  if (exercise.isStar) ...[
                    const SizedBox(width: 5),
                    Icon(Icons.star_rounded, size: 15, color: p.warning),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      repsText,
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                    if (latestLog != null && latestLog.weightKg > 0)
                      StatusPill(
                        label: prLog != null &&
                                prLog.estimated1RM == latestLog.estimated1RM
                            ? 'PR ${_fmtWeight(prLog.weightKg)}kg×${prLog.reps}'
                            : '上次 ${_fmtWeight(latestLog.weightKg)}kg×${latestLog.reps}',
                        color: p.accent,
                      ),
                  ],
                ),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 10),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    exercise.note?.isNotEmpty == true
                        ? exercise.note!
                        : '按当天状态稳定控制离心与发力；点击右侧菜单可调整组数与次数。',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: p.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var s = 0; s < exercise.sets.clamp(0, 12); s++)
                      GestureDetector(
                        onTap: isFuture || _busy
                            ? null
                            : () {
                                if (s == block.completedSets) {
                                  _complete(index);
                                } else if (s == block.completedSets - 1) {
                                  _complete(index, undo: true);
                                }
                              },
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 160),
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: s < block.completedSets
                                ? p.primaryGradient
                                : null,
                            color:
                                s < block.completedSets ? null : p.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: s == block.completedSets && !isFuture
                                ? Border.all(
                                    color: p.primary.withValues(alpha: .45),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: s < block.completedSets
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: p.onPrimary,
                                )
                              : Text(
                                  '${s + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${block.completedSets}/${exercise.sets} 组',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: complete ? p.primary : p.textSecondary,
                ),
              ),
            ],
          ),
          if (!isFuture) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        key: ValueKey('undo-set-$index'),
                        tooltip: '撤销上一组',
                        visualDensity: VisualDensity.compact,
                        onPressed: _busy || block.completedSets == 0
                            ? null
                            : () => _complete(index, undo: true),
                        icon: Icon(
                          Icons.undo_rounded,
                          size: 18,
                          color: block.completedSets == 0
                              ? p.textTertiary.withValues(alpha: .35)
                              : p.textSecondary,
                        ),
                      ),
                      IconButton(
                        key: ValueKey('log-weight-$index'),
                        tooltip: '记录负重',
                        visualDensity: VisualDensity.compact,
                        onPressed: _busy ? null : () => _logWeight(exercise),
                        icon: Icon(
                          Icons.fitness_center_rounded,
                          size: 17,
                          color: p.textSecondary,
                        ),
                      ),
                      if (parseRestSeconds(exercise.rest) != null)
                        IconButton(
                          key: ValueKey('start-rest-$index'),
                          tooltip: '休息 ${exercise.rest}',
                          visualDensity: VisualDensity.compact,
                          onPressed: _busy ? null : () => _startTimer(exercise),
                          icon: Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: p.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  key: ValueKey('complete-set-$index'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(74, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    backgroundColor: complete
                        ? p.primary.withValues(alpha: p.isDark ? .18 : .12)
                        : p.primary,
                    foregroundColor: complete ? p.primary : p.onPrimary,
                  ),
                  onPressed: _busy || complete ? null : () => _complete(index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        complete ? Icons.check_rounded : Icons.add_rounded,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        complete ? '完成' : '记一组',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _blockMenu(
    DailyWorkout session,
    int index,
    bool isAutoTemplate,
  ) {
    final p = context.palette;
    final dateStr = session.date;
    final id = session.blocks[index].id;
    final blockExercise = session.blocks[index].exercise;

    void handle(String action) {
      if (!mounted || _busy) return;
      DailyWorkout? target = _sessions[dateStr];
      var position = -1;
      if (target != null) {
        position = target.blocks.indexWhere((b) => b.id == id);
      } else if (isAutoTemplate) {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          target = _materializeForDate(parsed);
          position = index.clamp(0, target.blocks.length - 1);
        }
      }
      if (target == null || position < 0 || position >= target.blocks.length) {
        return;
      }
      switch (action) {
        case 'edit':
          _custom(session: target, blockIndex: position);
        case 'weight':
          _logWeight(target.blocks[position].exercise);
        case 'save_lib':
          _saveBlockToLibrary(blockExercise);
        case 'remove':
          _remove(target, position);
        case 'up':
          _move(target, position, -1);
        case 'down':
          _move(target, position, 1);
      }
    }

    return PopupMenuButton<String>(
      key: ValueKey('block-menu-$index'),
      enabled: !_busy,
      tooltip: '调整项目',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz_rounded, size: 20, color: p.textSecondary),
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () => handle('edit'),
          child: const Text('修改组数 / 次数 / 说明'),
        ),
        PopupMenuItem(
          onTap: () => handle('weight'),
          child: const Text('记录负重 / PR'),
        ),
        PopupMenuItem(
          onTap: () => handle('save_lib'),
          child: const Text('收入动作库'),
        ),
        if (index > 0)
          PopupMenuItem(onTap: () => handle('up'), child: const Text('上移')),
        if (index < session.blocks.length - 1)
          PopupMenuItem(onTap: () => handle('down'), child: const Text('下移')),
        PopupMenuItem(
          onTap: () => handle('remove'),
          child: Text('移除项目（可撤销）', style: TextStyle(color: p.danger)),
        ),
      ],
    );
  }
}
