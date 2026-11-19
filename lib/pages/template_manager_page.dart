import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/daily_workout.dart';
import '../models/library_exercise.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../services/exercise_library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/exercise_mark.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/loading_view.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/text_prompt.dart';
import '../widgets/undo_notice.dart';

/// Standalone page wrapper for managing templates & daily fixed weekday schedule.
class TemplateManagerPage extends StatelessWidget {
  const TemplateManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('每日固定模板')),
      body: const AmbientCanvas(child: WeeklyTemplatesView()),
    );
  }
}

class WeeklyTemplatesView extends StatefulWidget {
  const WeeklyTemplatesView({super.key});

  @override
  State<WeeklyTemplatesView> createState() => _WeeklyTemplatesViewState();
}

class _WeeklyTemplatesViewState extends State<WeeklyTemplatesView> {
  List<WorkoutTemplate>? _templates;
  List<String> _schedule = [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    workoutPlanRevision.addListener(_load);
    workoutDataRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    workoutPlanRevision.removeListener(_load);
    workoutDataRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final templates = await loadWorkoutTemplates();
      final schedule = await loadWeeklySchedule();
      if (mounted) {
        setState(() {
          _templates = templates;
          _schedule = schedule;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '模板读取失败，原数据未被覆盖。');
    }
  }

  Future<void> _edit(WorkoutTemplate? template) async {
    final library = _templates ?? [];
    final result = await Navigator.push<WorkoutTemplate>(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditorPage(
          template: template,
          library: library,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = List<WorkoutTemplate>.from(_templates ?? []);
      final index = next.indexWhere((value) => value.id == result.id);
      if (index < 0) {
        next.add(result);
      } else {
        next[index] = result;
      }
      await saveWorkoutTemplates(next);
      workoutPlanRevision.value++;
      if (mounted) setState(() => _templates = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('模板保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _duplicate(WorkoutTemplate template) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await duplicateWorkoutTemplate(template);
      workoutPlanRevision.value++;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已复制「${template.name}」')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('模板复制失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteTemplate(WorkoutTemplate template) async {
    if (_busy) return;
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final boundDays = <int>[
      for (var d = 0; d < _schedule.length; d++)
        if (_schedule[d] == template.id) d,
    ];
    final dayNames = boundDays.map((d) => weekdays[d]).join('、');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${template.name}」？'),
        content: Text(
          boundDays.isEmpty
              ? '删除后不会改变已保存的历史训练记录。'
              : '$dayNames 当前绑定了此模板，删除后这些日期将恢复为「休息 / 恢复」，但不影响已保存的历史训练记录。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final previousTemplates = List<WorkoutTemplate>.from(_templates ?? []);
    final previousSchedule = List<String>.from(_schedule);

    setState(() => _busy = true);
    try {
      await deleteWorkoutTemplate(template.id);
      workoutPlanRevision.value++;
      await _load();
      if (!mounted) return;
      showUndoNotice(
        context,
        '已删除模板「${template.name}」',
        onUndo: () async {
          try {
            await saveWorkoutTemplates(previousTemplates);
            await saveWeeklySchedule(previousSchedule);
            workoutPlanRevision.value++;
            await _load();
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('恢复模板失败，请重试')),
              );
            }
          }
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除模板失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDay(int day, String value) async {
    setState(() => _busy = true);
    try {
      final next = List<String>.from(_schedule)..[day] = value;
      await saveWeeklySchedule(next);
      workoutPlanRevision.value++;
      if (mounted) setState(() => _schedule = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('每日模板保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseDay(int day) async {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
        title: '周${weekdays[day]}安排',
        subtitle: '每天打开「训练」页将自动载入该固定模板',
        icon: Icons.calendar_month_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectionOption(
              key: const ValueKey('schedule-option-rest'),
              title: '休息 / 恢复',
              subtitle: '当天默认标记为恢复休息日',
              leading: _restMark(ctx),
              selected: _schedule[day].isEmpty,
              onTap: () => Navigator.pop(ctx, ''),
            ),
            for (final t in _templates!)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectionOption(
                  key: ValueKey('schedule-option-${t.id}'),
                  title: t.name,
                  subtitle:
                      '${t.exercises.length} 个动作 · ${t.exercises.fold<int>(0, (s, e) => s + e.sets)} 组',
                  leading: ExerciseMark(
                    t.exercises.isEmpty ? '' : t.exercises.first.name,
                    size: 38,
                  ),
                  selected: _schedule[day] == t.id,
                  onTap: () => Navigator.pop(ctx, t.id),
                ),
              ),
          ],
        ),
      ),
    );
    if (value != null && mounted && value != _schedule[day]) {
      await _setDay(day, value);
    }
  }

  Widget _restMark(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: p.isDark ? .14 : .09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(Icons.spa_outlined, size: 19, color: p.primary),
    );
  }

  Widget _weeklyScheduleCard(BuildContext context) {
    final p = context.palette;
    final todayWeekday = DateTime.now().weekday - 1;
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var day = 0; day < 7; day++) ...[
            if (day > 0)
              Divider(
                  height: 1, indent: 64, endIndent: 16, color: p.borderSubtle),
            Builder(
              builder: (ctx) {
                final matches =
                    _templates!.where((t) => t.id == _schedule[day]);
                final template = matches.isEmpty ? null : matches.first;
                final isToday = day == todayWeekday;
                final totalSets = template == null
                    ? 0
                    : template.exercises.fold<int>(0, (s, e) => s + e.sets);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('schedule-day-$day'),
                    onTap: _busy ? null : () => _chooseDay(day),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  labels[day],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isToday ? p.primary : p.textPrimary,
                                  ),
                                ),
                                if (isToday)
                                  Text(
                                    '今天',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          template == null
                              ? _restMark(ctx)
                              : ExerciseMark(
                                  template.exercises.isEmpty
                                      ? ''
                                      : template.exercises.first.name,
                                  size: 38,
                                ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template?.name ?? '休息 / 恢复',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: template == null
                                        ? p.textSecondary
                                        : p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  template == null
                                      ? '主动休息恢复日'
                                      : '${template.exercises.length} 个动作 · $totalSets 组',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (template != null)
                            IconButton(
                              tooltip: '编辑此模板',
                              onPressed: _busy ? null : () => _edit(template),
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: p.textSecondary,
                              ),
                            ),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 18,
                            color: p.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: p.textPrimary)),
              const SizedBox(height: 10),
              TextButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_templates == null) return const LoadingView();

    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        const SectionTitleBar(
          title: '每周固定模板',
          subtitle: '设定周一至周日固定课表，打开训练页自动载入',
        ),
        const SizedBox(height: 12),
        _weeklyScheduleCard(context),
        const SizedBox(height: 26),
        SectionTitleBar(
          title: '模板库',
          subtitle: '共 ${_templates!.length} 套模板，修改模板不影响历史记录',
          trailing: FilledButton.icon(
            key: const Key('create-template'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 38),
            ),
            onPressed: _busy ? null : () => _edit(null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('新建模板'),
          ),
        ),
        const SizedBox(height: 12),
        for (final template in _templates!) ...[
          Builder(
            builder: (context) {
              final totalSets =
                  template.exercises.fold<int>(0, (s, e) => s + e.sets);
              final boundDays = <String>[
                for (var d = 0; d < _schedule.length; d++)
                  if (_schedule[d] == template.id) weekdays[d],
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  key: ValueKey('template-card-${template.id}'),
                  onTap: _busy ? null : () => _edit(template),
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    children: [
                      ExerciseMark(
                        template.exercises.isEmpty
                            ? '平板卧推'
                            : template.exercises.first.name,
                        size: 46,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${template.exercises.length} 个动作 · $totalSets 组'
                              '${template.note.isNotEmpty ? ' · ${template.note}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textSecondary,
                              ),
                            ),
                            if (boundDays.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final d in boundDays)
                                    StatusPill(label: d),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        key: ValueKey('template-menu-${template.id}'),
                        enabled: !_busy,
                        tooltip: '模板操作',
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: p.textSecondary,
                        ),
                        onSelected: (action) {
                          switch (action) {
                            case 'edit':
                              _edit(template);
                            case 'duplicate':
                              _duplicate(template);
                            case 'delete':
                              _deleteTemplate(template);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('编辑模板'),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Text('复制模板'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              '删除模板',
                              style: TextStyle(color: p.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class TemplateEditorPage extends StatefulWidget {
  final WorkoutTemplate? template;
  final List<WorkoutTemplate> library;
  const TemplateEditorPage({
    super.key,
    required this.template,
    required this.library,
  });

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  late String _name = widget.template?.name ?? '我的训练模板';
  late final _note = TextEditingController(text: widget.template?.note ?? '');
  late final List<Exercise> _exercises =
      List.from(widget.template?.exercises ?? []);
  late final String _initial;
  bool _allowPop = false;
  bool _leaving = false;
  bool _finishing = false;

  String _snapshot() => jsonEncode({
        'name': _name,
        'note': _note.text.trim(),
        'exercises': _exercises.map((e) => e.toJson()).toList(),
      });
  bool get _dirty => _snapshot() != _initial;

  @override
  void initState() {
    super.initState();
    _initial = _snapshot();
    _note.addListener(_noteChanged);
  }

  void _noteChanged() => setState(() {});

  Future<void> _finish({required bool save}) async {
    if (_finishing) return;
    _finishing = true;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.pop(
      context,
      save
          ? WorkoutTemplate(
              id: widget.template?.id ??
                  'custom_${DateTime.now().microsecondsSinceEpoch}',
              name: _name,
              note: _note.text.trim(),
              exercises: List.from(_exercises),
            )
          : null,
    );
  }

  Future<void> _leave() async {
    if (_leaving || _finishing) return;
    if (!_dirty) {
      await _finish(save: false);
      return;
    }
    _leaving = true;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('模板有未保存的修改'),
        content: const Text('返回前是否保存这次修改？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('放弃修改'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存并返回'),
          ),
        ],
      ),
    );
    _leaving = false;
    if (save != null && mounted) await _finish(save: save);
  }

  void _remove(int index) {
    final exercise = _exercises[index];
    setState(() => _exercises.removeAt(index));
    showUndoNotice(context, '已移除 ${exercise.name}', onUndo: () {
      if (!mounted) return;
      setState(
        () => _exercises.insert(index.clamp(0, _exercises.length), exercise),
      );
    });
  }

  @override
  void dispose() {
    _note.removeListener(_noteChanged);
    _note.dispose();
    super.dispose();
  }

  Future<void> _custom([int? index]) async {
    final res = await editExerciseDetailed(
      context,
      initial: index == null ? null : _exercises[index],
      offerSaveToLibrary: index == null,
    );
    if (res == null || !mounted) return;
    setState(() {
      if (index == null) {
        _exercises.add(res.exercise);
      } else {
        _exercises[index] = res.exercise;
      }
    });
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
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('编辑模板'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                key: const Key('save-template'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _finish(save: true),
                child: const Text('保存'),
              ),
            ),
          ],
        ),
        body: AmbientCanvas(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
            children: [
              SurfaceCard(
                onTap: () async {
                  final value =
                      await promptText(context, '模板名称', initial: _name);
                  if (value != null && mounted) setState(() => _name = value);
                },
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '模板名称',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: p.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, color: p.primary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '模板说明 / 练后安排',
                  hintText: '例如：练后爬坡快走 20 分钟；疲劳时可跳过直接拉伸',
                ),
              ),
              const SizedBox(height: 20),
              SectionTitleBar(
                title: '训练动作列表',
                subtitle: '共 ${_exercises.length} 个项目',
              ),
              const SizedBox(height: 10),
              if (_exercises.isEmpty)
                SurfaceCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      '从动作库挑选或添加自定义动作来搭建此模板',
                      style: TextStyle(fontSize: 13, color: p.textSecondary),
                    ),
                  ),
                ),
              for (var i = 0; i < _exercises.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ExerciseMark(_exercises[i].name, size: 42),
                          title: Text(
                            _exercises[i].name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${_exercises[i].sets} 组 × ${_exercises[i].reps}'
                            '${_exercises[i].rest.isNotEmpty ? ' · 休 ${_exercises[i].rest}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.textSecondary,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: '编辑动作',
                            onPressed: () => _custom(i),
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 19,
                              color: p.textSecondary,
                            ),
                          ),
                          onTap: () => _custom(i),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: '上移',
                              onPressed: i == 0
                                  ? null
                                  : () => setState(() {
                                        final e = _exercises.removeAt(i);
                                        _exercises.insert(i - 1, e);
                                      }),
                              icon: const Icon(Icons.arrow_upward_rounded,
                                  size: 19),
                            ),
                            IconButton(
                              tooltip: '下移',
                              onPressed: i == _exercises.length - 1
                                  ? null
                                  : () => setState(() {
                                        final e = _exercises.removeAt(i);
                                        _exercises.insert(i + 1, e);
                                      }),
                              icon: const Icon(Icons.arrow_downward_rounded,
                                  size: 19),
                            ),
                            TextButton(
                              onPressed: () => _remove(i),
                              child: Text(
                                '移除',
                                style: TextStyle(color: p.danger),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () async {
                        final values = await pickExercises(
                          context,
                          widget.library,
                          initialSource: 1,
                        );
                        if (values != null && mounted) {
                          setState(() => _exercises.addAll(values));
                        }
                      },
                      icon: const Icon(Icons.view_module_outlined, size: 18),
                      label: const Text('从动作库 / 模板添加'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () => _custom(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('自定义项目'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
