import 'package:flutter/material.dart';
import '../data/exercise_library.dart';
import '../models/library_exercise.dart';
import '../models/recomp_models.dart';
import '../services/rest_timer_service.dart';
import '../theme/app_theme.dart';
import 'muscle_body_graphic.dart';
import 'sheet_frame.dart';

class ExerciseEditResult {
  final Exercise exercise;
  final String category;
  final bool saveToLibrary;
  final bool isFavorite;

  const ExerciseEditResult({
    required this.exercise,
    required this.category,
    this.saveToLibrary = false,
    this.isFavorite = false,
  });
}

Future<Exercise?> editExercise(BuildContext context,
    {Exercise? initial}) async {
  final res = await editExerciseDetailed(context, initial: initial);
  return res?.exercise;
}

Future<ExerciseEditResult?> editExerciseDetailed(
  BuildContext context, {
  Exercise? initial,
  String? initialCategory,
  bool offerSaveToLibrary = false,
  bool isLibraryMode = false,
  bool initialFavorite = false,
}) =>
    showModalBottomSheet<ExerciseEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseEditor(
        initial: initial,
        initialCategory: initialCategory,
        offerSaveToLibrary: offerSaveToLibrary,
        isLibraryMode: isLibraryMode,
        initialFavorite: initialFavorite,
      ),
    );

Future<LibraryExercise?> editLibraryExercise(
  BuildContext context, {
  LibraryExercise? initial,
}) async {
  final res = await editExerciseDetailed(
    context,
    initial: initial?.exercise,
    initialCategory: initial?.category,
    isLibraryMode: true,
    initialFavorite: initial?.isFavorite ?? false,
  );
  if (res == null) return null;
  if (initial != null) {
    return initial.copyWith(
      category: res.category,
      exercise: res.exercise,
      isFavorite: res.isFavorite,
    );
  }
  return LibraryExercise(
    id: 'lib_${DateTime.now().microsecondsSinceEpoch}',
    category: res.category,
    exercise: res.exercise,
    isFavorite: res.isFavorite,
    isBuiltIn: false,
  );
}

class _ExerciseEditor extends StatefulWidget {
  final Exercise? initial;
  final String? initialCategory;
  final bool offerSaveToLibrary;
  final bool isLibraryMode;
  final bool initialFavorite;

  const _ExerciseEditor({
    this.initial,
    this.initialCategory,
    this.offerSaveToLibrary = false,
    this.isLibraryMode = false,
    this.initialFavorite = false,
  });

  @override
  State<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<_ExerciseEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _target =
      TextEditingController(text: widget.initial?.muscleTarget ?? '');
  late final _sets =
      TextEditingController(text: '${widget.initial?.sets ?? 3}');
  late final _reps =
      TextEditingController(text: widget.initial?.reps ?? '10-12');
  late final _rest = TextEditingController(text: widget.initial?.rest ?? '60s');
  late final _note = TextEditingController(text: widget.initial?.note ?? '');

  late String _category = _resolveInitialCategory();
  bool _categoryEdited = false;
  late bool _saveToLibrary = widget.offerSaveToLibrary;
  late bool _isFavorite = widget.initialFavorite;

  static String? _mapTagToCategory(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return null;
    for (final cat in exerciseCategories) {
      if (t == cat.toLowerCase()) return cat;
    }
    if (RegExp(r'胸|chest|pec').hasMatch(t)) return '胸部';
    if (RegExp(r'背|背阔|斜方|菱形|back|lat').hasMatch(t)) return '背部';
    if (RegExp(r'肩|三角肌|shoulder|delt').hasMatch(t)) return '肩部';
    if (RegExp(r'腿|臀|股四|腘绳|小腿|leg|glute|quad|hamstring|calf').hasMatch(t)) {
      return '腿臀';
    }
    if (RegExp(r'臂|二头|三头|肱|腕|arm|bicep|tricep').hasMatch(t)) return '手臂';
    if (RegExp(r'腹|核心|core|abs').hasMatch(t)) return '核心';
    if (RegExp(r'有氧|心肺|恢复|拉伸|放松|cardio|hiit|recovery|stretch').hasMatch(t)) {
      return '有氧恢复';
    }
    if (t == '其他' || t == 'other') return '其他';
    return null;
  }

  String _resolveInitialCategory() {
    if (widget.initialCategory != null &&
        widget.initialCategory!.trim().isNotEmpty) {
      return _mapTagToCategory(widget.initialCategory!) ??
          widget.initialCategory!;
    }
    final muscles = widget.initial?.muscles ?? const [];
    for (final m in muscles) {
      final mapped = _mapTagToCategory(m);
      if (mapped != null) return mapped;
    }
    if (widget.initial != null) {
      final inferred = inferMuscleGroups([widget.initial!]);
      const order = [
        ('chest', '胸部'),
        ('back', '背部'),
        ('shoulders', '肩部'),
        ('legs', '腿臀'),
        ('arms', '手臂'),
        ('core', '核心'),
        ('cardio', '有氧恢复'),
      ];
      for (final (key, cat) in order) {
        if (inferred.contains(key)) return cat;
      }
    }
    return exerciseCategories.first;
  }

  @override
  void dispose() {
    for (final controller in [_name, _target, _sets, _reps, _rest, _note]) {
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
    final muscles =
        (original != null && !_categoryEdited) ? original.muscles : [_category];
    final exercise = Exercise(
      name: _name.text.trim(),
      muscles: muscles,
      muscleTarget: _target.text.trim(),
      sets: int.parse(_sets.text),
      reps: _reps.text.trim(),
      rest: _rest.text.trim(),
      note: _note.text.trim(),
      isStar: original?.isStar ?? false,
    );
    Navigator.pop(
      context,
      ExerciseEditResult(
        exercise: exercise,
        category: _category,
        saveToLibrary: _saveToLibrary,
        isFavorite: _isFavorite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.textSecondary,
            ),
          ),
        );

    InputDecoration field(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: p.surfaceMuted,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintStyle: TextStyle(fontSize: 13, color: p.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: p.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: p.primary, width: 1.4),
          ),
          errorMaxLines: 2,
        );

    return SheetFrame(
      title: widget.isLibraryMode
          ? (widget.initial == null ? '新增动作库动作' : '编辑动作库动作')
          : (widget.initial == null ? '自定义训练项目' : '编辑训练项目'),
      subtitle: '自由设定肌群分类、组数、次数与组间休息',
      icon: Icons.tune_rounded,
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label('动作名称'),
            TextFormField(
              key: const Key('exercise-name'),
              controller: _name,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: p.textPrimary,
              ),
              decoration: field('例如：平板卧推').copyWith(counterText: ''),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),
            label('所属部位分类'),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final cat in exerciseCategories)
                  ChoiceChip(
                    key: ValueKey('category-chip-$cat'),
                    label: Text(cat),
                    selected: _category == cat,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _category == cat ? p.onPrimary : p.textSecondary,
                    ),
                    selectedColor: p.primary,
                    backgroundColor: p.surfaceMuted,
                    side: BorderSide(
                      color: _category == cat ? p.primary : p.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    onSelected: (_) => setState(() {
                      _category = cat;
                      _categoryEdited = true;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            label('目标肌群 · 选填'),
            TextFormField(
              key: const Key('exercise-target'),
              controller: _target,
              maxLength: 40,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 13, color: p.textPrimary),
              decoration: field('例如：胸大肌上束 / 三角肌中束').copyWith(counterText: ''),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: p.textPrimary,
                        ),
                        decoration: field('3').copyWith(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 34, maxWidth: 34),
                          suffixIconConstraints:
                              const BoxConstraints(minWidth: 34, maxWidth: 34),
                          prefixIcon: IconButton(
                            key: const Key('exercise-sets-minus'),
                            tooltip: '减少一组',
                            padding: EdgeInsets.zero,
                            onPressed: () => _step(-1),
                            icon: Icon(Icons.remove_rounded,
                                size: 18, color: p.primary),
                          ),
                          suffixIcon: IconButton(
                            key: const Key('exercise-sets-plus'),
                            tooltip: '增加一组',
                            padding: EdgeInsets.zero,
                            onPressed: () => _step(1),
                            icon: Icon(Icons.add_rounded,
                                size: 18, color: p.primary),
                          ),
                        ),
                        validator: (v) {
                          final count = int.tryParse(v ?? '');
                          return count == null || count < 1 || count > 100
                              ? '请输入 1–100 组'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      label('每组次数 / 时长'),
                      TextFormField(
                        key: const Key('exercise-reps'),
                        controller: _reps,
                        style: TextStyle(fontSize: 13, color: p.textPrimary),
                        decoration: field('8–10 次 / 20 分钟'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? '请填写次数或时长' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in const [
                  '8-10',
                  '10-12',
                  '12-15',
                  '20分钟',
                  '45秒'
                ])
                  ActionChip(
                    label: Text(preset),
                    backgroundColor: p.surfaceMuted,
                    side: BorderSide(color: p.borderSubtle),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.textSecondary,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _reps.text = preset),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            label('组间休息'),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final option in const [
                  (0, '不计时'),
                  (45, '45 秒'),
                  (60, '60 秒'),
                  (90, '90 秒'),
                  (120, '2 分钟'),
                ])
                  ChoiceChip(
                    key: ValueKey('rest-preset-${option.$1}'),
                    label: Text(option.$2),
                    selected: (parseRestSeconds(_rest.text) ?? 0) == option.$1,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (parseRestSeconds(_rest.text) ?? 0) == option.$1
                          ? p.onPrimary
                          : p.textSecondary,
                    ),
                    selectedColor: p.primary,
                    backgroundColor: p.surfaceMuted,
                    side: BorderSide(
                      color: (parseRestSeconds(_rest.text) ?? 0) == option.$1
                          ? p.primary
                          : p.borderSubtle,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    onSelected: (_) => setState(
                      () => _rest.text = option.$1 == 0 ? '' : '${option.$1}s',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('exercise-rest'),
              controller: _rest,
              style: TextStyle(fontSize: 13, color: p.textPrimary),
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
                    Icon(Icons.timer_outlined, size: 18, color: p.textTertiary),
              ),
            ),
            const SizedBox(height: 16),
            label('补充说明 / 动作要点 · 选填'),
            TextFormField(
              key: const Key('exercise-note'),
              controller: _note,
              minLines: 2,
              maxLines: 3,
              style: TextStyle(fontSize: 13, height: 1.5, color: p.textPrimary),
              decoration: field('动作要点、器械座椅档位或感受'),
            ),
            if (widget.offerSaveToLibrary) ...[
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                key: const Key('save-to-library-switch'),
                contentPadding: EdgeInsets.zero,
                value: _saveToLibrary,
                onChanged: (v) => setState(() => _saveToLibrary = v),
                title: Text(
                  '同时保存到动作库',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '方便后续在模板和日常训练中重复挑选',
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                ),
              ),
            ],
            if (widget.isLibraryMode) ...[
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isFavorite,
                onChanged: (v) => setState(() => _isFavorite = v),
                title: Text(
                  '设为常用收藏动作',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              key: const Key('save-exercise'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: _save,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
