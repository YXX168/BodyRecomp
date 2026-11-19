import '../widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/workout_templates.dart';
import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../services/rest_timer_service.dart';
import '../services/rest_countdown.dart';
import '../widgets/rest_timer_pill.dart';
import '../widgets/daily_date_bar.dart';
import '../widgets/daily_record_date.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/text_prompt.dart';
import '../widgets/exercise_mark.dart';
import '../widgets/undo_notice.dart';
import 'template_manager_page.dart';

class WorkoutPage extends StatefulWidget {
  final DateTime Function()? now;
  final RestCountdown? restController;
  final bool showRestTimer;
  const WorkoutPage(
      {super.key, this.now, this.restController, this.showRestTimer = true});
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
  bool _loading = true;
  bool _busy = false;
  bool _autoRest = false;
  String? _error;
  int _generation = 0;
  int _nextId = 0;
  late final RestCountdown _rest;

  DailyWorkout get _session =>
      _sessions[dayKey(recordDate)] ?? DailyWorkout(date: dayKey(recordDate));
  WorkoutTemplate? get _suggestion {
    final matches = _templates
        .where((value) => value.id == _schedule[recordDate.weekday - 1]);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  void initState() {
    super.initState();
    _rest = widget.restController ??
        RestCountdown(
            now: () => now, onFinished: () => HapticFeedback.heavyImpact());
    workoutDataRevision.addListener(_reload);
    workoutPlanRevision.addListener(_reload);
    restTimerPreferenceRevision.addListener(_reload);
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
    if (widget.restController == null) _rest.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (widget.restController == null) _rest.setActive(pageActive);
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    try {
      final sessions = await loadDailyWorkouts();
      final templates = await loadWorkoutTemplates();
      final schedule = await loadWeeklySchedule();
      final autoRest = await loadAutoRestTimer();
      if (!mounted || generation != _generation) return;
      setState(() {
        _sessions = sessions;
        _templates = templates;
        _schedule = schedule;
        _autoRest = autoRest;
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
    // Invalidate an older in-flight read before a mutation can be published.
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
    // Different variants (e.g. 3 versus 5 sets) remain distinct building blocks.
    for (final exercise in exercises) {
      next.add(WorkoutBlock(
          id: 'block_${DateTime.now().microsecondsSinceEpoch}_${_nextId++}',
          exercise: exercise));
    }
    await _save(target.copyWith(blocks: next, rested: false));
  }

  Future<void> _pick() async {
    final target = _session;
    final values = await pickExercises(context, _templates);
    if (values != null && mounted) await _add(values, target);
  }

  Future<void> _custom({DailyWorkout? session, WorkoutBlock? block}) async {
    final target = session ?? _session;
    final value = await editExercise(context, initial: block?.exercise);
    if (!mounted || value == null) return;
    if (block == null) {
      await _add([value], target);
      return;
    }
    if (value.sets < block.completedSets) {
      _message('计划组数不能小于已完成组数，请先撤销多余的组。');
      return;
    }
    await _save(target.copyWith(
        blocks: target.blocks
            .map((e) => e.id == block.id ? e.copyWith(exercise: value) : e)
            .toList()));
  }

  Future<void> _complete(WorkoutBlock block, {bool undo = false}) async {
    final target = _session;
    final count =
        (block.completedSets + (undo ? -1 : 1)).clamp(0, block.exercise.sets);
    if (count == block.completedSets) return;
    final success = await _save(target.copyWith(
        blocks: target.blocks
            .map((e) => e.id == block.id ? e.copyWith(completedSets: count) : e)
            .toList()));
    if (!success || !mounted) return;
    HapticFeedback.lightImpact();
    // Backdated entries and undo never launch a timer.
    if (!undo &&
        _autoRest &&
        target.date == dayKey(now) &&
        count < block.exercise.sets) {
      _startTimer(block.exercise);
    }
  }

  Future<void> _remove(DailyWorkout target, int index) async {
    final block = target.blocks[index];
    if (!await _save(target.copyWith(
            blocks: target.blocks.where((e) => e.id != block.id).toList())) ||
        !mounted) {
      return;
    }
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

  Future<void> _saveTemplate() async {
    final blocks = List<WorkoutBlock>.from(_session.blocks);
    final name = await promptText(context, '把这组积木存成模板');
    if (name == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final templates = await loadWorkoutTemplates();
      templates.add(WorkoutTemplate(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          exercises: blocks.map((e) => e.exercise).toList()));
      await saveWorkoutTemplates(templates);
      workoutPlanRevision.value++;
      _message('已保存为模板，完成进度不会带到下一次训练。');
    } catch (_) {
      _message('模板保存失败，请重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startTimer(Exercise exercise) {
    final seconds = parseRestSeconds(exercise.rest);
    if (seconds != null) {
      _rest.start(
          seconds, '${recordDate.month}/${recordDate.day} · ${exercise.name}');
    }
  }

  Future<void> _pickSuggestion() async {
    final suggestion = _suggestion;
    if (suggestion == null) return;
    final target = _session;
    final values = await pickExercises(context, [suggestion]);
    if (values != null && mounted) await _add(values, target);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null)
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!),
                TextButton(onPressed: _reload, child: const Text('重试'))
              ])));
    final session = _session;
    final suggestion = _suggestion;
    final isToday = recordDate == today;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: .45);
    final progress = session.plannedSets == 0
        ? 0.0
        : session.completedSets / session.plannedSets;
    return Column(children: [
      if (widget.showRestTimer)
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Align(
                alignment: Alignment.centerRight,
                child: RestTimerPill(controller: _rest))),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: DailyDateBar(
          date: recordDate,
          today: today,
          enabled: !_busy,
          onChanged: selectRecordDate,
        ),
      ),
      Expanded(
          child: ListView(
              key: PageStorageKey('daily-workout-scroll-${dayKey(recordDate)}'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
            Container(
                key: const Key('daily-suggestion'),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
                decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: color.withValues(alpha: .09)),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Row(children: [
                    Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(9)),
                        child: Icon(
                            suggestion == null
                                ? Icons.spa_outlined
                                : Icons.bookmark_border_rounded,
                            size: 15,
                            color: color)),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(isToday ? '今日参考' : '当日参考',
                              style: TextStyle(fontSize: 9, color: muted)),
                          const SizedBox(height: 3),
                          Text(suggestion?.name ?? '休息 / 恢复',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ])),
                    if (suggestion != null)
                      TextButton(
                          key: const Key('use-suggestion'),
                          onPressed: _busy ? null : _pickSuggestion,
                          child:
                              const Text('挑选', style: TextStyle(fontSize: 11))),
                    if (suggestion == null)
                      IconButton(
                          tooltip: '恢复安排',
                          onPressed: () => showModalBottomSheet(
                              context: context,
                              builder: (context) => SafeArea(
                                  child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                          recoveryNotes[recordDate.weekday - 1]
                                                  .isEmpty
                                              ? '按当天状态自由恢复。'
                                              : recoveryNotes[
                                                  recordDate.weekday - 1],
                                          style: const TextStyle(
                                              fontSize: 13, height: 1.7))))),
                          icon: Icon(Icons.info_outline_rounded,
                              size: 17, color: muted)),
                    IconButton(
                        tooltip: '管理模板',
                        onPressed: _busy
                            ? null
                            : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const TemplateManagerPage())),
                        icon: Icon(Icons.tune_rounded, size: 17, color: muted)),
                  ]),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                          height: 1, color: muted.withValues(alpha: .12))),
                  Row(children: [
                    Expanded(
                        child:
                            _summaryMetric('${session.blocks.length}', '个项目')),
                    Expanded(
                        child: _summaryMetric(
                            '${session.completedSets} / ${session.plannedSets}',
                            '已完成组数')),
                    SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(alignment: Alignment.center, children: [
                          SizedBox.expand(
                              child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                  strokeCap: StrokeCap.round,
                                  color: color,
                                  backgroundColor:
                                      color.withValues(alpha: .08))),
                          Text('${(progress * 100).round()}%',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ])),
                    const SizedBox(width: 4),
                  ]),
                ])),
            const SizedBox(height: 10),
            Row(children: [
              const Text('我的训练',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                  key: const Key('choose-blocks'),
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加项目', style: TextStyle(fontSize: 11)))
            ]),
            if (session.blocks.isEmpty)
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Transform.rotate(
                          angle: -.12,
                          child: const ExerciseMark('平板卧推', size: 44)),
                      const SizedBox(width: 10),
                      Transform.translate(
                          offset: const Offset(0, -8),
                          child: const ExerciseMark('腿', size: 50)),
                      const SizedBox(width: 10),
                      Transform.rotate(
                          angle: .12, child: const ExerciseMark('散步', size: 44))
                    ]),
                    const SizedBox(height: 18),
                    Text(session.rested ? '已标记休息' : '暂无训练项目',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    TextButton(
                        key: const Key('record-rest'),
                        onPressed: _busy
                            ? null
                            : () => _save(
                                session.copyWith(rested: !session.rested)),
                        child: Text(session.rested ? '取消休息标记' : '标记休息',
                            style: TextStyle(fontSize: 11, color: muted))),
                  ])),
            for (var i = 0; i < session.blocks.length; i++)
              Padding(
                  key: ValueKey('${session.date}-${session.blocks[i].id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _blockCard(session, i)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(
                  onPressed: _busy ? null : () => _custom(),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text('自定义项目',
                      style: TextStyle(fontSize: 11, color: muted))),
              if (session.blocks.isNotEmpty) ...[
                Container(
                    height: 12, width: 1, color: muted.withValues(alpha: .25)),
                TextButton.icon(
                    onPressed: _busy ? null : _saveTemplate,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 14),
                    label: Text('存为模板',
                        style: TextStyle(fontSize: 11, color: muted)))
              ],
            ]),
          ])),
    ]);
  }

  Widget _summaryMetric(String value, String label) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, height: 1.2, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 9, color: Theme.of(context).hintColor)),
      ]);

  Widget _blockCard(DailyWorkout session, int index) {
    final block = session.blocks[index];
    final exercise = block.exercise;
    final complete = block.completedSets == exercise.sets;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: .42);
    return Material(
        key: ValueKey('workout-block-$index'),
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: complete
                    ? color.withValues(alpha: .25)
                    : color.withValues(alpha: .06))),
        child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 10),
            child: Column(children: [
              Theme(
                  data: theme.copyWith(
                      splashFactory: NoSplash.splashFactory,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey(
                        'exercise-details-${session.date}-${block.id}'),
                    minTileHeight: 56,
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: ExerciseMark(exercise.name, size: 42),
                    trailing: _blockMenu(session, index),
                    title: Text(exercise.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            '${exercise.sets} 组 · ${exercise.reps}${RegExp(r'[a-zA-Z分钟秒]').hasMatch(exercise.reps) ? '' : ' 次'}',
                            style: TextStyle(fontSize: 10, color: muted))),
                    childrenPadding: const EdgeInsets.only(bottom: 10),
                    children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              exercise.note?.isNotEmpty == true
                                  ? exercise.note!
                                  : '按实际情况完成，可在菜单调整组数与次数。',
                              style: TextStyle(
                                  fontSize: 12, height: 1.6, color: muted)))
                    ],
                  )),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(
                    child: Wrap(spacing: 5, runSpacing: 5, children: [
                  for (var i = 0; i < exercise.sets.clamp(0, 12); i++)
                    Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: i < block.completedSets
                                ? color.withValues(alpha: .12)
                                : theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(6)),
                        child: i < block.completedSets
                            ? Icon(Icons.check_rounded, size: 13, color: color)
                            : Text('${i + 1}',
                                style: TextStyle(fontSize: 9, color: muted))),
                  if (exercise.sets > 12)
                    Text('${block.completedSets} / ${exercise.sets} 组',
                        style: TextStyle(fontSize: 10, color: muted))
                ])),
                IconButton(
                    key: ValueKey('undo-set-$index'),
                    tooltip: '撤销上一组',
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy || block.completedSets == 0
                        ? null
                        : () => _complete(block, undo: true),
                    icon: Icon(Icons.undo_rounded, size: 17, color: muted)),
                if (parseRestSeconds(exercise.rest) != null)
                  IconButton(
                      key: ValueKey('start-rest-$index'),
                      tooltip: '休息 ${exercise.rest}',
                      visualDensity: VisualDensity.compact,
                      onPressed: _busy ? null : () => _startTimer(exercise),
                      icon: Icon(Icons.timer_outlined, size: 18, color: muted)),
                FilledButton(
                    key: ValueKey('complete-set-$index'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(68, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        backgroundColor:
                            complete ? color.withValues(alpha: .1) : color,
                        foregroundColor:
                            complete ? color : theme.colorScheme.onPrimary),
                    onPressed:
                        _busy || complete ? null : () => _complete(block),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(complete ? Icons.check_rounded : Icons.add_rounded,
                          size: 14),
                      const SizedBox(width: 3),
                      Text(complete ? '完成' : '记一组',
                          style: const TextStyle(fontSize: 10)),
                    ])),
              ]),
            ])));
  }

  Widget _blockMenu(DailyWorkout session, int index) {
    final id = session.blocks[index].id;

    void handle(String action) {
      // Actions belong to the date and block that opened the menu, even if
      // the page rolls over to a new day while the menu is open.
      final target = _sessions[session.date];
      if (!mounted || _busy || target == null) return;
      final position = target.blocks.indexWhere((block) => block.id == id);
      if (position == -1) return;
      switch (action) {
        case 'edit':
          _custom(session: target, block: target.blocks[position]);
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
      icon: Icon(Icons.more_horiz_rounded,
          size: 19, color: Theme.of(context).hintColor),
      itemBuilder: (_) => [
        PopupMenuItem(
            onTap: () => handle('edit'), child: const Text('修改组数 / 次数 / 说明')),
        if (index > 0)
          PopupMenuItem(onTap: () => handle('up'), child: const Text('上移')),
        if (index < session.blocks.length - 1)
          PopupMenuItem(onTap: () => handle('down'), child: const Text('下移')),
        PopupMenuItem(
            onTap: () => handle('remove'), child: const Text('移除项目（可撤销）')),
      ],
    );
  }
}
