import 'package:flutter/material.dart';
import '../models/recomp_models.dart';
import '../services/rest_timer_service.dart';
import 'sheet_frame.dart';

Future<Exercise?> editExercise(BuildContext context, {Exercise? initial}) =>
    showModalBottomSheet<Exercise>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ExerciseEditor(initial: initial));

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

  void _step(int delta) {
    final value = ((int.tryParse(_sets.text) ?? 3) + delta).clamp(1, 100);
    _sets.text = '$value';
  }

  void _save() {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = colors.onSurface.withValues(alpha: .48);
    Widget label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.onSurface.withValues(alpha: .65))));
    InputDecoration field(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: colors.onSurface.withValues(alpha: .035),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          hintStyle: TextStyle(fontSize: 12, color: muted),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: colors.onSurface.withValues(alpha: .06))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: colors.primary.withValues(alpha: .65), width: 1.3)),
          errorMaxLines: 2,
        );
    return SheetFrame(
      title: widget.initial == null ? '自定义训练项目' : '编辑训练项目',
      subtitle: '按自己的习惯调整组数、次数和休息',
      icon: Icons.tune_rounded,
      body: Form(
          key: _form,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            label('项目名称'),
            TextFormField(
                key: const Key('exercise-name'),
                controller: _name,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                decoration: field('例如：平板卧推').copyWith(counterText: ''),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '请输入名称' : null),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    label('计划组数'),
                    TextFormField(
                        key: const Key('exercise-sets'),
                        controller: _sets,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        decoration: field('3').copyWith(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            prefixIconConstraints: const BoxConstraints(
                                minWidth: 32, maxWidth: 32),
                            suffixIconConstraints: const BoxConstraints(
                                minWidth: 32, maxWidth: 32),
                            prefixIcon: IconButton(
                                key: const Key('exercise-sets-minus'),
                                tooltip: '减少一组',
                                padding: EdgeInsets.zero,
                                onPressed: () => _step(-1),
                                icon: Icon(Icons.remove_rounded,
                                    size: 17, color: colors.primary)),
                            suffixIcon: IconButton(
                                key: const Key('exercise-sets-plus'),
                                tooltip: '增加一组',
                                padding: EdgeInsets.zero,
                                onPressed: () => _step(1),
                                icon: Icon(Icons.add_rounded,
                                    size: 17, color: colors.primary))),
                        validator: (v) {
                          final count = int.tryParse(v ?? '');
                          return count == null || count < 1 || count > 100
                              ? '请输入 1–100 组'
                              : null;
                        }),
                  ])),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    label('每组次数 / 时长'),
                    TextFormField(
                        key: const Key('exercise-reps'),
                        controller: _reps,
                        style: const TextStyle(fontSize: 13),
                        decoration: field('8–10 次 / 20 分钟'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? '请填写次数或时长' : null),
                  ])),
            ]),
            const SizedBox(height: 20),
            label('组间休息'),
            Wrap(spacing: 7, runSpacing: 7, children: [
              for (final option in [
                (0, '不计时'),
                (60, '60 秒'),
                (90, '90 秒'),
                (120, '2 分钟')
              ])
                ChoiceChip(
                    key: ValueKey('rest-preset-${option.$1}'),
                    label: Text(option.$2),
                    selected: (parseRestSeconds(_rest.text) ?? 0) == option.$1,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (parseRestSeconds(_rest.text) ?? 0) == option.$1
                            ? colors.onPrimary
                            : muted),
                    selectedColor: colors.primary,
                    backgroundColor: colors.onSurface.withValues(alpha: .035),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    onSelected: (_) => setState(() =>
                        _rest.text = option.$1 == 0 ? '' : '${option.$1}s')),
            ]),
            const SizedBox(height: 9),
            TextFormField(
                key: const Key('exercise-rest'),
                controller: _rest,
                style: const TextStyle(fontSize: 12),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  return text.isNotEmpty &&
                          !text.contains('循环') &&
                          parseRestSeconds(text) == null
                      ? '例如 75s、1分30秒；留空不计时'
                      : null;
                },
                decoration: field('自定义，例如 75s；留空不计时').copyWith(
                    prefixIcon:
                        Icon(Icons.timer_outlined, size: 17, color: muted))),
            const SizedBox(height: 20),
            label('补充说明 · 选填'),
            TextFormField(
                key: const Key('exercise-note'),
                controller: _note,
                minLines: 2,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, height: 1.5),
                decoration: field('动作要点、器械设置或当天感受')),
          ])),
      footer: Row(children: [
        Expanded(
            child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: BorderSide(
                        color: colors.onSurface.withValues(alpha: .12)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'))),
        const SizedBox(width: 10),
        Expanded(
            flex: 2,
            child: FilledButton(
                key: const Key('save-exercise'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _save,
                child: const Text('保存'))),
      ]),
    );
  }
}
