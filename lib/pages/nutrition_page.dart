import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_workout.dart';
import '../services/app_signals.dart';
import '../services/nutrition_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/daily_date_bar.dart';
import '../widgets/daily_record_date.dart';
import '../widgets/day_page_view.dart';
import '../widgets/kinetic_ring.dart';
import '../widgets/loading_view.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/undo_notice.dart';

class NutritionPage extends StatefulWidget {
  final DateTime Function()? now;
  const NutritionPage({super.key, this.now});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with WidgetsBindingObserver, DailyRecordDate<NutritionPage> {
  @override
  DateTime get now => widget.now?.call() ?? DateTime.now();
  Map<String, MealEntry>? _meals;
  String? _error;
  bool _busy = false;
  int _generation = 0;
  bool _loadScheduled = false;
  bool _ignoringSignals = false;

  @override
  void initState() {
    super.initState();
    nutritionRevision.addListener(_onRevisionChanged);
    workoutDataRevision.addListener(_onRevisionChanged);
    _load();
  }

  @override
  void dispose() {
    nutritionRevision.removeListener(_onRevisionChanged);
    workoutDataRevision.removeListener(_onRevisionChanged);
    super.dispose();
  }

  void _onRevisionChanged() {
    if (_ignoringSignals || _loadScheduled) return;
    _loadScheduled = true;
    scheduleMicrotask(() {
      _loadScheduled = false;
      if (mounted) _load();
    });
  }

  void _emitSilent(VoidCallback notify) {
    _ignoringSignals = true;
    try {
      notify();
    } finally {
      _ignoringSignals = false;
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

  Future<void> _edit(
    DateTime targetDate,
    (String, String, String) reference,
  ) async {
    if (_busy) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final date = dayKey(targetDate);
    final id = '$date|${reference.$1}';
    final before = _meals![id];
    final result = await showModalBottomSheet<_MealResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MealEditor(
        date: date,
        reference: reference,
        initial: before,
      ),
    );
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
      _emitSilent(() => nutritionRevision.value++);
      if (result.entry == null && before != null) {
        showUndoNotice(context, '已清除此餐记录', onUndo: () async {
          // An old undo must never replace a later record of this meal.
          if (!mounted || _busy || _meals!.containsKey(id)) return;
          setState(() => _busy = true);
          try {
            await saveMealEntry(id, before);
            _emitSilent(() => nutritionRevision.value++);
            await _load();
          } catch (_) {
            if (mounted) {
              showGlassNotice(context, '恢复失败，请重试', isError: true);
            }
          } finally {
            if (mounted) setState(() => _busy = false);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        showGlassNotice(context, '保存失败，请重试', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyYesterdayMeals(DateTime targetDate) async {
    if (_busy || _meals == null) return;
    final currentKey = dayKey(targetDate);
    final prevDate =
        DateTime(targetDate.year, targetDate.month, targetDate.day - 1);
    final prevKey = dayKey(prevDate);
    final prevMeals = _meals!.values.where((e) => e.date == prevKey).toList();
    if (prevMeals.isEmpty) return;

    setState(() => _busy = true);
    _generation++;
    var copiedCount = 0;
    try {
      for (final meal in prevMeals) {
        final copied = MealEntry(
          date: currentKey,
          meal: meal.meal,
          actual: meal.actual,
          calories: meal.calories,
          protein: meal.protein,
        );
        await saveMealEntry(copied.id, copied);
        _meals![copied.id] = copied;
        copiedCount++;
      }
      _emitSilent(() => nutritionRevision.value++);
      if (mounted) {
        setState(() {});
        showGlassNotice(context, '已沿用前一天 ${prevMeals.length} 餐记录');
      }
    } catch (_) {
      if (copiedCount > 0) {
        _emitSilent(() => nutritionRevision.value++);
      }
      try {
        final fresh = await loadMeals();
        if (mounted) {
          setState(() {
            _meals = fresh;
            _error = null;
          });
        }
      } catch (_) {
        if (mounted) setState(() {});
      }
      if (mounted) {
        showGlassNotice(
          context,
          copiedCount > 0 ? '部分餐次复制失败，已同步写入 $copiedCount 餐' : '复制失败，请重试',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: p.textPrimary)),
              const SizedBox(height: 10),
              TextButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_meals == null) return const LoadingView();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DailyDateBar(
            date: recordDate,
            today: today,
            enabled: !_busy,
            onChanged: selectRecordDate,
          ),
        ),
        Expanded(
          child: DayPageView(
            date: recordDate,
            minDate: DateTime(2000),
            maxDate: today,
            enabled: !_busy,
            onDateChanged: selectRecordDate,
            pageBuilder: _buildDayList,
          ),
        ),
      ],
    );
  }

  Widget _buildDayList(BuildContext context, DateTime pageDate) {
    final p = context.palette;
    final pageDateKey = dayKey(pageDate);
    final prevDateKey =
        dayKey(DateTime(pageDate.year, pageDate.month, pageDate.day - 1));
    final entries = _meals!.values.where((e) => e.date == pageDateKey).toList();
    final hasPrevMeals =
        entries.isEmpty && _meals!.values.any((e) => e.date == prevDateKey);
    final calories = entries.where((e) => e.calories != null);
    final protein = entries.where((e) => e.protein != null);

    const summaries = [
      '鸡蛋 · 牛奶 · 玉米 / 燕麦',
      '瘦肉 · 米饭 · 少油蔬菜',
      '鸡胸肉 · 香蕉 / 面包',
      '瘦肉 · 米饭 · 蔬菜',
      '零食、饮料与蛋白饮',
    ];
    const icons = [
      Icons.egg_outlined,
      Icons.rice_bowl_outlined,
      Icons.bolt_outlined,
      Icons.dinner_dining_outlined,
      Icons.local_cafe_outlined,
    ];
    const slotColors = [
      Color(0xFFFBBF24),
      Color(0xFF2EE59D),
      Color(0xFFFB923C),
      Color(0xFF38BDF8),
      Color(0xFFA78BFA),
    ];

    final mealProgress = entries.length / mealReferences.length;

    return ListView(
      key: PageStorageKey('nutrition-scroll-$pageDateKey'),
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
      children: [
        SurfaceCard(
          elevated: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: StatusPill(
                                label:
                                    '已记录 ${entries.length}/${mealReferences.length} 餐',
                                icon: Icons.restaurant_rounded,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: '营养汇总说明',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => showGlassConfirm(
                                context: context,
                                title: '营养汇总',
                                message: '仅汇总手动填写的热量和蛋白质。未填写的餐次不参与计算，也不等于零摄入。',
                                icon: Icons.info_outline_rounded,
                                cancelLabel: null,
                                confirmLabel: '知道了',
                              ),
                              icon: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _macroMetric(
                                value: calories.isEmpty
                                    ? '—'
                                    : calories
                                        .fold<double>(
                                          0,
                                          (sum, e) => sum + e.calories!,
                                        )
                                        .toStringAsFixed(0),
                                label: '已填热量',
                                unit: 'kcal',
                                color: p.warning,
                                p: p,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _macroMetric(
                                value: protein.isEmpty
                                    ? '—'
                                    : protein
                                        .fold<double>(
                                          0,
                                          (sum, e) => sum + e.protein!,
                                        )
                                        .toStringAsFixed(1),
                                label: '已填蛋白质',
                                unit: 'g',
                                color: p.primary,
                                p: p,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  KineticProgressRing(
                    progress: mealProgress,
                    size: 72,
                    strokeWidth: 7,
                    center: Text(
                      '${entries.length}/${mealReferences.length}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final reference in mealReferences)
                    Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _meals!
                                  .containsKey('$pageDateKey|${reference.$1}')
                              ? p.primary
                              : p.surfaceMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              if (hasPrevMeals) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _busy ? null : () => _copyYesterdayMeals(pageDate),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('沿用前一天饮食记录'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitleBar(
          title: '每餐记录',
          subtitle: '参考份量仅作推荐，按实际饮食填写即可',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < mealReferences.length; i++)
          Builder(
            builder: (context) {
              final reference = mealReferences[i];
              final meal = _meals!['$pageDateKey|${reference.$1}'];
              final slotColor = p.isDark
                  ? slotColors[i]
                  : HSLColor.fromColor(slotColors[i])
                      .withLightness(0.38)
                      .toColor();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  key: ValueKey('edit-meal-${reference.$1}'),
                  highlighted: meal != null,
                  onTap: _busy ? null : () => _edit(pageDate, reference),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color:
                              slotColor.withValues(alpha: p.isDark ? .16 : .11),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: slotColor.withValues(alpha: .28),
                            width: 0.9,
                          ),
                        ),
                        child: Icon(icons[i], size: 23, color: slotColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    reference.$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                ),
                                if (meal != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: p.primary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meal?.actual ?? '参考 · ${summaries[i]}',
                              key: ValueKey('meal-actual-${reference.$1}'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: meal != null
                                    ? p.textPrimary
                                    : p.textSecondary,
                              ),
                            ),
                            if (meal != null &&
                                (meal.calories != null ||
                                    meal.protein != null)) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (meal.calories != null)
                                    StatusPill(
                                      label:
                                          '${meal.calories!.toStringAsFixed(0)} kcal',
                                      color: p.warning,
                                    ),
                                  if (meal.protein != null)
                                    StatusPill(
                                      label:
                                          '蛋白 ${meal.protein!.toStringAsFixed(1)} g',
                                      color: p.primary,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        meal == null
                            ? Icons.add_circle_outline_rounded
                            : Icons.chevron_right_rounded,
                        size: 21,
                        color: meal == null ? p.primary : p.textTertiary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _macroMetric({
    required String value,
    required String label,
    required String unit,
    required Color color,
    required AppPalette p,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: p.textSecondary),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: p.isDark
                          ? color
                          : (value == '—' ? p.textTertiary : p.textPrimary),
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _MealResult {
  final MealEntry? entry;
  const _MealResult(this.entry);
}

class _MealEditor extends StatefulWidget {
  final String date;
  final (String, String, String) reference;
  final MealEntry? initial;
  const _MealEditor({
    required this.date,
    required this.reference,
    this.initial,
  });

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
      _MealResult(
        MealEntry(
          date: widget.date,
          meal: widget.reference.$1,
          actual: _actual.text.trim(),
          calories: double.tryParse(_calories.text.trim()),
          protein: double.tryParse(_protein.text.trim()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SheetFrame(
      title: '记录${widget.reference.$2}',
      subtitle: widget.date,
      icon: Icons.restaurant_rounded,
      body: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: p.isDark ? .10 : .06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.borderSubtle),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  '份量参考',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                children: [
                  Text(
                    widget.reference.$3,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () async {
                      if (_actual.text.trim().isNotEmpty) {
                        final replace = await showGlassConfirm(
                          context: context,
                          title: '替换已填写的饮食？',
                          message: '填入参考后，还可以按实际情况修改。',
                          icon: Icons.restaurant_rounded,
                          cancelLabel: '保留原内容',
                          confirmLabel: '填入参考',
                        );
                        if (replace != true || !mounted) return;
                      }
                      _actual.text = widget.reference.$3;
                    },
                    child: const Text('按参考填入，再按实际修改'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('meal-actual-input'),
              controller: _actual,
              minLines: 3,
              maxLines: 5,
              style: TextStyle(fontSize: 14, height: 1.5, color: p.textPrimary),
              decoration: const InputDecoration(
                labelText: '实际吃了什么',
                alignLabelWithHint: true,
                hintText: '例如：米饭、鸡胸肉和青菜',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '请填写实际饮食' : null,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final caloriesField = TextFormField(
                  key: const Key('meal-calories-input'),
                  controller: _calories,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '热量 kcal（选填）'),
                  validator: _number,
                );
                final proteinField = TextFormField(
                  key: const Key('meal-protein-input'),
                  controller: _protein,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '蛋白质 g（选填）'),
                  validator: _number,
                );
                if (constraints.maxWidth < 290) {
                  return Column(
                    children: [
                      caloriesField,
                      const SizedBox(height: 12),
                      proteinField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: caloriesField),
                    const SizedBox(width: 12),
                    Expanded(child: proteinField),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              '营养数值选填，仅汇总你手动填写的内容。',
              style: TextStyle(fontSize: 11.5, color: p.textSecondary),
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          if (widget.initial != null)
            TextButton(
              key: const Key('clear-meal'),
              onPressed: () => Navigator.pop(context, const _MealResult(null)),
              child: Text('清除', style: TextStyle(color: p.danger)),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const Key('save-meal'),
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
