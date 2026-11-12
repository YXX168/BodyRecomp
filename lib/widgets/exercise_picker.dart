import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/exercise_library.dart';
import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import 'exercise_mark.dart';

Future<List<Exercise>?> pickExercises(
        BuildContext context, List<WorkoutTemplate> templates) =>
    showModalBottomSheet<List<Exercise>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ExercisePicker(templates: templates));

class _PickerItem {
  final String id;
  final String widgetKey;
  final Exercise exercise;
  const _PickerItem(this.id, this.widgetKey, this.exercise);
}

class _ExercisePicker extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  const _ExercisePicker({required this.templates});
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final _selected = <String, Exercise>{};
  int _source = 0;
  final _tabs = [0, 0];
  String _query = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scroll = ScrollController(keepScrollOffset: false);
  late final List<List<List<_PickerItem>>> _items;

  List<WorkoutTemplate> get _groups =>
      _source == 0 ? widget.templates : exerciseLibraryGroups;
  @override
  void initState() {
    super.initState();
    if (widget.templates.isEmpty) _source = 1;
    _items = [
      for (var source = 0; source < 2; source++)
        [
          for (var gi = 0;
              gi <
                  (source == 0 ? widget.templates : exerciseLibraryGroups)
                      .length;
              gi++)
            [
              for (var ei = 0;
                  ei <
                      (source == 0
                              ? widget.templates
                              : exerciseLibraryGroups)[gi]
                          .exercises
                          .length;
                  ei++)
                _PickerItem(
                    '${source == 0 ? 'template' : 'library'}:${(source == 0 ? widget.templates : exerciseLibraryGroups)[gi].id}:$ei',
                    source == 0
                        ? 'pick_${gi}_$ei'
                        : 'pick-${exerciseLibraryGroups[gi].id}-$ei',
                    (source == 0 ? widget.templates : exerciseLibraryGroups)[gi]
                        .exercises[ei]),
            ],
        ]
    ];
  }

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
      return _groups.isEmpty ? [] : _items[_source][_tabs[_source]];
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
                        .contains) &&
                seen.add(item.exercise.name.trim().toLowerCase()))
              item
    ];
  }

  void _toggle(_PickerItem item) {
    _searchFocus.unfocus();
    setState(() {
      if (_selected.containsKey(item.id)) {
        _selected.remove(item.id);
      } else {
        _selected[item.id] = item.exercise;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = colors.onSurface.withValues(alpha: .47);
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final compact = keyboard > 0;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8);
    final items = _visibleItems();
    final allSelected = items.isNotEmpty &&
        items.every((item) => _selected.containsKey(item.id));
    final template = _groups.isEmpty ? null : _groups[_tabs[_source]];
    return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Material(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                  height: math.min(media.size.height * .9,
                      media.size.height - keyboard - media.padding.top),
                  child: Column(children: [
                    Container(
                        width: 30,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10, bottom: 10),
                        decoration: BoxDecoration(
                            color: muted.withValues(alpha: .25),
                            borderRadius: BorderRadius.circular(4))),
                    if (!compact)
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 10, 2),
                          child: Row(children: [
                            const Expanded(
                                child: Text('添加训练项目',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700))),
                            Text('${_selected.length} 项已选',
                                style: TextStyle(fontSize: 10, color: muted)),
                            IconButton(
                                tooltip: '关闭',
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close_rounded,
                                    size: 18, color: muted)),
                          ])),
                    Padding(
                        key: const ValueKey('picker-search-container'),
                        padding:
                            EdgeInsets.fromLTRB(20, compact ? 0 : 8, 20, 10),
                        child: TextField(
                            key: const Key('exercise-search'),
                            controller: _searchController,
                            focusNode: _searchFocus,
                            style: const TextStyle(fontSize: 12),
                            onChanged: (value) {
                              _resetScroll();
                              setState(() => _query = value.trim());
                            },
                            decoration: InputDecoration(
                                hintText: '搜索动作或部位',
                                prefixIcon: Icon(Icons.search_rounded,
                                    size: 19, color: muted),
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
                                        icon: const Icon(Icons.close_rounded,
                                            size: 17)),
                                isDense: true,
                                filled: true,
                                fillColor: colors.surface,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none)))),
                    if (!compact && _query.isEmpty) ...[
                      Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                  color:
                                      colors.onSurface.withValues(alpha: .045),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [
                                for (var source = 0; source < 2; source++)
                                  Expanded(
                                      child: InkWell(
                                          key:
                                              ValueKey('picker-source-$source'),
                                          onTap: () => _switchSource(source),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 9),
                                              decoration: BoxDecoration(
                                                  color: _source == source
                                                      ? colors.surface
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                              child: Text(source == 0 ? '参考模板' : '动作库 · $libraryExerciseCount',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: _source == source
                                                          ? colors.primary
                                                          : muted))))),
                              ]))),
                      if (_groups.isNotEmpty)
                        SizedBox(
                            height: 42,
                            child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                children: [
                                  for (var gi = 0; gi < _groups.length; gi++)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(right: 7),
                                        child: _CategoryButton(
                                            key: ValueKey(
                                                'picker-template-${_groups[gi].id}'),
                                            label: _groups[gi].name,
                                            selected: _tabs[_source] == gi,
                                            onTap: () => _switchCategory(gi))),
                                ])),
                    ],
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  '${items.length} 个动作${_query.isNotEmpty ? ' · 搜索结果' : ''}',
                                  style:
                                      TextStyle(fontSize: 10, color: muted))),
                          if (!compact &&
                              _query.isEmpty &&
                              template?.note.isNotEmpty == true)
                            IconButton(
                                tooltip: '查看模板说明',
                                onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                            title: Text(template!.name),
                                            content: Text(template.note),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('知道了'))
                                            ])),
                                icon: Icon(Icons.info_outline_rounded,
                                    size: 16, color: muted)),
                          TextButton(
                              key: const Key('toggle-visible-selection'),
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
                              child: Text(allSelected ? '取消全选' : '全选',
                                  style: const TextStyle(fontSize: 11))),
                          TextButton(
                              key: const Key('clear-picked-exercises'),
                              onPressed: _selected.isEmpty
                                  ? null
                                  : () => setState(_selected.clear),
                              child: Text('清空',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _selected.isEmpty
                                          ? muted.withValues(alpha: .3)
                                          : muted))),
                        ])),
                    Expanded(
                        child: items.isEmpty
                            ? Center(
                                child: Text(
                                    _query.isEmpty
                                        ? '从动作库挑选，或先新建一个模板'
                                        : '没有找到这个动作',
                                    style:
                                        TextStyle(fontSize: 12, color: muted)))
                            : compact
                                ? ListView.builder(
                                    key: const ValueKey('picker-search-list'),
                                    controller: _scroll,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    itemCount: items.length,
                                    itemExtent: 64 * scale,
                                    itemBuilder: (context, index) =>
                                        _itemTile(items[index], compact: true))
                                : GridView.builder(
                                    key: const ValueKey('picker-exercise-grid'),
                                    controller: _scroll,
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 12),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                            mainAxisExtent: 132 * scale),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) =>
                                        _itemTile(items[index]))),
                    SafeArea(
                        top: false,
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                            child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                    key: const Key('add-picked-exercises'),
                                    style: FilledButton.styleFrom(
                                        minimumSize: const Size(0, 46),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(13))),
                                    onPressed: _selected.isEmpty
                                        ? null
                                        : () => Navigator.pop(
                                            context, _selected.values.toList()),
                                    child: Text(
                                        _selected.isEmpty
                                            ? '选择要加入的项目'
                                            : '加入 ${_selected.length} 个项目',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)))))),
                  ])),
            ),
          ),
        ));
  }

  Widget _itemTile(_PickerItem item, {bool compact = false}) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .45);
    final selected = _selected.containsKey(item.id);
    final exercise = item.exercise;
    final check = Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.add_circle_outline_rounded,
        size: 19,
        color: selected ? colors.primary : muted.withValues(alpha: .6));
    final title = Text(exercise.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600));
    final subtitle = Text('${exercise.sets} 组 × ${exercise.reps}',
        style: TextStyle(fontSize: 10, color: muted));
    return Padding(
        padding: compact ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: selected
                        ? colors.primary.withValues(alpha: .7)
                        : colors.onSurface.withValues(alpha: .035),
                    width: 1.2)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey(item.widgetKey),
              onTap: () => _toggle(item),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: compact
                      ? Row(children: [
                          ExerciseMark(exercise.name, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                title,
                                const SizedBox(height: 4),
                                subtitle
                              ])),
                          const SizedBox(width: 8),
                          check
                        ])
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Row(children: [
                                ExerciseMark(exercise.name, size: 46),
                                const Spacer(),
                                check
                              ]),
                              const Spacer(),
                              title,
                              const SizedBox(height: 5),
                              subtitle,
                            ])),
            ),
          ),
        ));
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryButton(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        selected: selected,
        button: true,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: selected ? null : onTap,
                borderRadius: BorderRadius.circular(10),
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                        color: selected
                            ? colors.primary.withValues(alpha: .09)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            width: 1,
                            color: selected
                                ? colors.primary.withValues(alpha: .3)
                                : colors.onSurface.withValues(alpha: .05))),
                    child: Text(label,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? colors.primary
                                : colors.onSurface.withValues(alpha: .6)))))));
  }
}
