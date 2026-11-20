import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/exercise_library.dart';
import '../models/daily_workout.dart';
import '../models/library_exercise.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../services/data_service.dart';
import '../services/exercise_library_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/exercise_mark.dart';
import '../widgets/loading_view.dart';
import '../widgets/undo_notice.dart';

class ExerciseLibraryView extends StatefulWidget {
  const ExerciseLibraryView({super.key});

  @override
  State<ExerciseLibraryView> createState() => _ExerciseLibraryViewState();
}

class _ExerciseLibraryViewState extends State<ExerciseLibraryView> {
  List<LibraryExercise>? _items;
  List<ExerciseLog> _logs = [];
  String _selectedCategory = '全部';
  String _query = '';
  String? _error;
  bool _busy = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    exerciseLibraryRevision.addListener(_load);
    exerciseLogsRevision.addListener(_load);
    workoutDataRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    exerciseLibraryRevision.removeListener(_load);
    exerciseLogsRevision.removeListener(_load);
    workoutDataRevision.removeListener(_load);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await loadExerciseLibrary();
      final logs = await loadExerciseLogs();
      if (!mounted) return;
      setState(() {
        _items = items;
        _logs = logs;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = '动作库读取失败，原数据未被覆盖。');
      }
    }
  }

  List<String> get _categories {
    final items = _items ?? const <LibraryExercise>[];
    final existing = items.map((e) => e.category).toSet();
    return [
      '全部',
      '收藏',
      for (final cat in exerciseCategories)
        if (existing.contains(cat)) cat,
      ...existing.where((c) => !exerciseCategories.contains(c)),
    ];
  }

  List<LibraryExercise> get _filtered {
    final items = _items ?? const <LibraryExercise>[];
    final words = _query.trim().isEmpty
        ? const <String>[]
        : _query.trim().toLowerCase().split(RegExp(r'\s+'));
    return [
      for (final item in items)
        if ((_selectedCategory == '全部' ||
                (_selectedCategory == '收藏' && item.isFavorite) ||
                item.category == _selectedCategory) &&
            (words.isEmpty ||
                words.every(
                  ('${item.exercise.name} ${item.category} ${item.exercise.muscleTarget} ${item.exercise.note ?? ''}')
                      .toLowerCase()
                      .contains,
                )))
          item,
    ];
  }

  int _countForCategory(String cat) {
    final items = _items ?? const <LibraryExercise>[];
    if (cat == '全部') return items.length;
    if (cat == '收藏') return items.where((e) => e.isFavorite).length;
    return items.where((e) => e.category == cat).length;
  }

  Future<void> _addExercise() async {
    if (_busy) return;
    final created = await editLibraryExercise(context);
    if (created == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await addLibraryExercise(created);
      exerciseLibraryRevision.value++;
      if (!mounted) return;
      setState(() {
        _items = updated;
        if (_selectedCategory != '全部' &&
            _selectedCategory != created.category) {
          _selectedCategory = created.category;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加「${created.exercise.name}」')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('添加动作失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editExercise(LibraryExercise item) async {
    if (_busy) return;
    final edited = await editLibraryExercise(context, initial: item);
    if (edited == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await updateLibraryExercise(edited);
      exerciseLibraryRevision.value++;
      if (mounted) setState(() => _items = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新动作失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFavorite(LibraryExercise item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await updateLibraryExercise(
        item.copyWith(isFavorite: !item.isFavorite),
      );
      exerciseLibraryRevision.value++;
      if (mounted) setState(() => _items = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('收藏更新失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteExercise(LibraryExercise item) async {
    if (_busy) return;
    final previous = List<LibraryExercise>.from(_items ?? []);
    setState(() => _busy = true);
    try {
      final updated = await deleteLibraryExercise(item.id);
      exerciseLibraryRevision.value++;
      if (!mounted) return;
      setState(() => _items = updated);
      showUndoNotice(
        context,
        '已删除「${item.exercise.name}」',
        onUndo: () async {
          try {
            await saveExerciseLibrary(previous);
            exerciseLibraryRevision.value++;
            if (mounted) setState(() => _items = previous);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('恢复动作失败，请重试')),
              );
            }
          }
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除动作失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addToTodayWorkout(LibraryExercise item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final todayDate = dateOnly(DateTime.now());
      final key = dayKey(todayDate);
      final sessions = await loadDailyWorkouts();
      var session = sessions[key];

      if (session == null) {
        final templates = await loadWorkoutTemplates();
        final schedule = await loadWeeklySchedule();
        final boundId = schedule[todayDate.weekday - 1];
        final matched = templates.where((t) => t.id == boundId);
        final initialBlocks = matched.isNotEmpty
            ? instantiateTemplateBlocks(matched.first, key)
            : <WorkoutBlock>[];
        session = DailyWorkout(date: key, blocks: initialBlocks);
      }

      final nextBlocks = List<WorkoutBlock>.from(session.blocks)
        ..add(
          WorkoutBlock(
            id: 'block_${DateTime.now().microsecondsSinceEpoch}',
            exercise: item.exercise,
          ),
        );
      await saveDailyWorkout(
        session.copyWith(blocks: nextBlocks, rested: false),
      );
      workoutDataRevision.value++;
      workoutHistoryRevision.value++;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('已加入今日「${item.exercise.name}」')),
        );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加入今日训练失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复内置动作？'),
        content: const Text('将恢复系统默认动作，自建动作会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复内置'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await restoreDefaultExerciseLibrary(keepCustom: true);
      exerciseLibraryRevision.value++;
      if (!mounted) return;
      setState(() => _items = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复内置动作')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('恢复内置动作失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtWeight(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

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
    if (_items == null) return const LoadingView();

    final visible = _filtered;
    final categories = _categories;
    final scaler = MediaQuery.textScalerOf(context);
    final cardExtent = 120.0 +
        scaler.scale(13.5) * 1.45 +
        math.max(30.0, scaler.scale(11.5) * 1.45);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('library-search'),
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        style: TextStyle(fontSize: 13.5, color: p.textPrimary),
                        decoration: InputDecoration(
                          hintText: '搜索动作',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: p.textTertiary,
                          ),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  key: const Key('clear-library-search'),
                                  tooltip: '清除搜索',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: '新增动作',
                      child: FilledButton(
                        key: const Key('add-library-exercise'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _busy ? null : _addExercise,
                        child: const Icon(Icons.add_rounded, size: 22),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: '动作库选项',
                      constraints:
                          const BoxConstraints.tightFor(width: 34, height: 44),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert_rounded,
                          size: 20, color: p.textSecondary),
                      onSelected: (value) {
                        if (value == 'restore') _restoreDefaults();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'restore',
                          child: Text('恢复内置默认动作'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: FilterChip(
                            key: ValueKey('library-cat-$cat'),
                            selected: _selectedCategory == cat,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '${cat == '收藏' ? '★ 收藏' : cat} ${_countForCategory(cat)}',
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: _selectedCategory == cat
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedCategory == cat
                                  ? p.onPrimary
                                  : p.textSecondary,
                            ),
                            selectedColor: p.primary,
                            backgroundColor: p.isDark
                                ? Colors.white.withValues(alpha: .06)
                                : Colors.white.withValues(alpha: .65),
                            side: BorderSide(
                              color: _selectedCategory == cat
                                  ? p.primary
                                  : p.borderSubtle,
                              width: 0.85,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
            sliver: SliverToBoxAdapter(
              child: SurfaceCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        size: 34, color: p.textTertiary),
                    const SizedBox(height: 10),
                    Text(
                      _query.isNotEmpty ? '没有匹配的动作' : '该分类暂无动作',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                mainAxisExtent: cardExtent,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = visible[index];
                  final pr = exercisePersonalRecord(_logs, item.exercise.name);
                  return SurfaceCard(
                    key: ValueKey('library-item-${item.id}'),
                    onTap: _busy ? null : () => _editExercise(item),
                    radius: 20,
                    padding: const EdgeInsets.fromLTRB(12, 8, 10, 11),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: IconButton(
                                key: ValueKey('fav-library-${item.id}'),
                                tooltip: item.isFavorite ? '取消收藏' : '收藏',
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed:
                                    _busy ? null : () => _toggleFavorite(item),
                                icon: Icon(
                                  item.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 17,
                                  color: item.isFavorite
                                      ? p.warning
                                      : p.textTertiary.withValues(alpha: .65),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!item.isBuiltIn)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.accent,
                                ),
                              ),
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: IconButton(
                                key: ValueKey('delete-library-${item.id}'),
                                tooltip: '删除动作',
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed:
                                    _busy ? null : () => _deleteExercise(item),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: p.textTertiary.withValues(alpha: .52),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        ExerciseMark(item.exercise.name, size: 48),
                        const Spacer(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.exercise.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pr != null
                                    ? 'PR ${_fmtWeight(pr.weightKg)}kg'
                                    : '${item.exercise.sets}×${item.exercise.reps}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      pr != null ? p.warning : p.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 30,
                              height: 30,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: ValueKey('add-today-library-${item.id}'),
                                  customBorder: const CircleBorder(),
                                  onTap: _busy
                                      ? null
                                      : () => _addToTodayWorkout(item),
                                  child: Tooltip(
                                    message: '加入今日训练',
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: p.primary.withValues(
                                          alpha: p.isDark ? .18 : .12,
                                        ),
                                        border: Border.all(
                                          color:
                                              p.primary.withValues(alpha: .35),
                                          width: 0.85,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: p.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: visible.length,
              ),
            ),
          ),
      ],
    );
  }
}
