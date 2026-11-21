import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/exercise_library.dart';
import '../models/daily_workout.dart';
import '../models/library_exercise.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/exercise_library_service.dart';
import '../theme/app_theme.dart';
import 'ambient_background.dart';
import 'exercise_editor.dart';
import 'exercise_mark.dart';

Future<List<Exercise>?> pickExercises(
  BuildContext context,
  List<WorkoutTemplate> templates, {
  int initialSource = 0,
}) =>
    showModalBottomSheet<List<Exercise>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePicker(
        templates: templates,
        initialSource: initialSource,
      ),
    );

class _PickerItem {
  final String id;
  final String widgetKey;
  final Exercise exercise;
  const _PickerItem(this.id, this.widgetKey, this.exercise);
}

class _ExercisePicker extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  final int initialSource;
  const _ExercisePicker({
    required this.templates,
    this.initialSource = 0,
  });

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final _selected = <String, Exercise>{};
  late int _source = widget.templates.isEmpty ? 1 : widget.initialSource;
  final _tabs = [0, 0];
  String _query = '';
  String? _errorMessage;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _searchKey = GlobalKey();
  final _scroll = ScrollController(keepScrollOffset: false);

  List<LibraryExercise> _libraryItems = buildDefaultExerciseLibrary();
  late List<WorkoutTemplate> _libraryGroups =
      groupExerciseLibrary(_libraryItems);
  late List<List<List<_PickerItem>>> _items = _buildItems();

  String _identity(Exercise exercise) => jsonEncode(exercise.toJson());

  List<WorkoutTemplate> get _groups =>
      _source == 0 ? widget.templates : _libraryGroups;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    try {
      final loaded = await loadExerciseLibrary();
      if (!mounted) return;
      setState(() {
        _libraryItems = loaded;
        _libraryGroups = groupExerciseLibrary(loaded);
        if (_tabs[1] >= _libraryGroups.length) {
          _tabs[1] = math.max(0, _libraryGroups.length - 1);
        }
        _items = _buildItems();
      });
    } catch (_) {
      // Keep synchronous fallback catalog on unexpected read errors.
    }
  }

  List<List<List<_PickerItem>>> _buildItems() => [
        for (var source = 0; source < 2; source++)
          [
            for (var gi = 0;
                gi < (source == 0 ? widget.templates : _libraryGroups).length;
                gi++)
              [
                for (var ei = 0;
                    ei <
                        (source == 0 ? widget.templates : _libraryGroups)[gi]
                            .exercises
                            .length;
                    ei++)
                  _PickerItem(
                    _identity(
                      (source == 0 ? widget.templates : _libraryGroups)[gi]
                          .exercises[ei],
                    ),
                    source == 0
                        ? 'pick_${gi}_$ei'
                        : 'pick-${_libraryGroups[gi].id}-$ei',
                    (source == 0 ? widget.templates : _libraryGroups)[gi]
                        .exercises[ei],
                  ),
              ],
          ],
      ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _resetScroll() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _switchSource(int source) {
    if (_source == source) return;
    _resetScroll();
    setState(() => _source = source);
  }

  void _switchCategory(int tab) {
    if (_tabs[_source] == tab) return;
    _resetScroll();
    setState(() => _tabs[_source] = tab);
  }

  List<_PickerItem> _visibleItems() {
    if (_query.isEmpty) {
      if (_groups.isEmpty) return [];
      final tab = _tabs[_source].clamp(0, _groups.length - 1);
      return _items[_source][tab];
    }
    final words = _query.toLowerCase().split(RegExp(r'\s+'));
    final seen = <String>{};
    return [
      for (final source in _items)
        for (final group in source)
          for (final item in group)
            if (words.every(
                  ('${item.exercise.name} ${item.exercise.muscles.join(' ')} ${item.exercise.muscleTarget}')
                      .toLowerCase()
                      .contains,
                ) &&
                seen.add(item.id))
              item,
    ];
  }

  void _toggle(_PickerItem item) {
    setState(() {
      if (_selected.containsKey(item.id)) {
        _selected.remove(item.id);
      } else {
        _selected[item.id] = item.exercise;
      }
    });
  }

  Future<void> _createAndSelectExercise() async {
    final created = await editLibraryExercise(context);
    if (created == null || !mounted) return;
    try {
      final updated = await addLibraryExercise(created);
      exerciseLibraryRevision.value++;
      if (!mounted) return;
      setState(() {
        _libraryItems = updated;
        _libraryGroups = groupExerciseLibrary(updated);
        _items = _buildItems();
        _source = 1;
        final catIndex = _libraryGroups
            .indexWhere((group) => group.name == created.category);
        if (catIndex >= 0) _tabs[1] = catIndex;
        _selected[_identity(created.exercise)] = created.exercise;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '新增动作保存失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final compact = keyboard > 0;
    final scale = media.textScaler.scale(12) / 12;
    final height = math.max(
      0.0,
      math.min(
        media.size.height * .9,
        media.size.height - keyboard - media.padding.top,
      ),
    );
    final short = height < (compact ? 240 : 360) + (scale - 1) * 240;
    final items = _visibleItems();
    final allSelected = items.isNotEmpty &&
        items.every((item) => _selected.containsKey(item.id));
    final template = _groups.isEmpty
        ? null
        : _groups[_tabs[_source].clamp(0, _groups.length - 1)];

    final controls = <Widget>[
      Center(
        child: Container(
          width: 34,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: p.textTertiary.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      if (!compact)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '添加训练项目',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    Text(
                      '${_selected.length} 项已选',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                key: const Key('picker-add-custom'),
                onPressed: _createAndSelectExercise,
                icon: Icon(Icons.add_circle_outline_rounded,
                    size: 16, color: p.primary),
                label: Text(
                  '新增动作',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.pop(context),
                icon:
                    Icon(Icons.close_rounded, size: 20, color: p.textSecondary),
              ),
            ],
          ),
        ),
      Padding(
        key: _searchKey,
        padding: EdgeInsets.fromLTRB(20, compact ? 0 : 8, 20, 10),
        child: TextField(
          key: const Key('exercise-search'),
          controller: _searchController,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 13, color: p.textPrimary),
          onChanged: (value) {
            _resetScroll();
            setState(() => _query = value.trim());
          },
          decoration: InputDecoration(
            hintText: '搜索动作名称或目标肌群',
            prefixIcon:
                Icon(Icons.search_rounded, size: 19, color: p.textTertiary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    key: const Key('clear-exercise-search'),
                    tooltip: '清除搜索',
                    onPressed: () {
                      _searchController.clear();
                      _resetScroll();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            isDense: true,
            filled: true,
            fillColor: p.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      if (!compact && _query.isEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Row(
              children: [
                for (var source = 0; source < 2; source++)
                  Expanded(
                    child: InkWell(
                      key: ValueKey('picker-source-$source'),
                      onTap: () => _switchSource(source),
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _source == source
                              ? p.primary.withValues(
                                  alpha: p.isDark ? .20 : .14,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          border: _source == source
                              ? Border.all(color: p.borderHighlight, width: 0.9)
                              : null,
                        ),
                        child: Text(
                          source == 0
                              ? '参考模板 (${widget.templates.length})'
                              : '动作库 · ${_libraryItems.length}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                _source == source ? p.primary : p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_groups.isNotEmpty)
          SizedBox(
            height: math.max(42, 24 + media.textScaler.scale(12) * 1.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var gi = 0; gi < _groups.length; gi++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryButton(
                        key: ValueKey('picker-template-${_groups[gi].id}'),
                        label: _groups[gi].name,
                        selected: _tabs[_source] == gi,
                        onTap: () => _switchCategory(gi),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 14, 4),
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              '${items.length} 个动作${_query.isNotEmpty ? ' · 搜索结果' : ''}',
              style: TextStyle(fontSize: 11.5, color: p.textSecondary),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact &&
                    _query.isEmpty &&
                    template?.note.isNotEmpty == true)
                  IconButton(
                    tooltip: '查看模板说明',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showGlassConfirm(
                      context: context,
                      title: template!.name,
                      message: template.note,
                      icon: Icons.info_outline_rounded,
                      cancelLabel: null,
                      confirmLabel: '知道了',
                    ),
                    icon: Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: p.textSecondary,
                    ),
                  ),
                TextButton(
                  key: const Key('toggle-visible-selection'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: items.isEmpty
                      ? null
                      : () => setState(() {
                            for (final item in items) {
                              if (allSelected) {
                                _selected.remove(item.id);
                              } else {
                                _selected[item.id] = item.exercise;
                              }
                            }
                          }),
                  child: Text(
                    allSelected ? '取消全选' : '全选',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  key: const Key('clear-picked-exercises'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _selected.isEmpty
                      ? null
                      : () => setState(_selected.clear),
                  child: Text(
                    '清空',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selected.isEmpty
                          ? p.textTertiary.withValues(alpha: .4)
                          : p.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (_errorMessage != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.danger,
            ),
          ),
        ),
    ];

    final footer = SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, short ? 4 : 10, 20, short ? 6 : 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('add-picked-exercises'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.pop(context, _selected.values.toList()),
            child: Text(
              _selected.isEmpty ? '选择要加入的项目' : '加入 ${_selected.length} 个项目',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );

    final empty = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _query.isEmpty ? '当前分类暂无动作，点击右上角新增或切换分类' : '没有找到这个动作',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textSecondary),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _createAndSelectExercise,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('新增自定义动作'),
          ),
        ],
      ),
    );

    final tileTitleH = media.textScaler.scale(13.5) * 1.45 * 2;
    final tileSubH = media.textScaler.scale(11.5) * 1.45;
    final gridExtent = math.max(142.0, 90.0 + tileTitleH + tileSubH);
    final glassTop = p.isDark
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: .06),
            p.surfaceElevated.withValues(alpha: .84),
          )
        : Colors.white.withValues(alpha: .86);
    final glassBottom = p.isDark
        ? p.canvas.withValues(alpha: .92)
        : p.surfaceElevated.withValues(alpha: .80);

    final results = items.isEmpty
        ? Center(child: empty)
        : compact
            ? ListView.builder(
                key: const ValueKey('picker-search-list'),
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder: (_, index) =>
                    _itemTile(items[index], compact: true),
              )
            : GridView.builder(
                key: const ValueKey('picker-exercise-grid'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: gridExtent,
                ),
                itemCount: items.length,
                itemBuilder: (_, index) => _itemTile(items[index]),
              );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [glassTop, glassBottom],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: p.glassRimBright.withValues(alpha: .54),
                    width: 1.05,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: height,
                    child: Column(
                      children: [
                        if (!short) ...controls,
                        Expanded(
                          child: short
                              ? CustomScrollView(
                                  key: const ValueKey('picker-compact-scroll'),
                                  controller: _scroll,
                                  slivers: [
                                    SliverList.list(children: controls),
                                    if (items.isEmpty)
                                      SliverToBoxAdapter(child: empty)
                                    else
                                      SliverPadding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        sliver: SliverList.builder(
                                          itemCount: items.length,
                                          itemBuilder: (_, index) => _itemTile(
                                              items[index],
                                              compact: true),
                                        ),
                                      ),
                                  ],
                                )
                              : results,
                        ),
                        footer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemTile(_PickerItem item, {bool compact = false}) {
    final p = context.palette;
    final selected = _selected.containsKey(item.id);
    final exercise = item.exercise;
    final check = Icon(
      selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
      size: 20,
      color: selected ? p.primary : p.textTertiary,
    );
    final title = Text(
      exercise.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: p.textPrimary,
      ),
    );
    final subtitle = Text(
      '${exercise.sets} 组 × ${exercise.reps}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11.5, color: p.textSecondary),
    );

    return Padding(
      padding: compact ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [
                        p.primary.withValues(alpha: p.isDark ? .20 : .14),
                        p.accent.withValues(alpha: p.isDark ? .08 : .05),
                      ]
                    : [p.glassFillTop, p.glassFillBottom],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? p.borderHighlight : p.borderSubtle,
                width: selected ? 1.3 : 1.0,
              ),
            ),
            child: InkWell(
              key: ValueKey(item.widgetKey),
              borderRadius: BorderRadius.circular(18),
              onTap: () => _toggle(item),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: compact
                    ? Row(
                        children: [
                          ExerciseMark(exercise.name, size: 38),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                title,
                                const SizedBox(height: 3),
                                subtitle,
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          check,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ExerciseMark(exercise.name, size: 46),
                              const Spacer(),
                              check,
                            ],
                          ),
                          const Spacer(),
                          title,
                          const SizedBox(height: 4),
                          subtitle,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? p.primary.withValues(alpha: p.isDark ? .18 : .12)
                  : p.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 1,
                color: selected ? p.borderHighlight : p.borderSubtle,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? p.primary : p.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
