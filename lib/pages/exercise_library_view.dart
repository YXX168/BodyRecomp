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
        SnackBar(content: Text('已添加动作「${created.exercise.name}」')),
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
        '已删除动作「${item.exercise.name}」',
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
          session.copyWith(blocks: nextBlocks, rested: false));
      workoutDataRevision.value++;
      workoutHistoryRevision.value++;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('已将「${item.exercise.name}」加入今日训练')),
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
        content: const Text('将恢复所有系统内置动作的默认内容，你新增的自定义动作会保留。'),
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
        const SnackBar(content: Text('已恢复内置动作（自定义动作已保留）')),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
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
                  hintText: '搜索动作、肌群或要点',
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
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const Key('add-library-exercise'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: _busy ? null : _addExercise,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('新增'),
            ),
            PopupMenuButton<String>(
              tooltip: '动作库选项',
              icon: Icon(Icons.more_vert_rounded, color: p.textSecondary),
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
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final cat in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: FilterChip(
                    key: ValueKey('library-cat-$cat'),
                    selected: _selectedCategory == cat,
                    showCheckmark: false,
                    label: Text('$cat ${_countForCategory(cat)}'),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _selectedCategory == cat
                          ? p.onPrimary
                          : p.textSecondary,
                    ),
                    selectedColor: p.primary,
                    backgroundColor: p.surface,
                    side: BorderSide(
                      color:
                          _selectedCategory == cat ? p.primary : p.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          SurfaceCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(Icons.fitness_center_rounded,
                    size: 32, color: p.textTertiary),
                const SizedBox(height: 10),
                Text(
                  _query.isNotEmpty ? '没有匹配的动作' : '该分类下暂无动作',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '点击右上角「新增」随时扩充你的个人动作库',
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
        for (final item in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(
              builder: (context) {
                final pr = exercisePersonalRecord(_logs, item.exercise.name);
                return SurfaceCard(
                  key: ValueKey('library-item-${item.id}'),
                  onTap: _busy ? null : () => _editExercise(item),
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  child: Row(
                    children: [
                      ExerciseMark(item.exercise.name, size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.exercise.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!item.isBuiltIn) ...[
                                  const SizedBox(width: 6),
                                  StatusPill(label: '自建', color: p.accent),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${item.category}${item.exercise.muscleTarget.isNotEmpty ? ' · ${item.exercise.muscleTarget}' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textSecondary,
                                  ),
                                ),
                                Text(
                                  '· ${item.exercise.sets}组 × ${item.exercise.reps}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            if (pr != null) ...[
                              const SizedBox(height: 5),
                              StatusPill(
                                label:
                                    'PR ${pr.weightKg == pr.weightKg.roundToDouble() ? pr.weightKg.toStringAsFixed(0) : pr.weightKg.toStringAsFixed(1)}kg × ${pr.reps}',
                                icon: Icons.emoji_events_rounded,
                                color: p.warning,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        key: ValueKey('fav-library-${item.id}'),
                        tooltip: item.isFavorite ? '取消收藏' : '收藏动作',
                        visualDensity: VisualDensity.compact,
                        onPressed: _busy ? null : () => _toggleFavorite(item),
                        icon: Icon(
                          item.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 20,
                          color: item.isFavorite ? p.warning : p.textTertiary,
                        ),
                      ),
                      IconButton(
                        key: ValueKey('add-today-library-${item.id}'),
                        tooltip: '加入今日训练',
                        visualDensity: VisualDensity.compact,
                        onPressed:
                            _busy ? null : () => _addToTodayWorkout(item),
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                          color: p.primary,
                        ),
                      ),
                      IconButton(
                        key: ValueKey('delete-library-${item.id}'),
                        tooltip: '删除动作',
                        visualDensity: VisualDensity.compact,
                        onPressed: _busy ? null : () => _deleteExercise(item),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: p.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
