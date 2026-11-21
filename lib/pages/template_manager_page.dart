import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/workout_templates.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('每日固定模板')),
      body: const LiquidBackdrop(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(top: kToolbarHeight),
            child: WeeklyTemplatesView(),
          ),
        ),
      ),
    );
  }
}

class WeeklyTemplatesView extends StatefulWidget {
  const WeeklyTemplatesView({super.key});

  @override
  State<WeeklyTemplatesView> createState() => _WeeklyTemplatesViewState();
}

class _WeeklyTemplatesViewState extends State<WeeklyTemplatesView>
    with WidgetsBindingObserver {
  List<WorkoutTemplate>? _templates;
  List<String> _schedule = [];
  int _selectedDay = DateTime.now().weekday - 1;
  int _todayWeekday = DateTime.now().weekday - 1;
  String? _error;
  bool _busy = false;
  int _loadGeneration = 0;
  bool _pageVisible = true;
  bool _foreground = true;
  Timer? _midnightTimer;

  bool get _pageActive => _pageVisible && _foreground;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    workoutPlanRevision.addListener(_load);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pageVisible = TickerMode.valuesOf(context).enabled;
    if (_pageVisible) _syncTodayWeekday();
    _scheduleMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_pageActive) _syncTodayWeekday();
    _scheduleMidnight();
  }

  void _syncTodayWeekday() {
    final nextWeekday = DateTime.now().weekday - 1;
    if (nextWeekday != _todayWeekday && mounted) {
      setState(() => _todayWeekday = nextWeekday);
    }
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    if (!_pageActive) return;
    final current = DateTime.now();
    final nextDay = DateTime(current.year, current.month, current.day + 1);
    _midnightTimer = Timer(nextDay.difference(current), () {
      _syncTodayWeekday();
      _scheduleMidnight();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    workoutPlanRevision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    try {
      final templates = await loadWorkoutTemplates();
      final schedule = await loadWeeklySchedule();
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _templates = templates;
          _schedule = schedule;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() => _error = '模板读取失败，原数据未被覆盖。');
      }
    }
  }

  WorkoutTemplate? _templateById(String id) {
    final list = _templates;
    if (list == null || id.isEmpty) return null;
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }

  WorkoutTemplate? _templateForDay(int day) {
    if (_templates == null || day < 0 || day >= _schedule.length) return null;
    return _templateById(_schedule[day]);
  }

  Future<void> _resetToDefaultPlan() async {
    if (_busy) return;
    final ok = await showGlassConfirm(
      context: context,
      title: '恢复默认 4 练课表？',
      message: '将重置预制模板并设为周一周二周三周四训练、周五六日休息的增肌减脂方案，已记录的每日历史训练不会被修改。',
      icon: Icons.restart_alt_rounded,
      confirmLabel: '恢复默认',
    );
    if (ok != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final freshTemplates = List<WorkoutTemplate>.from(defaultTemplates);
      final freshSchedule = List<String>.from(defaultSchedule);
      await saveWorkoutTemplates(freshTemplates);
      await saveWeeklySchedule(freshSchedule);
      workoutPlanRevision.value++;
      if (!mounted) return;
      setState(() {
        _templates = freshTemplates;
        _schedule = freshSchedule;
        _error = null;
      });
      showGlassNotice(context, '已恢复默认 4 练增肌减脂课表');
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '恢复默认课表失败，请重试', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _saveTemplateUpdate(WorkoutTemplate updated) async {
    if (_busy) return false;
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
      return true;
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '模板保存失败，请重试', isError: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(WorkoutTemplate? template) async {
    if (_busy) return;
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
  }

  Future<void> _duplicate(WorkoutTemplate template) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await duplicateWorkoutTemplate(template);
      workoutPlanRevision.value++;
      await _load();
      if (mounted) {
        showGlassNotice(context, '已复制「${template.name}」');
      }
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '模板复制失败，请重试', isError: true);
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

    final confirmed = await showGlassConfirm(
      context: context,
      title: '删除「${template.name}」？',
      message: boundDays.isEmpty
          ? '删除后不会改变已保存的历史训练记录。'
          : '$dayNames 当前绑定了此模板，删除后将转为休息日，不影响历史记录。',
      cancelLabel: '取消',
      confirmLabel: '删除',
      isDanger: true,
    );
    if (confirmed != true || !mounted || _busy) return;

    final deletedTemplate = template;
    final originalIndex =
        (_templates ?? []).indexWhere((t) => t.id == template.id);

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
          if (!mounted || _busy) return;
          setState(() => _busy = true);
          try {
            final latestTemplates =
                List<WorkoutTemplate>.from(await loadWorkoutTemplates());
            if (!latestTemplates.any((t) => t.id == deletedTemplate.id)) {
              final insertAt = originalIndex < 0
                  ? latestTemplates.length
                  : originalIndex.clamp(0, latestTemplates.length);
              latestTemplates.insert(insertAt, deletedTemplate);
              await saveWorkoutTemplates(latestTemplates);
            }
            if (boundDays.isNotEmpty) {
              final latestSchedule =
                  List<String>.from(await loadWeeklySchedule());
              var changed = false;
              for (final d in boundDays) {
                if (d >= 0 &&
                    d < latestSchedule.length &&
                    latestSchedule[d].isEmpty) {
                  latestSchedule[d] = deletedTemplate.id;
                  changed = true;
                }
              }
              if (changed) {
                await saveWeeklySchedule(latestSchedule);
              }
            }
            workoutPlanRevision.value++;
            await _load();
          } catch (_) {
            if (mounted) {
              showGlassNotice(context, '恢复模板失败，请重试', isError: true);
            }
          } finally {
            if (mounted) setState(() => _busy = false);
          }
        },
      );
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '删除模板失败，请重试', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDay(int day, String value) async {
    if (_busy || day < 0 || day >= _schedule.length) return;
    setState(() => _busy = true);
    try {
      final next = List<String>.from(_schedule)..[day] = value;
      await saveWeeklySchedule(next);
      workoutPlanRevision.value++;
      if (mounted) setState(() => _schedule = next);
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '每日模板保存失败，请重试', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseDay(int day) async {
    if (_busy || _templates == null || day < 0 || day >= _schedule.length) {
      return;
    }
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
    if (value != null &&
        mounted &&
        day < _schedule.length &&
        value != _schedule[day]) {
      await _setDay(day, value);
    }
  }

  Future<void> _addExerciseToTemplate(WorkoutTemplate template) async {
    if (_busy) return;
    final values = await pickExercises(
      context,
      _templates ?? [],
      initialSource: 1,
    );
    if (values == null || values.isEmpty || !mounted) return;
    final fresh = _templateById(template.id) ?? template;
    await _saveTemplateUpdate(
      fresh.copyWith(exercises: [...fresh.exercises, ...values]),
    );
  }

  Future<void> _editTemplateExercise(
    WorkoutTemplate template,
    int index,
  ) async {
    if (_busy || index < 0 || index >= template.exercises.length) return;
    final edited = await editExercise(
      context,
      initial: template.exercises[index],
    );
    if (edited == null || !mounted) return;
    final fresh = _templateById(template.id);
    if (fresh == null || index < 0 || index >= fresh.exercises.length) return;
    final nextExercises = List<Exercise>.from(fresh.exercises)
      ..[index] = edited;
    await _saveTemplateUpdate(fresh.copyWith(exercises: nextExercises));
  }

  Future<void> _moveTemplateExercise(
    WorkoutTemplate template,
    int index,
    int delta,
  ) async {
    if (_busy) return;
    final fresh = _templateById(template.id);
    if (fresh == null) return;
    final target = index + delta;
    if (index < 0 ||
        index >= fresh.exercises.length ||
        target < 0 ||
        target >= fresh.exercises.length) {
      return;
    }
    final list = List<Exercise>.from(fresh.exercises);
    final item = list.removeAt(index);
    list.insert(target, item);
    await _saveTemplateUpdate(fresh.copyWith(exercises: list));
  }

  Future<void> _removeTemplateExercise(
    WorkoutTemplate template,
    int index,
  ) async {
    if (_busy) return;
    final fresh = _templateById(template.id);
    if (fresh == null || index < 0 || index >= fresh.exercises.length) return;
    final removed = fresh.exercises[index];
    final tplId = fresh.id;
    final removedIndex = index;
    final nextList = List<Exercise>.from(fresh.exercises)..removeAt(index);
    final saved =
        await _saveTemplateUpdate(fresh.copyWith(exercises: nextList));
    if (!saved || !mounted) return;
    showUndoNotice(context, '已从模板移除 ${removed.name}', onUndo: () async {
      if (!mounted || _busy) return;
      final latest = _templateById(tplId);
      if (latest == null) return;
      final restored = List<Exercise>.from(latest.exercises)
        ..insert(removedIndex.clamp(0, latest.exercises.length), removed);
      await _saveTemplateUpdate(latest.copyWith(exercises: restored));
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
    final todayWeekday = _todayWeekday;
    final selectedTemplate = _templateForDay(_selectedDay);
    final totalSets =
        selectedTemplate?.exercises.fold<int>(0, (sum, e) => sum + e.sets) ?? 0;
    final muscles = selectedTemplate == null
        ? const <String>{}
        : inferMuscleGroups(selectedTemplate.exercises);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 112),
      children: [
        // Unified Calm 7-Day Glass Pill Rail with smooth sliding indicator
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / 7;
              final reduceMotion = MediaQuery.disableAnimationsOf(context);
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                    left: _selectedDay * slotWidth,
                    top: 0,
                    bottom: 0,
                    width: slotWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: p.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: p.isDark ? 0.22 : 0.34,
                          ),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: p.primary.withValues(
                              alpha: p.isDark ? 0.28 : 0.20,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
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
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !isSelected && isToday
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
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            color: isSelected
                                                ? p.onPrimary.withValues(
                                                    alpha: hasTpl ? .92 : .35)
                                                : hasTpl
                                                    ? p.primary
                                                        .withValues(alpha: .85)
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
                ],
              );
            },
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
                                    final tplId = selectedTemplate.id;
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
                                    final fresh = _templateById(tplId);
                                    if (fresh == null ||
                                        i < 0 ||
                                        i >= fresh.exercises.length) {
                                      return;
                                    }
                                    switch (action) {
                                      case 'edit':
                                        await _editTemplateExercise(fresh, i);
                                      case 'up':
                                        await _moveTemplateExercise(
                                            fresh, i, -1);
                                      case 'down':
                                        await _moveTemplateExercise(
                                            fresh, i, 1);
                                      case 'remove':
                                        await _removeTemplateExercise(fresh, i);
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
            onPressed: _busy ? null : () => _edit(null),
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
                    width: 158,
                    child: Builder(
                      builder: (context) {
                        final tplSets = template.exercises
                            .fold<int>(0, (s, e) => s + e.sets);
                        final boundCurrentDay =
                            selectedTemplate?.id == template.id;
                        final boundDays = <String>[
                          for (var d = 0; d < _schedule.length; d++)
                            if (_schedule[d] == template.id) fullWeekdays[d],
                        ];
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
                                                final tplId = template.id;
                                                final targetDay = _selectedDay;
                                                final action =
                                                    await showGlassMenu<String>(
                                                  context: context,
                                                  anchorContext: btnCtx,
                                                  title: template.name,
                                                  items: [
                                                    GlassMenuItem(
                                                      value: 'bind',
                                                      label:
                                                          '设为${fullWeekdays[targetDay]}固定',
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
                                                final fresh =
                                                    _templateById(tplId);
                                                if (fresh == null) return;
                                                switch (action) {
                                                  case 'bind':
                                                    await _setDay(
                                                        targetDay, fresh.id);
                                                  case 'edit':
                                                    await _edit(fresh);
                                                  case 'duplicate':
                                                    await _duplicate(fresh);
                                                  case 'delete':
                                                    await _deleteTemplate(
                                                        fresh);
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
                              const SizedBox(height: 3),
                              Text(
                                boundDays.isNotEmpty
                                    ? boundDays.join('、')
                                    : '未绑定固定日',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: boundDays.isNotEmpty
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: boundDays.isNotEmpty
                                      ? p.primary
                                      : p.textTertiary,
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
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            key: const Key('reset-default-templates'),
            onPressed: _busy ? null : _resetToDefaultPlan,
            style: TextButton.styleFrom(
              foregroundColor: p.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: const Text('恢复默认 4 练增肌减脂课表'),
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
    final save = await showGlassDialog<bool>(
      context: context,
      title: '模板有未保存的修改',
      message: '返回前是否保存这次修改？',
      icon: Icons.save_outlined,
      actionsBuilder: (ctx) {
        final p = ctx.palette;
        return [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: p.textSecondary),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: p.danger),
            child: const Text('放弃修改'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存并返回'),
          ),
        ];
      },
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
      } catch (_) {
        if (mounted) {
          showGlassNotice(
            context,
            '动作已加入模板，但同步到动作库失败',
            isError: true,
          );
        }
      }
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
        extendBodyBehindAppBar: true,
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
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
                children: [
                  SurfaceCard(
                    onTap: () async {
                      final value =
                          await promptText(context, '模板名称', initial: _name);
                      if (value != null && mounted) {
                        setState(() => _name = value);
                      }
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
                          style:
                              TextStyle(fontSize: 13, color: p.textSecondary),
                        ),
                      ),
                    ),
                  for (var i = 0; i < _exercises.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfaceCard(
                        radius: 20,
                        onTap: () => _custom(i),
                        padding: const EdgeInsets.fromLTRB(12, 11, 10, 7),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ExerciseMark(_exercises[i].name, size: 40),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _exercises[i].name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: p.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_exercises[i].sets}×${_exercises[i].reps}'
                                        '${_exercises[i].rest.isNotEmpty ? ' · ${_exercises[i].rest}' : ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: p.textTertiary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Divider(
                              height: 1,
                              thickness: 0.7,
                              color: p.borderSubtle,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: '上移',
                                  constraints: const BoxConstraints.tightFor(
                                    width: 32,
                                    height: 30,
                                  ),
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: i == 0
                                      ? null
                                      : () => setState(() {
                                            final e = _exercises.removeAt(i);
                                            _exercises.insert(i - 1, e);
                                          }),
                                  icon: Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 17,
                                    color: i == 0
                                        ? p.textTertiary.withValues(alpha: .35)
                                        : p.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  tooltip: '下移',
                                  constraints: const BoxConstraints.tightFor(
                                    width: 32,
                                    height: 30,
                                  ),
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: i == _exercises.length - 1
                                      ? null
                                      : () => setState(() {
                                            final e = _exercises.removeAt(i);
                                            _exercises.insert(i + 1, e);
                                          }),
                                  icon: Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 17,
                                    color: i == _exercises.length - 1
                                        ? p.textTertiary.withValues(alpha: .35)
                                        : p.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: const Size(0, 30),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () => _remove(i),
                                  child: Text(
                                    '移除',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.danger,
                                    ),
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
        ),
      ),
    );
  }
}
