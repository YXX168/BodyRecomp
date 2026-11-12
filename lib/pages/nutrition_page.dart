import '../widgets/loading_view.dart';
import 'package:flutter/material.dart';
import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/nutrition_service.dart';
import '../widgets/daily_date_bar.dart';
import '../widgets/sheet_frame.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with WidgetsBindingObserver {
  bool _followToday = true;
  DateTime _date = dateOnly(DateTime.now());
  Map<String, MealEntry>? _meals;
  String? _error;
  bool _busy = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    workoutDataRevision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    workoutDataRevision.removeListener(_load);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _followToday &&
        _date != dateOnly(DateTime.now())) {
      setState(() => _date = dateOnly(DateTime.now()));
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final values = await loadMeals();
      if (mounted && generation == _generation) {
        setState(() {
          _meals = values;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = '饮食记录读取失败，原数据未被覆盖。');
      }
    }
  }

  Future<void> _edit((String, String, String) reference) async {
    if (_busy) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final date = dayKey(_date);
    final id = '$date|${reference.$1}';
    final before = _meals![id];
    final result = await showModalBottomSheet<_MealResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            _MealEditor(date: date, reference: reference, initial: before));
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    _generation++;
    try {
      await saveMealEntry(id, result.entry);
      if (!mounted) return;
      setState(() {
        if (result.entry == null) {
          _meals!.remove(id);
        } else {
          _meals![id] = result.entry!;
        }
      });
      if (result.entry == null && before != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: const Text('已清除此餐记录'),
              action: SnackBarAction(
                  label: '撤销',
                  onPressed: () async {
                    // An old undo must never replace a later record of this meal.
                    if (!mounted || _busy || _meals!.containsKey(id)) return;
                    setState(() => _busy = true);
                    try {
                      await saveMealEntry(id, before);
                      await _load();
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('恢复失败，请重试')));
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  })));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!),
        TextButton(onPressed: _load, child: const Text('重试'))
      ]));
    if (_meals == null) return const LoadingView();
    final entries =
        _meals!.values.where((e) => e.date == dayKey(_date)).toList();
    final calories = entries.where((e) => e.calories != null);
    final protein = entries.where((e) => e.protein != null);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: .45);
    const summaries = [
      '鸡蛋 · 牛奶 · 玉米 / 燕麦',
      '瘦肉 · 米饭 · 少油蔬菜',
      '鸡胸肉 · 香蕉 / 面包',
      '瘦肉 · 米饭 · 蔬菜',
      '零食、饮料与蛋白饮'
    ];
    const icons = [
      Icons.egg_outlined,
      Icons.rice_bowl_outlined,
      Icons.bolt_outlined,
      Icons.dinner_dining_outlined,
      Icons.local_cafe_outlined
    ];
    const colors = [
      Color(0xFFBD8C44),
      Color(0xFF628269),
      Color(0xFFA47664),
      Color(0xFF7287A1),
      Color(0xFF9984A4)
    ];
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          DailyDateBar(
              date: _date,
              today: DateTime.now(),
              enabled: !_busy,
              onChanged: (date) => setState(() {
                    _date = date;
                    _followToday = date == dateOnly(DateTime.now());
                  })),
          const SizedBox(height: 14),
          Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      child: _metric(
                          calories.isEmpty
                              ? '—'
                              : calories
                                  .fold<double>(
                                      0, (sum, e) => sum + e.calories!)
                                  .toStringAsFixed(0),
                          '已填热量',
                          'kcal',
                          const Color(0xFFB88A45))),
                  Container(
                      width: 1,
                      height: 32,
                      color: muted.withValues(alpha: .15)),
                  Expanded(
                      child: _metric(
                          protein.isEmpty
                              ? '—'
                              : protein
                                  .fold<double>(0, (sum, e) => sum + e.protein!)
                                  .toStringAsFixed(1),
                          '已填蛋白质',
                          'g',
                          const Color(0xFF628269))),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  for (final reference in mealReferences)
                    Expanded(
                        child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                                color: _meals!.containsKey(
                                        '${dayKey(_date)}|${reference.$1}')
                                    ? theme.colorScheme.primary
                                    : theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(2))))
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('已记录 ${entries.length} 餐',
                      style: TextStyle(fontSize: 10, color: muted)),
                  const Spacer(),
                  IconButton(
                      tooltip: '营养汇总说明',
                      onPressed: () => showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                              title: Text('营养汇总'),
                              content:
                                  Text('仅汇总手动填写的热量和蛋白质。未填写的餐次不参与计算，也不等于零摄入。'))),
                      icon: Icon(Icons.info_outline, size: 15, color: muted))
                ]),
              ])),
          const SizedBox(height: 20),
          const Text('每餐记录',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (var i = 0; i < mealReferences.length; i++)
            Builder(builder: (context) {
              final reference = mealReferences[i];
              final meal = _meals!['${dayKey(_date)}|${reference.$1}'];
              return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18)),
                  child: InkWell(
                      key: ValueKey('edit-meal-${reference.$1}'),
                      borderRadius: BorderRadius.circular(18),
                      onTap: _busy ? null : () => _edit(reference),
                      child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                    color: colors[i].withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(14)),
                                child:
                                    Icon(icons[i], size: 23, color: colors[i])),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Text(reference.$2,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 7),
                                    if (meal != null)
                                      Icon(Icons.check_circle,
                                          size: 12,
                                          color: theme.colorScheme.primary)
                                  ]),
                                  const SizedBox(height: 5),
                                  Text(meal?.actual ?? '参考 · ${summaries[i]}',
                                      key: ValueKey(
                                          'meal-actual-${reference.$1}'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 10,
                                          height: 1.5,
                                          color: muted)),
                                ])),
                            const SizedBox(width: 8),
                            Icon(
                                meal == null
                                    ? Icons.add_rounded
                                    : Icons.chevron_right_rounded,
                                size: 20,
                                color: muted),
                          ]))));
            }),
          const SizedBox(height: 4),
          Text('点开餐次，查看份量参考或记录实际饮食。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: muted)),
        ]);
  }

  Widget _metric(String value, String label, String unit, Color color) =>
      Column(children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
        const SizedBox(height: 7),
        Text.rich(TextSpan(children: [
          TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w600, color: color)),
          TextSpan(
              text: ' $unit',
              style:
                  TextStyle(fontSize: 10, color: Theme.of(context).hintColor))
        ])),
      ]);
}

class _MealResult {
  final MealEntry? entry;
  const _MealResult(this.entry);
}

class _MealEditor extends StatefulWidget {
  final String date;
  final (String, String, String) reference;
  final MealEntry? initial;
  const _MealEditor(
      {required this.date, required this.reference, this.initial});
  @override
  State<_MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<_MealEditor> {
  final _form = GlobalKey<FormState>();
  late final _actual =
      TextEditingController(text: widget.initial?.actual ?? '');
  late final _calories =
      TextEditingController(text: widget.initial?.calories?.toString() ?? '');
  late final _protein =
      TextEditingController(text: widget.initial?.protein?.toString() ?? '');
  @override
  void dispose() {
    _actual.dispose();
    _calories.dispose();
    _protein.dispose();
    super.dispose();
  }

  String? _number(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value);
    return number == null || !number.isFinite || number < 0
        ? '请输入非负数字，或留空'
        : null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(
        context,
        _MealResult(MealEntry(
            date: widget.date,
            meal: widget.reference.$1,
            actual: _actual.text.trim(),
            calories: double.tryParse(_calories.text.trim()),
            protein: double.tryParse(_protein.text.trim()))));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SheetFrame(
        title: '记录${widget.reference.$2}',
        subtitle: widget.date,
        icon: Icons.restaurant_rounded,
        body: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .05),
                      borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: const Text('份量参考', style: TextStyle(fontSize: 12)),
                      children: [
                        Text(widget.reference.$3,
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color:
                                    colors.onSurface.withValues(alpha: .65))),
                        TextButton(
                            onPressed: () async {
                              if (_actual.text.trim().isNotEmpty) {
                                final replace = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                            title: const Text('替换已填写的饮食？'),
                                            content:
                                                const Text('填入参考后，还可以按实际情况修改。'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('保留原内容')),
                                              FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('填入参考')),
                                            ]));
                                if (replace != true || !mounted) return;
                              }
                              _actual.text = widget.reference.$3;
                            },
                            child: const Text('按参考填入，再按实际修改')),
                      ])),
              const SizedBox(height: 18),
              TextFormField(
                  key: const Key('meal-actual-input'),
                  controller: _actual,
                  minLines: 3,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                  decoration: const InputDecoration(
                      labelText: '实际吃了什么',
                      alignLabelWithHint: true,
                      hintText: '例如：米饭、鸡胸肉和青菜'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请填写实际饮食' : null),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: TextFormField(
                        key: const Key('meal-calories-input'),
                        controller: _calories,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: '热量 kcal（选填）'),
                        validator: _number)),
                const SizedBox(width: 12),
                Expanded(
                    child: TextFormField(
                        key: const Key('meal-protein-input'),
                        controller: _protein,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: '蛋白质 g（选填）'),
                        validator: _number)),
              ]),
              const SizedBox(height: 8),
              Text('营养数值选填，仅汇总你手动填写的内容。',
                  style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurface.withValues(alpha: .5))),
            ])),
        footer: Row(children: [
          if (widget.initial != null)
            TextButton(
                key: const Key('clear-meal'),
                onPressed: () =>
                    Navigator.pop(context, const _MealResult(null)),
                child: const Text('清除')),
          const Spacer(),
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          const SizedBox(width: 8),
          FilledButton(
              key: const Key('save-meal'),
              onPressed: _save,
              child: const Text('保存')),
        ]));
  }
}
