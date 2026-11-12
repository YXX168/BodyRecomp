import 'package:flutter/material.dart';
import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/exercise_mark.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/text_prompt.dart';
import '../widgets/sheet_frame.dart';

class TemplateManagerPage extends StatefulWidget {
  const TemplateManagerPage({super.key});
  @override
  State<TemplateManagerPage> createState() => _TemplateManagerPageState();
}

class _TemplateManagerPageState extends State<TemplateManagerPage> {
  List<WorkoutTemplate>? _templates;
  List<String> _schedule = [];
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final templates = await loadWorkoutTemplates();
      final schedule = await loadWeeklySchedule();
      if (mounted) {
        setState(() {
          _templates = templates;
          _schedule = schedule;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '模板读取失败，原数据未被覆盖。');
    }
  }

  Future<void> _edit(WorkoutTemplate? template) async {
    final result = await Navigator.push<WorkoutTemplate>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                _TemplateEditor(template: template, library: _templates!)));
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = List<WorkoutTemplate>.from(_templates!);
      final index = next.indexWhere((value) => value.id == result.id);
      if (index < 0) {
        next.add(result);
      } else {
        next[index] = result;
      }
      await saveWorkoutTemplates(next);
      workoutPlanRevision.value++;
      if (mounted) setState(() => _templates = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('模板保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setDay(int day, String value) async {
    setState(() => _busy = true);
    try {
      final next = List<String>.from(_schedule)..[day] = value;
      await saveWeeklySchedule(next);
      workoutPlanRevision.value++;
      if (mounted) setState(() => _schedule = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('每周参考保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseDay(int day) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
          title: '周${['一', '二', '三', '四', '五', '六', '日'][day]}安排',
          subtitle: '只作当天参考，实际训练仍可自由组合',
          icon: Icons.calendar_month_outlined,
          body: Column(mainAxisSize: MainAxisSize.min, children: [
            SelectionOption(
                key: const ValueKey('schedule-option-rest'),
                title: '休息 / 恢复',
                subtitle: '给身体留出恢复时间',
                leading: _restMark(ctx),
                selected: _schedule[day].isEmpty,
                onTap: () => Navigator.pop(ctx, '')),
            for (final t in _templates!)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SelectionOption(
                      key: ValueKey('schedule-option-${t.id}'),
                      title: t.name,
                      subtitle: '${t.exercises.length} 个项目',
                      leading: ExerciseMark(
                          t.exercises.isEmpty ? '' : t.exercises.first.name,
                          size: 36),
                      selected: _schedule[day] == t.id,
                      onTap: () => Navigator.pop(ctx, t.id))),
          ])),
    );
    if (value != null && mounted && value != _schedule[day]) {
      await _setDay(day, value);
    }
  }

  Widget _restMark(BuildContext context) => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(11)),
      child: Icon(Icons.spa_outlined,
          size: 18, color: Theme.of(context).colorScheme.primary));

  Widget _weeklySchedule(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .5);
    return Container(
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.onSurface.withValues(alpha: .07))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var day = 0; day < 7; day++) ...[
          if (day > 0)
            Divider(
                height: 1,
                indent: 54,
                endIndent: 14,
                color: colors.onSurface.withValues(alpha: .06)),
          Builder(builder: (ctx) {
            final matches = _templates!.where((t) => t.id == _schedule[day]);
            final template = matches.isEmpty ? null : matches.first;
            return Material(
                color: Colors.transparent,
                child: InkWell(
                    key: ValueKey('schedule-day-$day'),
                    onTap: _busy ? null : () => _chooseDay(day),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(children: [
                          SizedBox(
                              width: 40,
                              child: Text(
                                  '周${[
                                    '一',
                                    '二',
                                    '三',
                                    '四',
                                    '五',
                                    '六',
                                    '日'
                                  ][day]}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: muted))),
                          template == null
                              ? _restMark(ctx)
                              : ExerciseMark(
                                  template.exercises.isEmpty
                                      ? ''
                                      : template.exercises.first.name,
                                  size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(template?.name ?? '休息 / 恢复',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: template == null
                                          ? muted
                                          : colors.onSurface))),
                          const SizedBox(width: 8),
                          Icon(Icons.unfold_more_rounded,
                              size: 17, color: muted),
                        ]))));
          }),
        ]
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('训练模板')),
        body: _error != null
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('重试'))
              ]))
            : _templates == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(padding: const EdgeInsets.all(16), children: [
                    Text('用模板做参考，按自己的节奏练。',
                        style: TextStyle(
                            fontSize: 11, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 16),
                    for (final template in _templates!)
                      Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                              leading: ExerciseMark(
                                  template.exercises.isEmpty
                                      ? '平板卧推'
                                      : template.exercises.first.name,
                                  size: 40),
                              title: Text(template.name),
                              subtitle: Text(
                                  '${template.exercises.length} 个项目 · 点击编辑'),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: _busy ? null : () => _edit(template))),
                    OutlinedButton.icon(
                        onPressed: _busy ? null : () => _edit(null),
                        icon: const Icon(Icons.add),
                        label: const Text('新建模板')),
                    const SizedBox(height: 24),
                    Text('每周参考安排',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('按日期提示，不限制当天实际训练。',
                        style: TextStyle(
                            fontSize: 11, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 14),
                    _weeklySchedule(context),
                  ]),
      );
}

class _TemplateEditor extends StatefulWidget {
  final WorkoutTemplate? template;
  final List<WorkoutTemplate> library;
  const _TemplateEditor({required this.template, required this.library});
  @override
  State<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<_TemplateEditor> {
  late String _name = widget.template?.name ?? '我的训练模板';
  late final _note = TextEditingController(text: widget.template?.note ?? '');
  late final List<Exercise> _exercises =
      List.from(widget.template?.exercises ?? []);
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _custom([int? index]) async {
    final exercise = await editExercise(context,
        initial: index == null ? null : _exercises[index]);
    if (exercise != null && mounted) {
      setState(() {
        if (index == null) {
          _exercises.add(exercise);
        } else {
          _exercises[index] = exercise;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('编辑模板'), actions: [
          TextButton(
              onPressed: () => Navigator.pop(
                  context,
                  WorkoutTemplate(
                      id: widget.template?.id ??
                          'custom_${DateTime.now().microsecondsSinceEpoch}',
                      name: _name,
                      note: _note.text.trim(),
                      exercises: List.from(_exercises))),
              child: const Text('保存'))
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_name, style: Theme.of(context).textTheme.titleLarge),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final value = await promptText(context, '模板名称', initial: _name);
                if (value != null && mounted) setState(() => _name = value);
              }),
          TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '模板说明 / 练后安排')),
          const SizedBox(height: 16),
          if (_exercises.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16), child: Text('添加项目来搭建模板。')),
          for (var i = 0; i < _exercises.length; i++)
            Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(children: [
                  ListTile(
                      leading: ExerciseMark(_exercises[i].name, size: 40),
                      title: Text(_exercises[i].name),
                      subtitle: Text(
                          '${_exercises[i].sets} 组 × ${_exercises[i].reps}'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _custom(i)),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(
                        tooltip: '上移',
                        onPressed: i == 0
                            ? null
                            : () => setState(() {
                                  final e = _exercises.removeAt(i);
                                  _exercises.insert(i - 1, e);
                                }),
                        icon: const Icon(Icons.arrow_upward, size: 20)),
                    IconButton(
                        tooltip: '下移',
                        onPressed: i == _exercises.length - 1
                            ? null
                            : () => setState(() {
                                  final e = _exercises.removeAt(i);
                                  _exercises.insert(i + 1, e);
                                }),
                        icon: const Icon(Icons.arrow_downward, size: 20)),
                    TextButton(
                        onPressed: () => setState(() => _exercises.removeAt(i)),
                        child: const Text('移除')),
                  ]),
                ])),
          OutlinedButton.icon(
              onPressed: () async {
                final values = await pickExercises(context, widget.library);
                if (values != null && mounted) {
                  setState(() => _exercises.addAll(values));
                }
              },
              icon: const Icon(Icons.view_module_outlined),
              label: const Text('从模板挑选项目')),
          OutlinedButton.icon(
              onPressed: () => _custom(),
              icon: const Icon(Icons.add),
              label: const Text('自定义项目')),
        ]),
      );
}
