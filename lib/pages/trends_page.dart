import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../services/data_service.dart';
import '../services/record_summary_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/body_editor.dart';
import '../widgets/exercise_mark.dart';
import '../widgets/loading_view.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/smooth_trend_chart.dart';
import '../widgets/text_prompt.dart';
import '../widgets/weight_log_sheet.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  int _segment = 0; // 0: 训练热力, 1: 力量 PR, 2: 身体曲线
  String _bodyTab = 'weight';
  int _viewYear = DateTime.now().year;
  int _viewMonth = DateTime.now().month;

  bool _loading = true;
  String? _loadError;
  int _loadGeneration = 0;

  Map<int, int> _monthData = {};
  int _yearTotal = 0;
  Map<int, Map<int, int>> _yearMonths = {};
  Map<String, DailyWorkout> _sessions = {};
  WorkoutAnalytics _analytics = const WorkoutAnalytics(
    currentStreak: 0,
    longestStreak: 0,
    monthCompletedSets: 0,
    last7Days: [],
  );

  List<ExerciseLog> _exerciseLogs = [];
  String? _selectedStrengthExercise;
  List<WeightEntry> _weightHistory = [];
  List<BodyMeasurement> _measurements = [];
  UserProfile _profile = UserProfile();

  @override
  void initState() {
    super.initState();
    workoutDataRevision.addListener(_loadData);
    workoutHistoryRevision.addListener(_loadData);
    exerciseLogsRevision.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    workoutDataRevision.removeListener(_loadData);
    workoutHistoryRevision.removeListener(_loadData);
    exerciseLogsRevision.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final generation = ++_loadGeneration;
    final year = _viewYear;
    final month = _viewMonth;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await loadDailyWorkouts();
      final summary = await loadRecordSummary(prefs, year, month);
      final logs = await loadExerciseLogs();
      final weights = await loadWeightHistory();
      final measurements = await loadMeasurements();
      final profile = await loadProfile();
      final analytics = computeWorkoutAnalytics(
        sessions,
        DateTime.now(),
        viewYear: year,
        viewMonth: month,
      );

      if (!mounted || generation != _loadGeneration) return;
      final distinctNames = logs.map((e) => e.exerciseName).toSet().toList();
      setState(() {
        _sessions = sessions;
        _monthData = summary.monthData;
        _yearTotal = summary.yearTotal;
        _yearMonths = summary.yearMonths;
        _analytics = analytics;
        _exerciseLogs = logs;
        if (_selectedStrengthExercise == null ||
            !distinctNames.contains(_selectedStrengthExercise)) {
          _selectedStrengthExercise =
              distinctNames.isEmpty ? null : distinctNames.first;
        }
        _weightHistory = weights;
        _measurements = measurements;
        _profile = profile;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _loadError = '统计数据读取失败，原记录未被覆盖。';
          _loading = false;
        });
      }
    }
  }

  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewYear--;
        _viewMonth = 12;
      } else {
        _viewMonth--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_viewYear > now.year ||
        (_viewYear == now.year && _viewMonth >= now.month)) {
      return;
    }
    setState(() {
      if (_viewMonth == 12) {
        _viewYear++;
        _viewMonth = 1;
      } else {
        _viewMonth++;
      }
    });
    _loadData();
  }

  void _goToday() {
    final now = DateTime.now();
    if (_viewYear == now.year && _viewMonth == now.month) return;
    setState(() {
      _viewYear = now.year;
      _viewMonth = now.month;
    });
    _loadData();
  }

  int _totalExercises() => _monthData.values.fold(0, (a, b) => a + b);
  int _trainDays() => _monthData.length;

  void _openDayDetail(int day) {
    final date = DateTime(_viewYear, _viewMonth, day);
    final key = dayKey(date);
    final session = _sessions[key];
    final count = _monthData[day] ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = ctx.palette;
        return SheetFrame(
          title: '$_viewYear年$_viewMonth月$day日',
          subtitle: session == null
              ? (count > 0 ? '历史已练 $count 个项目' : '当天无训练打卡记录')
              : session.rested
                  ? '已标记主动休息'
                  : '完成 ${session.trainedProjects} 个项目 · ${session.completedSets}/${session.plannedSets} 组',
          icon: Icons.calendar_today_rounded,
          body: session == null || session.blocks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    session?.rested == true
                        ? '当天记录为休息恢复日。'
                        : count > 0
                            ? '当天已归档 $count 个已练项目（旧版统计记录）。'
                            : '当天暂无具体训练项目记录。',
                    style: TextStyle(fontSize: 13.5, color: p.textSecondary),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final block in session.blocks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ExerciseMark(block.exercise.name, size: 38),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      block.exercise.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${block.completedSets}/${block.exercise.sets} 组 · ${block.exercise.reps}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: p.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (block.completedSets > 0)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: p.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _addWeightEntry({WeightEntry? existing}) async {
    final date = existing?.date ?? DateTime.now();
    final values = await editBodyValues(
      context,
      title: existing == null ? '记录体重' : '编辑体重',
      subtitle: '${date.year}年${date.month}月${date.day}日 · 同日记录会更新',
      fields: const {'weight': '体重 · kg'},
      initial: {'weight': existing?.weightKg ?? _profile.weightKg},
    );
    if (values == null || !mounted) return;
    final result = values['weight']!;
    try {
      final entries = await saveWeightEntry(
        WeightEntry(date: date, weightKg: result),
      );
      if (dateOnly(date) == dateOnly(DateTime.now())) {
        await saveProfile(
          UserProfile(
            birthday: _profile.birthday,
            heightCm: _profile.heightCm,
            weightKg: result,
            gender: _profile.gender,
          ),
        );
      }
      workoutDataRevision.value++;
      if (mounted) setState(() => _weightHistory = entries);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('体重记录保存失败，请重试')));
      }
    }
  }

  Future<void> _deleteWeightEntry(WeightEntry entry) async {
    final confirmed = await _confirmDelete(
      '删除 ${entry.weightKg.toStringAsFixed(1)}kg 的体重记录？',
    );
    if (!confirmed || !mounted) return;
    try {
      final entries = await deleteWeightEntry(entry.date);
      if (mounted) setState(() => _weightHistory = entries);
    } catch (_) {}
  }

  Future<void> _addMeasurement({BodyMeasurement? existing}) async {
    const fields = {
      'waist': '腰围 · cm',
      'chest': '胸围 · cm',
      'hip': '臀围 · cm',
      'arm': '臂围 · cm',
      'thigh': '大腿围 · cm',
    };
    final values = await editBodyValues(
      context,
      title: existing == null ? '记录围度' : '编辑围度',
      subtitle: '填写需要记录的部位，单位为厘米',
      fields: fields,
      initial: existing?.values ?? const {},
    );
    if (values == null || !mounted) return;
    try {
      final entries = await saveMeasurement(
        BodyMeasurement(date: existing?.date ?? DateTime.now(), values: values),
        replaceSameDay: existing != null,
      );
      if (mounted) setState(() => _measurements = entries);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('围度保存失败，请重试')));
      }
    }
  }

  Future<void> _deleteMeasurement(BodyMeasurement entry) async {
    final confirmed = await _confirmDelete(
      '删除 ${entry.date.month}/${entry.date.day} 的围度记录？',
    );
    if (!confirmed || !mounted) return;
    try {
      final entries = await deleteMeasurement(entry.date);
      if (mounted) setState(() => _measurements = entries);
    } catch (_) {}
  }

  Future<bool> _confirmDelete(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _logNewStrengthExercise() async {
    final name = await promptText(
      context,
      '记录动作负重',
      label: '动作名称',
      hint: '例如：平板卧推',
    );
    if (name == null || !mounted) return;
    await showWeightLogSheet(
      context,
      exerciseName: name,
      latestLog: exerciseHistory(_exerciseLogs, name).firstOrNull,
      personalRecord: exercisePersonalRecord(_exerciseLogs, name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (_loading) return const LoadingView();
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, style: TextStyle(color: p.textPrimary)),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: _loadData, child: const Text('重试')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final raw = await exportAllData();
                      if (!context.mounted) return;
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('原数据备份 (JSON)'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                raw,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('关闭'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('查看原数据'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Row(
              children: [
                for (final item in const [
                  (0, '训练热力'),
                  (1, '力量 PR'),
                  (2, '身体数据'),
                ])
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('trends-seg-${item.$1}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _segment = item.$1),
                      child: AnimatedContainer(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _segment == item.$1
                              ? p.surfaceElevated
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _segment == item.$1
                              ? Border.all(color: p.borderHighlight, width: 0.9)
                              : null,
                        ),
                        child: Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: _segment == item.$1
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _segment == item.$1
                                ? p.primary
                                : p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (_segment) {
            0 => _buildTrainingAnalytics(context),
            1 => _buildStrengthView(context),
            _ => _buildBodyMetricsView(context),
          },
        ),
      ],
    );
  }

  Widget _buildTrainingAnalytics(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final isCurrentMonth = _viewYear == now.year && _viewMonth == now.month;
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;
    final firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday - 1;
    const monthNames = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];
    const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
      children: [
        // Month switcher
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(Icons.chevron_left_rounded, color: p.primary),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _goToday,
                  child: Column(
                    children: [
                      Text(
                        '$_viewYear年 ${monthNames[_viewMonth - 1]}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        isCurrentMonth ? '当前月份' : '点击回到本月',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCurrentMonth ? p.primary : p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: isCurrentMonth ? null : _nextMonth,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: isCurrentMonth
                      ? p.textTertiary.withValues(alpha: .35)
                      : p.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Bento 2x2 metrics grid
        Row(
          children: [
            Expanded(
              child: _bentoStat(
                '当前连续',
                '${_analytics.currentStreak}',
                '天 · 最长 ${_analytics.longestStreak}天',
                Icons.local_fire_department_rounded,
                p.warning,
                p,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _bentoStat(
                '本月训练',
                '${_trainDays()}',
                '天 · ${_totalExercises()} 项目',
                Icons.calendar_month_rounded,
                p.primary,
                p,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _bentoStat(
                '本月完成组数',
                '${_analytics.monthCompletedSets}',
                '组实际打卡',
                Icons.layers_rounded,
                p.accent,
                p,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _bentoStat(
                '年度累计项目',
                '$_yearTotal',
                '$_viewYear 全年',
                Icons.emoji_events_rounded,
                p.primaryBright,
                p,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 7-day volume bar chart
        const SectionTitleBar(
          title: '近 7 天训练容量',
          subtitle: '每日实际完成组数分布',
        ),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _WeeklyVolumeBars(points: _analytics.last7Days),
        ),
        const SizedBox(height: 18),

        // Interactive calendar heatmap
        const SectionTitleBar(
          title: '月度训练热力图',
          subtitle: '点击任意日期查看当天训练详情',
        ),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: firstWeekday + daysInMonth,
                itemBuilder: (context, idx) {
                  if (idx < firstWeekday) return const SizedBox.shrink();
                  final day = idx - firstWeekday + 1;
                  final count = _monthData[day] ?? 0;
                  final isToday = isCurrentMonth && day == now.day;
                  final intensity =
                      count == 0 ? 0.0 : (count / 5).clamp(0.28, 1.0);
                  return GestureDetector(
                    onTap: () => _openDayDetail(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: count > 0
                            ? p.primary
                                .withValues(alpha: 0.16 + intensity * 0.72)
                            : p.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday
                            ? Border.all(color: p.primaryBright, width: 1.6)
                            : Border.all(color: p.borderSubtle, width: 0.6),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday || count > 0
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: count > 0 && intensity > 0.55
                                  ? p.onPrimary
                                  : isToday
                                      ? p.primary
                                      : p.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('少',
                      style: TextStyle(fontSize: 11, color: p.textTertiary)),
                  const SizedBox(width: 6),
                  for (final level in const [0.0, 0.3, 0.65, 1.0])
                    Container(
                      width: 13,
                      height: 13,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: level == 0
                            ? p.surfaceMuted
                            : p.primary.withValues(alpha: 0.16 + level * 0.72),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  Text('多',
                      style: TextStyle(fontSize: 11, color: p.textTertiary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        SectionTitleBar(
          title: '$_viewYear 年度概览',
          subtitle: '全年 12 个月训练分布',
        ),
        const SizedBox(height: 10),
        SurfaceCard(
          padding: const EdgeInsets.all(14),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemCount: 12,
            itemBuilder: (context, idx) => _buildMiniMonth(idx + 1, p),
          ),
        ),
      ],
    );
  }

  Widget _bentoStat(
    String label,
    String value,
    String sub,
    IconData icon,
    Color tint,
    AppPalette p,
  ) =>
      SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: tint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: p.textTertiary),
            ),
          ],
        ),
      );

  Widget _buildMiniMonth(int month, AppPalette p) {
    final data = _yearMonths[month] ?? {};
    final daysInMonth = DateTime(_viewYear, month + 1, 0).day;
    final firstWd = DateTime(_viewYear, month, 1).weekday - 1;
    final isSelected = month == _viewMonth;

    return GestureDetector(
      onTap: () {
        setState(() => _viewMonth = month);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected
              ? p.primary.withValues(alpha: p.isDark ? .12 : .07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: p.borderHighlight) : null,
        ),
        child: Column(
          children: [
            Text(
              '$month月',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? p.primary : p.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                ),
                itemCount: firstWd + daysInMonth,
                itemBuilder: (context, idx) {
                  if (idx < firstWd) return const SizedBox.shrink();
                  final day = idx - firstWd + 1;
                  final count = data[day] ?? 0;
                  return Container(
                    decoration: BoxDecoration(
                      color: count > 0
                          ? p.primary.withValues(
                              alpha: (0.28 + count * 0.14).clamp(0.28, 0.95),
                            )
                          : p.surfaceMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthView(BuildContext context) {
    final p = context.palette;
    final names = _exerciseLogs.map((e) => e.exerciseName).toSet().toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
      children: [
        SectionTitleBar(
          title: '力量进阶与 PR',
          subtitle: '根据日常负重与次数估算 1RM',
          trailing: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: _logNewStrengthExercise,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('记负重'),
          ),
        ),
        const SizedBox(height: 12),
        if (names.isEmpty)
          SurfaceCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 34, color: p.textTertiary),
                const SizedBox(height: 10),
                Text(
                  '还没有力量负重记录',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '在训练卡片点击哑铃图标或点击右上角「记负重」，即可追踪每个动作的 1RM 增长曲线。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
              ],
            ),
          )
        else ...[
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final name in names)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      selected: _selectedStrengthExercise == name,
                      showCheckmark: false,
                      label: Text(name),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _selectedStrengthExercise == name
                            ? p.onPrimary
                            : p.textSecondary,
                      ),
                      selectedColor: p.primary,
                      backgroundColor: p.surface,
                      side: BorderSide(
                        color: _selectedStrengthExercise == name
                            ? p.primary
                            : p.borderSubtle,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedStrengthExercise = name),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedStrengthExercise != null)
            Builder(
              builder: (context) {
                final name = _selectedStrengthExercise!;
                final history = exerciseHistory(_exerciseLogs, name);
                final pr = exercisePersonalRecord(_exerciseLogs, name);
                final chartPoints = history.reversed
                    .take(24)
                    .map(
                      (log) => TrendPoint(
                        '${log.date.month}/${log.date.day}',
                        log.estimated1RM > 0 ? log.estimated1RM : log.weightKg,
                      ),
                    )
                    .toList();

                return Column(
                  children: [
                    SurfaceCard(
                      elevated: true,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ExerciseMark(name, size: 42),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: p.textPrimary,
                                      ),
                                    ),
                                    if (pr != null)
                                      Text(
                                        '最佳 PR: ${pr.weightKg.toStringAsFixed(1)}kg × ${pr.reps} · 预估 1RM ${pr.estimated1RM.toStringAsFixed(1)}kg',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: '新增一次记录',
                                onPressed: () => showWeightLogSheet(
                                  context,
                                  exerciseName: name,
                                  latestLog: history.firstOrNull,
                                  personalRecord: pr,
                                ),
                                icon: Icon(Icons.add_circle_rounded,
                                    color: p.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SmoothTrendChart(
                            points: chartPoints,
                            unit: 'kg (1RM)',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final log in history.take(15))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SurfaceCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                child: Text(
                                  '${log.date.month}/${log.date.day}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${log.weightKg.toStringAsFixed(1)} kg · ${log.sets}组 × ${log.reps}次'
                                  '${log.rpe > 0 ? ' · RPE ${log.rpe.toInt()}' : ''}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: '删除记录',
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  if (await _confirmDelete('删除这条负重记录？')) {
                                    await deleteExerciseLog(log);
                                    exerciseLogsRevision.value++;
                                  }
                                },
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: p.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildBodyMetricsView(BuildContext context) {
    final p = context.palette;
    final isWeight = _bodyTab == 'weight';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.borderSubtle),
                ),
                child: Row(
                  children: [
                    for (final tab in const [
                      ('weight', '体重趋势'),
                      ('measurements', '身体围度'),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _bodyTab = tab.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _bodyTab == tab.$1
                                  ? p.surfaceElevated
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              tab.$2,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _bodyTab == tab.$1
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _bodyTab == tab.$1
                                    ? p.primary
                                    : p.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: isWeight ? _addWeightEntry : _addMeasurement,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('记录'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (isWeight) ...[
          SurfaceCard(
            elevated: true,
            padding: const EdgeInsets.all(16),
            child: SmoothTrendChart(
              points: _weightHistory
                  .skip(math.max(0, _weightHistory.length - 30))
                  .map(
                    (e) => TrendPoint(
                      '${e.date.month}/${e.date.day}',
                      e.weightKg,
                    ),
                  )
                  .toList(),
              unit: ' kg',
            ),
          ),
          const SizedBox(height: 14),
          if (_weightHistory.isEmpty)
            SurfaceCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '点击右上角「记录」开始追踪体重变化',
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ),
            ),
          for (final entry in _weightHistory.reversed.take(15))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SurfaceCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 68,
                      child: Text(
                        '${entry.date.month}/${entry.date.day}',
                        style: TextStyle(fontSize: 12, color: p.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${entry.weightKg.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '编辑',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _addWeightEntry(existing: entry),
                      icon:
                          Icon(Icons.edit_outlined, size: 18, color: p.primary),
                    ),
                    IconButton(
                      tooltip: '删除',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _deleteWeightEntry(entry),
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 18, color: p.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
        ] else ...[
          if (_measurements.isEmpty)
            SurfaceCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '点击右上角「记录」填写腰围、胸围、臀围等数据',
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ),
            )
          else ...[
            if (_measurements.any((m) => m.values.containsKey('waist'))) ...[
              SurfaceCard(
                elevated: true,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '腰围变化趋势',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SmoothTrendChart(
                      points: _measurements
                          .where((m) => m.values.containsKey('waist'))
                          .map(
                            (m) => TrendPoint(
                              '${m.date.month}/${m.date.day}',
                              m.values['waist']!,
                            ),
                          )
                          .toList(),
                      unit: ' cm',
                      lineColor: p.accent,
                      glowColor: p.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final entry in _measurements.reversed.take(12))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 58,
                        child: Text(
                          '${entry.date.month}/${entry.date.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.values.entries
                              .map((e) =>
                                  '${_measurementLabel(e.key)} ${e.value.toStringAsFixed(1)}cm')
                              .join(' · '),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '编辑',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _addMeasurement(existing: entry),
                        icon: Icon(Icons.edit_outlined,
                            size: 18, color: p.primary),
                      ),
                      IconButton(
                        tooltip: '删除',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteMeasurement(entry),
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 18, color: p.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  String _measurementLabel(String key) => switch (key) {
        'waist' => '腰围',
        'chest' => '胸围',
        'hip' => '臀围',
        'arm' => '臂围',
        'thigh' => '大腿围',
        _ => key,
      };
}

class _WeeklyVolumeBars extends StatelessWidget {
  final List<DayVolumePoint> points;
  const _WeeklyVolumeBars({required this.points});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (points.isEmpty) return const SizedBox(height: 90);
    final maxSets =
        points.fold<int>(1, (best, pt) => math.max(best, pt.completedSets));
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < points.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      points[i].completedSets > 0
                          ? '${points[i].completedSets}'
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: p.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final maxH = math.max(12.0, c.maxHeight);
                          final barH = points[i].completedSets == 0
                              ? 6.0
                              : math.max(
                                  14.0,
                                  maxH * (points[i].completedSets / maxSets),
                                );
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 20,
                              height: barH,
                              decoration: BoxDecoration(
                                gradient: points[i].completedSets > 0
                                    ? LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [p.primary, p.primaryBright],
                                      )
                                    : null,
                                color: points[i].completedSets == 0
                                    ? p.surfaceMuted
                                    : null,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '周${weekdays[points[i].date.weekday - 1]}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == points.length - 1
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: i == points.length - 1
                            ? p.primary
                            : p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
