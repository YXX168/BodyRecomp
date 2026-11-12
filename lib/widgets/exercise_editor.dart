import 'package:flutter/material.dart';
import '../models/recomp_models.dart';

Future<Exercise?> editExercise(BuildContext context, {Exercise? initial}) =>
    showDialog<Exercise>(
        context: context, builder: (_) => _ExerciseEditor(initial: initial));

class _ExerciseEditor extends StatefulWidget {
  final Exercise? initial;
  const _ExerciseEditor({this.initial});
  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _sets =
      TextEditingController(text: '${widget.initial?.sets ?? 3}');
  late final _reps =
      TextEditingController(text: widget.initial?.reps ?? '10-12');
  late final _rest = TextEditingController(text: widget.initial?.rest ?? '60s');
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  @override
  void dispose() {
    for (final controller in [_name, _sets, _reps, _rest, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? '自定义训练项目' : '修改训练项目'),
        content: SingleChildScrollView(
            child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                      key: const Key('exercise-name'),
                      controller: _name,
                      maxLength: 80,
                      decoration: const InputDecoration(labelText: '项目名称'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? '请输入名称' : null),
                  TextFormField(
                      key: const Key('exercise-sets'),
                      controller: _sets,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '计划组数'),
                      validator: (v) {
                        final count = int.tryParse(v ?? '');
                        return count == null || count < 1 || count > 100
                            ? '请输入 1–100 组'
                            : null;
                      }),
                  TextFormField(
                      controller: _reps,
                      decoration: const InputDecoration(
                          labelText: '每组次数 / 时长', hintText: '例如 8-10 次、20 分钟'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? '请填写次数或时长' : null),
                  TextFormField(
                      controller: _rest,
                      decoration: const InputDecoration(
                          labelText: '组间休息', hintText: '例如 90s、2分钟；留空不计时')),
                  TextFormField(
                      controller: _note,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: '说明（选填）')),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                final original = widget.initial;
                Navigator.pop(
                    context,
                    Exercise(
                        name: _name.text.trim(),
                        muscles: original?.muscles ?? const [],
                        muscleTarget: original?.muscleTarget ?? '',
                        sets: int.parse(_sets.text),
                        reps: _reps.text.trim(),
                        rest: _rest.text.trim(),
                        note: _note.text.trim(),
                        isStar: original?.isStar ?? false));
              },
              child: const Text('保存')),
        ],
      );
}
