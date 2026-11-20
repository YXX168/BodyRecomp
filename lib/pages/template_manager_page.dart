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
import '../widgets/muscle_body_graphic.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/text_prompt.dart';
import '../widgets/undo_notice.dart';

/// Embedded Tab 1 page wrapper.
class WeeklyTemplatesPage extends StatelessWidget {
  const WeeklyTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) => const WeeklyTemplatesView();
}

/// Standalone page wrapper for managing templates & daily fixed weekday schedule.
class TemplateManagerPage extends StatelessWidget {
  const TemplateManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('每日固定模板')),
      body: const LiquidBackdrop(child: WeeklyTemplatesView()),
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
  int _selectedDay = DateTime.now().weekday - 1;
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

  WorkoutTemplate? _templateForDay(int day) {
    if (_templates == null || day < 0 || day >= _schedule.length) return null;
    final id = _schedule[day];
    if (id.isEmpty) return null;
    for (final t in _templates!) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _saveTemplateUpdate(WorkoutTemplate updated) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final next = List<WorkoutTemplate>.from(_templates ?? []);
      final index = next.indexWhere((value) => value.id == updated.id);
      if (index < 0) {
        next.add(updated);
      } else {
        next[index] = updated;
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

  Future<void> _edit(WorkoutTemplate? template,
      {bool bindSelected = false}) async {
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
    await _saveTemplateUpdate(result);
    if (bindSelected && template == null && mounted) {
      await _setDay(_selectedDay, result.id);
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
              : '$dayNames 当前绑定了此模板，删除后将转为休息日，不影响历史记录。',
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
        icon: Icons.calendar_month_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectionOption(
              key: const ValueKey('schedule-option-rest'),
              title: '休息 / 恢复',
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
                      '${t.exercises.length} 动作 · ${t.exercises.fold<int>(0, (s, e) => s + e.sets)} 组',
                  leading: ExerciseMark(
                    t.exercises.isEmpty ? '平板卧推' : t.exercises.first.name,
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

  Future<void> _addExerciseToTemplate(WorkoutTemplate template) async {
    final values = await pickExercises(
      context,
      _templates ?? [],
      initialSource: 1,
    );
    if (values == null || values.isEmpty || !mounted) return;
    await _saveTemplateUpdate(
      template.copyWith(exercises: [...template.exercises, ...values]),
    );
  }

  Future<void> _editTemplateExercise(
    WorkoutTemplate template,
    int index,
  ) async {
    final edited = await editExercise(
      context,
      initial: template.exercises[index],
    );
    if (edited == null || !mounted) return;
    final nextExercises = List<Exercise>.from(template.exercises)
      ..[index] = edited;
    await _saveTemplateUpdate(template.copyWith(exercises: nextExercises));
  }

  Future<void> _moveTemplateExercise(
    WorkoutTemplate template,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= template.exercises.length) return;
    final list = List<Exercise>.from(template.exercises);
    final item = list.removeAt(index);
    list.insert(target, item);
    await _saveTemplateUpdate(template.copyWith(exercises: list));
  }

  Future<void> _removeTemplateExercise(
    WorkoutTemplate template,
    int index,
  ) async {
    final removed = template.exercises[index];
    final previous = template;
    final nextList = List<Exercise>.from(template.exercises)..removeAt(index);
    await _saveTemplateUpdate(template.copyWith(exercises: nextList));
    if (!mounted) return;
    showUndoNotice(context, '已从模板移除 ${removed.name}', onUndo: () async {
      await _saveTemplateUpdate(previous);
    });
  }

  Widget _restMark(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: p.primary.withValues(alpha: p.isDark ? .18 : .12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(Icons.spa_outlined, size: 19, color: p.primary),
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

    const shortWeekdays = ['一', '二', '三', '四', '五', '六', '日'];
    const fullWeekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final todayWeekday = DateTime.now().weekday - 1;
    final selectedTemplate = _templateForDay(_selectedDay);
    final totalSets =
        selectedTemplate?.exercises.fold<int>(0, (sum, e) => sum + e.sets) ?? 0;
    final muscles = selectedTemplate == null
        ? const <String>{}
        : inferMuscleGroups(selectedTemplate.exercises);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 112),
      children: [
        // Unified Calm 7-Day Glass Pill Rail
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.glassFillTop, p.glassFillBottom],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.borderSubtle, width: 0.9),
          ),
          child: Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final isSelected = d == _selectedDay;
                      final isToday = d == todayWeekday;
                      final hasTpl = _templateForDay(d) != null;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey('schedule-day-$d'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: _busy
                              ? null
                              : () {
                                  if (_selectedDay == d) {
                                    _chooseDay(d);
                                  } else {
                                    setState(() => _selectedDay = d);
                                  }
                                },
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 170),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? p.primaryGradient : null,
                              color: isSelected
                                  ? null
                                  : isToday
                                      ? p.primary.withValues(
                                          alpha: p.isDark ? .12 : .08,
                                        )
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: !isSelected && isToday
                                    ? p.primary.withValues(alpha: .40)
                                    : Colors.transparent,
                                width: 0.9,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shortWeekdays[d],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? p.onPrimary
                                        : isToday
                                            ? p.primary
                                            : p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: hasTpl ? 6 : 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    color: isSelected
                                        ? p.onPrimary.withValues(
                                            alpha: hasTpl ? .92 : .35)
                                        : hasTpl
                                            ? p.primary.withValues(alpha: .85)
                                            : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Selected Day Asymmetric Hero Card
        SurfaceCard(
          elevated: true,
          highlighted: selectedTemplate != null,
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuscleBodyGraphic(activeGroups: muscles, size: 62),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDay == todayWeekday
                                ? '${fullWeekdays[_selectedDay]} · 今日'
                                : fullWeekdays[_selectedDay],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selectedTemplate == null
                                  ? p.accent
                                  : p.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedTemplate?.name ?? '休息 / 恢复',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.3,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            selectedTemplate == null
                                ? '主动恢复'
                                : '${selectedTemplate.exercises.length} 个动作 · 共 $totalSets 组',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedTemplate != null) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: '编辑此模板',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _busy ? null : () => _edit(selectedTemplate),
                          child: Container(
                            width: 30,
                            height: 30,
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
                              Icons.tune_rounded,
                              size: 16,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('change-day-template'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _busy ? null : () => _chooseDay(_selectedDay),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('换模板'),
                  ),
                  if (selectedTemplate != null)
                    FilledButton.icon(
                      key: const Key('add-day-exercise'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: _busy
                          ? null
                          : () => _addExerciseToTemplate(selectedTemplate),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('加动作'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Inline Selected Day Exercises
        if (selectedTemplate == null)
          SurfaceCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.spa_outlined, size: 28, color: p.accent),
                  const SizedBox(height: 8),
                  Text(
                    '此日设为休息日，点击「换模板」可随时指派训练',
                    style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else if (selectedTemplate.exercises.isEmpty)
          SurfaceCard(
            radius: 22,
            onTap:
                _busy ? null : () => _addExerciseToTemplate(selectedTemplate),
            padding: const EdgeInsets.all(22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 20, color: p.primary),
                const SizedBox(width: 8),
                Text(
                  '添加第一个模板动作',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < selectedTemplate.exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(
                builder: (context) {
                  final ex = selectedTemplate.exercises[i];
                  return SurfaceCard(
                    radius: 20,
                    onTap: _busy
                        ? null
                        : () => _editTemplateExercise(selectedTemplate, i),
                    padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
                    child: Row(
                      children: [
                        ExerciseMark(ex.name, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${ex.sets} 组 × ${ex.reps}${ex.rest.isNotEmpty ? ' · 休 ${ex.rest}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Builder(
                          builder: (btnCtx) => IconButton(
                            tooltip: '调整动作',
                            onPressed: _busy
                                ? null
                                : () async {
                                    final action = await showGlassMenu<String>(
                                      context: context,
                                      anchorContext: btnCtx,
                                      title: ex.name,
                                      items: [
                                        GlassMenuItem(
                                          value: 'edit',
                                          label: '编辑组次',
                                          icon: Icons.tune_rounded,
                                          color: p.primary,
                                        ),
                                        if (i > 0)
                                          const GlassMenuItem(
                                            value: 'up',
                                            label: '上移',
                                            icon: Icons.arrow_upward_rounded,
                                          ),
                                        if (i <
                                            selectedTemplate.exercises.length -
                                                1)
                                          const GlassMenuItem(
                                            value: 'down',
                                            label: '下移',
                                            icon: Icons.arrow_downward_rounded,
                                          ),
                                        const GlassMenuItem(
                                          value: 'remove',
                                          label: '移除',
                                          icon: Icons.delete_outline_rounded,
                                          isDanger: true,
                                          hasTopDivider: true,
                                        ),
                                      ],
                                    );
                                    if (!mounted || action == null) return;
                                    switch (action) {
                                      case 'edit':
                                        _editTemplateExercise(
                                            selectedTemplate, i);
                                      case 'up':
                                        _moveTemplateExercise(
                                            selectedTemplate, i, -1);
                                      case 'down':
                                        _moveTemplateExercise(
                                            selectedTemplate, i, 1);
                                      case 'remove':
                                        _removeTemplateExercise(
                                            selectedTemplate, i);
                                    }
                                  },
                            icon: Icon(
                              Icons.more_horiz_rounded,
                              size: 19,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

        const SizedBox(height: 16),
        SectionTitleBar(
          title: '全部模板',
          trailing: TextButton.icon(
            key: const Key('create-template'),
            onPressed: _busy ? null : () => _edit(null, bindSelected: false),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('新建模板'),
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal Glass Template Gallery Strip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final template in _templates!)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 154,
                    child: Builder(
                      builder: (context) {
                        final tplSets = template.exercises
                            .fold<int>(0, (s, e) => s + e.sets);
                        final boundCurrentDay =
                            selectedTemplate?.id == template.id;
                        return SurfaceCard(
                          key: ValueKey('template-card-${template.id}'),
                          highlighted: boundCurrentDay,
                          radius: 20,
                          onTap: _busy ? null : () => _edit(template),
                          padding: const EdgeInsets.fromLTRB(12, 11, 6, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ExerciseMark(
                                    template.exercises.isEmpty
                                        ? '平板卧推'
                                        : template.exercises.first.name,
                                    size: 36,
                                  ),
                                  const Spacer(),
                                  Builder(
                                    builder: (btnCtx) => Tooltip(
                                      message: '模板操作',
                                      child: IconButton(
                                        key: ValueKey(
                                            'template-menu-${template.id}'),
                                        constraints:
                                            const BoxConstraints.tightFor(
                                          width: 32,
                                          height: 32,
                                        ),
                                        padding: EdgeInsets.zero,
                                        style: IconButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: _busy
                                            ? null
                                            : () async {
                                                final action =
                                                    await showGlassMenu<String>(
                                                  context: context,
                                                  anchorContext: btnCtx,
                                                  title: template.name,
                                                  items: [
                                                    GlassMenuItem(
                                                      value: 'bind',
                                                      label:
                                                          '设为${fullWeekdays[_selectedDay]}固定',
                                                      icon: Icons
                                                          .event_available_rounded,
                                                      color: p.primary,
                                                    ),
                                                    GlassMenuItem(
                                                      value: 'edit',
                                                      label: '编辑模板',
                                                      icon: Icons.edit_outlined,
                                                      color: p.accent,
                                                    ),
                                                    const GlassMenuItem(
                                                      value: 'duplicate',
                                                      label: '复制模板',
                                                      icon: Icons.copy_rounded,
                                                    ),
                                                    const GlassMenuItem(
                                                      value: 'delete',
                                                      label: '删除模板',
                                                      icon: Icons
                                                          .delete_outline_rounded,
                                                      isDanger: true,
                                                      hasTopDivider: true,
                                                    ),
                                                  ],
                                                );
                                                if (!mounted ||
                                                    action == null) {
                                                  return;
                                                }
                                                switch (action) {
                                                  case 'bind':
                                                    _setDay(_selectedDay,
                                                        template.id);
                                                  case 'edit':
                                                    _edit(template);
                                                  case 'duplicate':
                                                    _duplicate(template);
                                                  case 'delete':
                                                    _deleteTemplate(template);
                                                }
                                              },
                                        icon: Icon(
                                          Icons.more_horiz_rounded,
                                          size: 19,
                                          color: p.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                template.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${template.exercises.length} 动作 · $tplSets 组',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
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
        body: LiquidBackdrop(
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
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '可选备注…',
                ),
              ),
              const SizedBox(height: 18),
              SectionTitleBar(title: '动作列表 (${_exercises.length})'),
              const SizedBox(height: 10),
              if (_exercises.isEmpty)
                SurfaceCard(
                  padding: const EdgeInsets.all(22),
                  child: Center(
                    child: Text(
                      '从动作库挑选或自建动作',
                      style: TextStyle(fontSize: 13, color: p.textSecondary),
                    ),
                  ),
                ),
              for (var i = 0; i < _exercises.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SurfaceCard(
                    onTap: () => _custom(i),
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ExerciseMark(_exercises[i].name, size: 42),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _exercises[i].name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${_exercises[i].sets}×${_exercises[i].reps}'
                                    '${_exercises[i].rest.isNotEmpty ? ' · ${_exercises[i].rest}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: '编辑动作',
                              onPressed: () => _custom(i),
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 19,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
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
                                  size: 18),
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
                                  size: 18),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(13);
                  final pickBtn = OutlinedButton.icon(
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
                    label: const Text('动作库挑选'),
                  );
                  final customBtn = FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: () => _custom(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('自定义项目'),
                  );
                  if (constraints.maxWidth < 260 || scale > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        pickBtn,
                        const SizedBox(height: 8),
                        customBtn,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: pickBtn),
                      const SizedBox(width: 10),
                      Expanded(child: customBtn),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
