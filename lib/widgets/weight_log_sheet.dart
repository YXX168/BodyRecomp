import 'package:flutter/material.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'ambient_background.dart';
import 'sheet_frame.dart';

Future<ExerciseLog?> showWeightLogSheet(
  BuildContext context, {
  required String exerciseName,
  int defaultSets = 3,
  int defaultReps = 10,
  ExerciseLog? latestLog,
  ExerciseLog? personalRecord,
}) =>
    showModalBottomSheet<ExerciseLog>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WeightLogSheet(
        exerciseName: exerciseName,
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        latestLog: latestLog,
        personalRecord: personalRecord,
      ),
    );

class _WeightLogSheet extends StatefulWidget {
  final String exerciseName;
  final int defaultSets;
  final int defaultReps;
  final ExerciseLog? latestLog;
  final ExerciseLog? personalRecord;

  const _WeightLogSheet({
    required this.exerciseName,
    required this.defaultSets,
    required this.defaultReps,
    this.latestLog,
    this.personalRecord,
  });

  @override
  State<_WeightLogSheet> createState() => _WeightLogSheetState();
}

class _WeightLogSheetState extends State<_WeightLogSheet> {
  final _form = GlobalKey<FormState>();
  late final _weightCtrl = TextEditingController(
    text: widget.latestLog != null && widget.latestLog!.weightKg > 0
        ? _fmtNum(widget.latestLog!.weightKg)
        : '',
  );
  late final _repsCtrl = TextEditingController(
    text:
        '${widget.latestLog != null && widget.latestLog!.reps > 0 ? widget.latestLog!.reps : widget.defaultReps}',
  );
  late final _setsCtrl = TextEditingController(
    text:
        '${widget.latestLog != null && widget.latestLog!.sets > 0 ? widget.latestLog!.sets : widget.defaultSets}',
  );
  double _rpe = 8;
  bool _saving = false;

  static String _fmtNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  void initState() {
    super.initState();
    if (widget.latestLog != null && widget.latestLog!.rpe > 0) {
      _rpe = widget.latestLog!.rpe;
    }
    _weightCtrl.addListener(_onChanged);
    _repsCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _weightCtrl.removeListener(_onChanged);
    _repsCtrl.removeListener(_onChanged);
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _setsCtrl.dispose();
    super.dispose();
  }

  void _stepWeight(double delta) {
    final current = double.tryParse(_weightCtrl.text.trim()) ?? 20.0;
    final next = (current + delta).clamp(0.5, 500.0);
    _weightCtrl.text = _fmtNum(next);
  }

  void _stepInt(TextEditingController ctrl, int delta, int min, int max) {
    final current = int.tryParse(ctrl.text.trim()) ?? min;
    ctrl.text = '${(current + delta).clamp(min, max)}';
  }

  double get _estimated1RM {
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final r = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    if (w <= 0 || r <= 0) return 0;
    return w * (1 + r / 30.0);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final log = ExerciseLog(
        exerciseName: widget.exerciseName,
        date: DateTime.now(),
        weightKg: double.parse(_weightCtrl.text.trim()),
        sets: int.parse(_setsCtrl.text.trim()),
        reps: int.parse(_repsCtrl.text.trim()),
        rpe: _rpe,
      );
      await saveExerciseLog(widget.exerciseName, log);
      exerciseLogsRevision.value++;
      if (mounted) Navigator.pop(context, log);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('负重记录保存失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final best1RM = widget.personalRecord?.estimated1RM ?? 0;
    final current1RM = _estimated1RM;
    final beatsPR = current1RM > 0 && current1RM > best1RM;

    return SheetFrame(
      title: '记录负重 · ${widget.exerciseName}',
      subtitle: widget.personalRecord != null
          ? '历史 PR ${_fmtNum(widget.personalRecord!.weightKg)}kg × ${widget.personalRecord!.reps}（预估 1RM ${best1RM.toStringAsFixed(1)}kg）'
          : '记录训练负重，追踪力量渐进与个人纪录 (PR)',
      icon: Icons.fitness_center_rounded,
      body: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '负重 (kg)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('weight-log-kg'),
              controller: _weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: p.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '例如：60',
                suffixText: 'kg',
              ),
              validator: (v) {
                final val = double.tryParse(v?.trim() ?? '');
                return val == null || !val.isFinite || val <= 0
                    ? '请输入大于 0 的负重数值'
                    : null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final delta in const [-5.0, -2.5, 2.5, 5.0])
                  ActionChip(
                    label: Text('${delta > 0 ? '+' : ''}${_fmtNum(delta)} kg'),
                    backgroundColor: p.surfaceMuted,
                    side: BorderSide(color: p.borderSubtle),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: delta > 0 ? p.primary : p.textSecondary,
                    ),
                    onPressed: () => _stepWeight(delta),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '组数',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('weight-log-sets'),
                        controller: _setsCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            onPressed: () => _stepInt(_setsCtrl, -1, 1, 100),
                            icon: Icon(Icons.remove_rounded,
                                size: 18, color: p.primary),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => _stepInt(_setsCtrl, 1, 1, 100),
                            icon: Icon(Icons.add_rounded,
                                size: 18, color: p.primary),
                          ),
                        ),
                        validator: (v) {
                          final val = int.tryParse(v?.trim() ?? '');
                          return val == null || val < 1 || val > 100
                              ? '1–100'
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
                      Text(
                        '每组次数',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('weight-log-reps'),
                        controller: _repsCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            onPressed: () => _stepInt(_repsCtrl, -1, 1, 200),
                            icon: Icon(Icons.remove_rounded,
                                size: 18, color: p.primary),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => _stepInt(_repsCtrl, 1, 1, 200),
                            icon: Icon(Icons.add_rounded,
                                size: 18, color: p.primary),
                          ),
                        ),
                        validator: (v) {
                          final val = int.tryParse(v?.trim() ?? '');
                          return val == null || val < 1 || val > 200
                              ? '1–200'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '主观疲劳度 RPE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rpe in const [6.0, 7.0, 8.0, 9.0, 10.0])
                  ChoiceChip(
                    label: Text('RPE ${rpe.toInt()}'),
                    selected: _rpe == rpe,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _rpe == rpe ? p.onPrimary : p.textSecondary,
                    ),
                    selectedColor: p.primary,
                    backgroundColor: p.surfaceMuted,
                    side: BorderSide(
                      color: _rpe == rpe ? p.primary : p.borderSubtle,
                    ),
                    onSelected: (_) => setState(() => _rpe = rpe),
                  ),
              ],
            ),
            if (current1RM > 0) ...[
              const SizedBox(height: 16),
              SurfaceCard(
                highlighted: beatsPR,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      beatsPR
                          ? Icons.emoji_events_rounded
                          : Icons.auto_graph_rounded,
                      color: beatsPR ? p.warning : p.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '预估 1RM · ${current1RM.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          if (beatsPR)
                            Text(
                              '将刷新该动作个人纪录 (PR)！',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: p.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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
              key: const Key('save-weight-log'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中...' : '保存负重'),
            ),
          ),
        ],
      ),
    );
  }
}
