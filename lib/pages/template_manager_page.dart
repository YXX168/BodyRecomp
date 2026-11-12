import 'package:flutter/material.dart';
import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../widgets/exercise_editor.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/text_prompt.dart';

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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('训练模板与每周参考')),
        body: _error != null
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('重试'))
              ]))
            : _templates == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(padding: const EdgeInsets.all(16), children: [
                    const Text('模板是参考，不会限制实际训练，也不会改动过去的记录。'),
                    const SizedBox(height: 16),
                    for (final template in _templates!)
                      Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
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
                    const Text('训练页会按日期提示对应模板。休息日也可以自行加入训练。'),
                    for (var day = 0; day < 7; day++)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Text(
                                '周${['一', '二', '三', '四', '五', '六', '日'][day]}'),
                            const SizedBox(width: 16),
                            Expanded(
                                child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _templates!
                                            .any((t) => t.id == _schedule[day])
                                        ? _schedule[day]
                                        : '',
                                    items: [
                                      const DropdownMenuItem(
                                          value: '', child: Text('休息 / 恢复')),
                                      for (final t in _templates!)
                                        DropdownMenuItem(
                                            value: t.id,
                                            child: Text(t.name,
                                                overflow:
                                                    TextOverflow.ellipsis))
                                    ],
                                    onChanged: _busy
                                        ? null
                                        : (value) {
                                            if (value != null) {
                                              _setDay(day, value);
                                            }
                                          })),
                          ])),
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
