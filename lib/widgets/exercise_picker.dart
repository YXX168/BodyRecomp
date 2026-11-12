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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .45);
    final template = widget.templates.isEmpty ? null : widget.templates[_tab];
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .80,
        child: Column(children: [
          Container(
              width: 30,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                  color: muted.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(4))),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(children: [
                const Text('挑选训练积木',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${_selected.length} 项已选',
                    style: TextStyle(fontSize: 11, color: muted))
              ])),
          const SizedBox(height: 16),
          if (widget.templates.length > 1)
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
          if (template != null)
            Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 16, 4),
                child: Row(children: [
                  Expanded(
                      child: Text(template.name,
                          style: TextStyle(fontSize: 11, color: muted))),
                  TextButton(
                      onPressed: () => setState(() {
                            for (var ei = 0;
                                ei < template.exercises.length;
                                ei++) {
                              _selected['${_tab}_$ei'] = template.exercises[ei];
                            }
                          }),
                      child: const Text('全选', style: TextStyle(fontSize: 11)))
                ])),
          if (template != null && template.note.isNotEmpty)
            Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                child: Text(template.note,
                    style: TextStyle(fontSize: 11, color: muted, height: 1.5))),
          Expanded(
              child: template == null
                  ? const Center(child: Text('先创建一个模板'))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 126 *
                              MediaQuery.textScalerOf(context)
                                  .scale(1)
                                  .clamp(1, 1.6)),
                      itemCount: template.exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = template.exercises[index];
                        final id = '${_tab}_$index';
                        final selected = _selected.containsKey(id);
                        return InkWell(
                            key: ValueKey('pick_${_tab}_$index'),
                            borderRadius: BorderRadius.circular(17),
                            onTap: () => setState(() {
                                  if (selected) {
                                    _selected.remove(id);
                                  } else {
                                    _selected[id] = exercise;
                                  }
                                }),
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
                                        ExerciseMark(exercise.name, size: 33),
                                        const Spacer(),
                                        Icon(
                                            selected
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .add_circle_outline_rounded,
                                            size: 18,
                                            color: selected
                                                ? theme.colorScheme.primary
                                                : muted.withValues(alpha: .5))
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
