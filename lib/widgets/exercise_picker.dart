import 'package:flutter/material.dart';
import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import 'exercise_mark.dart';

Future<List<Exercise>?> pickExercises(
        BuildContext context, List<WorkoutTemplate> templates) =>
    showModalBottomSheet<List<Exercise>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (_) => _ExercisePicker(templates: templates));

class _ExercisePicker extends StatefulWidget {
  final List<WorkoutTemplate> templates;
  const _ExercisePicker({required this.templates});
  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final _selected = <String, Exercise>{};
  int _tab = 0;
  String _query = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .45);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final compact = keyboard > 0;
    final template = widget.templates.isEmpty ? null : widget.templates[_tab];
    final items = <(int, int, Exercise)>[
      for (var ti = 0; ti < widget.templates.length; ti++)
        if (_query.isNotEmpty || ti == _tab)
          for (var ei = 0; ei < widget.templates[ti].exercises.length; ei++)
            if (_query.isEmpty ||
                widget.templates[ti].exercises[ei].name.contains(_query))
              (ti, ei, widget.templates[ti].exercises[ei]),
    ];
    return SizedBox(
        height: compact
            ? MediaQuery.sizeOf(context).height -
                keyboard -
                MediaQuery.paddingOf(context).top
            : MediaQuery.sizeOf(context).height * .86,
        child: Column(children: [
          Container(
              width: 30,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                  color: muted.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(4))),
          if (!compact)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(children: [
                  const Text('挑选训练积木',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${_selected.length} 项已选',
                      style: TextStyle(fontSize: 11, color: muted))
                ])),
          Padding(
              key: const ValueKey('picker-search-container'),
              padding: EdgeInsets.fromLTRB(20, compact ? 0 : 14, 20, 12),
              child: TextField(
                  key: const Key('exercise-search'),
                  controller: _searchController,
                  focusNode: _searchFocus,
                  style: const TextStyle(fontSize: 12),
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                      hintText: '搜索动作',
                      prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none)))),
          if (widget.templates.length > 1 && _query.isEmpty && !compact)
            SizedBox(
                height: 36,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      for (var i = 0; i < widget.templates.length; i++)
                        Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                                key: ValueKey(
                                    'picker-template-${widget.templates[i].id}'),
                                label: Text(widget.templates[i].name,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: _tab == i
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface)),
                                selected: _tab == i,
                                onSelected: (_) => setState(() => _tab = i),
                                showCheckmark: false,
                                side: BorderSide.none,
                                selectedColor: theme.colorScheme.primary
                                    .withValues(alpha: .12)))
                    ])),
          if (template != null && !compact)
            Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 16, 4),
                child: Row(children: [
                  Expanded(
                      child: Text('${items.length} 个动作',
                          style: TextStyle(fontSize: 11, color: muted))),
                  if (template.note.isNotEmpty && _query.isEmpty)
                    IconButton(
                        tooltip: '查看模板说明',
                        onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                    title: Text(template.name),
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
                      onPressed: () => setState(() {
                            for (final item in items) {
                              _selected['${item.$1}_${item.$2}'] = item.$3;
                            }
                          }),
                      child: const Text('全选', style: TextStyle(fontSize: 11)))
                ])),
          Expanded(
              child: template == null
                  ? const Center(child: Text('先创建一个模板'))
                  : items.isEmpty
                      ? const Center(
                          child:
                              Text('没有找到这个动作', style: TextStyle(fontSize: 12)))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  mainAxisExtent: 140 *
                                      MediaQuery.textScalerOf(context)
                                          .scale(1)
                                          .clamp(1, 1.6)),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final exercise = item.$3;
                            final id = '${item.$1}_${item.$2}';
                            final selected = _selected.containsKey(id);
                            return InkWell(
                                key: ValueKey('pick_${item.$1}_${item.$2}'),
                                borderRadius: BorderRadius.circular(17),
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  setState(() {
                                    if (selected) {
                                      _selected.remove(id);
                                    } else {
                                      _selected[id] = exercise;
                                    }
                                  });
                                },
                                child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(17),
                                        border: Border.all(
                                            color: selected
                                                ? theme.colorScheme.primary
                                                : Colors.transparent,
                                            width: 1.3)),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            ExerciseMark(exercise.name,
                                                size: 52),
                                            const Spacer(),
                                            Icon(
                                                selected
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                        .add_circle_outline_rounded,
                                                size: 18,
                                                color: selected
                                                    ? theme.colorScheme.primary
                                                    : muted.withValues(
                                                        alpha: .5))
                                          ]),
                                          const Spacer(),
                                          Text(exercise.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 5),
                                          Text(
                                              '${exercise.sets} 组 × ${exercise.reps}',
                                              style: TextStyle(
                                                  fontSize: 10, color: muted)),
                                        ])));
                          })),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                      key: const Key('add-picked-exercises'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      onPressed: _selected.isEmpty
                          ? null
                          : () =>
                              Navigator.pop(context, _selected.values.toList()),
                      child: Text('加入 ${_selected.length} 个项目',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600))))),
        ]));
  }
}
