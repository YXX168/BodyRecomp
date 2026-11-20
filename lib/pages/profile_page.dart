import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_workout.dart';
import '../models/recomp_models.dart';
import '../services/app_signals.dart';
import '../services/daily_workout_service.dart';
import '../services/data_service.dart';
import '../services/record_summary_service.dart';
import '../services/rest_timer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/body_editor.dart';
import '../widgets/exercise_mark.dart';
import '../widgets/loading_view.dart';
import '../widgets/sheet_frame.dart';
import '../widgets/smooth_trend_chart.dart';
import 'nutrition_page.dart';
import 'trends_page.dart';

const progressionPhases = [
  ('1-2 周', '学习期', '60-70% 1RM，掌握动作模式与控制节奏'),
  ('3-4 周', '适应期', '70-75% 1RM，轻松达标可小幅加重'),
  ('5-8 周', '增长期', '75-85% 1RM，保持 RPE 7-8 稳步推高容量'),
  ('9-12 周', '突破期', '接近 85% 1RM，巩固核心动作 PR'),
];

typedef ProfileHubPage = ProfilePage;

class ProfilePage extends StatefulWidget {
  final String appVersion;
  const ProfilePage({super.key, this.appVersion = '7.1.0'});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  List<WeightEntry> _weights = [];
  Map<int, int> _monthData = {};
  Map<String, DailyWorkout> _sessions = {};
  WorkoutAnalytics _analytics = const WorkoutAnalytics(
    currentStreak: 0,
    longestStreak: 0,
    monthCompletedSets: 0,
    last7Days: [],
  );
  int _viewYear = DateTime.now().year;
  int _viewMonth = DateTime.now().month;

  bool _autoRestTimer = false;
  bool _hasImportBackup = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    workoutDataRevision.addListener(_loadAll);
    workoutHistoryRevision.addListener(_loadAll);
    restTimerPreferenceRevision.addListener(_loadAll);
    _loadAll();
  }

  @override
  void dispose() {
    workoutDataRevision.removeListener(_loadAll);
    workoutHistoryRevision.removeListener(_loadAll);
    restTimerPreferenceRevision.removeListener(_loadAll);
    super.dispose();
  }

  Future<void> _loadAll() async {
    UserProfile? profile;
    var autoRest = false;
    var hasBackup = false;
    try {
      profile = await loadProfile();
      autoRest = await loadAutoRestTimer();
      hasBackup = await hasLastImportBackup();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '个人设置读取失败，本地数据未被覆盖。';
        });
      }
      return;
    }

    List<WeightEntry> weights = [];
    Map<String, DailyWorkout> sessions = {};
    Map<int, int> monthData = {};
    var analytics = const WorkoutAnalytics(
      currentStreak: 0,
      longestStreak: 0,
      monthCompletedSets: 0,
      last7Days: [],
    );
    String? statsError;

    try {
      final prefs = await SharedPreferences.getInstance();
      weights = await loadWeightHistory();
      sessions = await loadDailyWorkouts();
      final summary = await loadRecordSummary(prefs, _viewYear, _viewMonth);
      monthData = summary.monthData;
      analytics = computeWorkoutAnalytics(
        sessions,
        DateTime.now(),
        viewYear: _viewYear,
        viewMonth: _viewMonth,
      );
    } catch (_) {
      statsError = '统计数据读取失败，原记录未被覆盖。';
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _autoRestTimer = autoRest;
      _hasImportBackup = hasBackup;
      _weights = weights;
      _sessions = sessions;
      _monthData = monthData;
      _analytics = analytics;
      _loading = false;
      _loadError = null;
      _statsError = statsError;
    });
  }

  Future<void> _showRawStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final buffer = StringBuffer();
    for (final k in prefs.getKeys().toList()..sort()) {
      if (!k.startsWith('recomp_')) continue;
      buffer.writeln('$k: ${prefs.get(k)}');
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('本地原始存储'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              buffer.isEmpty ? '（无本地记录）' : buffer.toString(),
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
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
  }

  Future<void> _persist(Future<void> Function() action) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile(UserProfile profile) async {
    await saveProfile(profile);
    if (mounted) setState(() => _profile = profile);
    workoutDataRevision.value++;
  }

  void _shiftMonth(int delta) {
    final now = DateTime.now();
    var y = _viewYear;
    var m = _viewMonth + delta;
    if (m < 1) {
      y--;
      m = 12;
    } else if (m > 12) {
      y++;
      m = 1;
    }
    if (y > now.year || (y == now.year && m > now.month)) return;
    setState(() {
      _viewYear = y;
      _viewMonth = m;
    });
    _loadAll();
  }

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
              ? (count > 0 ? '已完成 $count 项' : '无训练记录')
              : session.rested
                  ? '休息恢复日'
                  : '${session.completedSets}/${session.plannedSets} 组',
          icon: Icons.calendar_today_rounded,
          body: session == null || session.blocks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    session?.rested == true
                        ? '当天已记录休息。'
                        : count > 0
                            ? '归档 $count 项训练。'
                            : '暂无打卡项目。',
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
                                Icon(Icons.check_circle_rounded,
                                    size: 18, color: p.primary),
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

  Future<void> _addWeightEntry() async {
    final profile = _profile ?? UserProfile();
    final values = await editBodyValues(
      context,
      title: '记录今日体重',
      fields: const {'weight': '体重 · kg'},
      initial: {'weight': profile.weightKg},
    );
    if (values == null || !mounted) return;
    final w = values['weight']!;
    await _persist(() async {
      final list = await saveWeightEntry(
        WeightEntry(date: DateTime.now(), weightKg: w),
      );
      await _saveProfile(
        UserProfile(
          birthday: profile.birthday,
          heightCm: profile.heightCm,
          weightKg: w,
          gender: profile.gender,
        ),
      );
      if (mounted) setState(() => _weights = list);
    });
  }

  Future<void> _openThemeSheet() async {
    final controller = ThemeScope.maybeOf(context);
    if (controller == null) return;
    final picked = await showModalBottomSheet<AppTheme>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
        title: '流光主题工坊',
        icon: Icons.palette_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in AppTheme.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Builder(
                  builder: (_) {
                    final target = AppPalette.forTheme(mode);
                    return SelectionOption(
                      key: ValueKey('profile-theme-${mode.name}'),
                      title: target.name,
                      subtitle: target.tagline,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: target.canvas,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: target.primary.withValues(alpha: .55),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [target.orb1, target.orb2],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      selected: mode == controller.current,
                      onTap: () => Navigator.pop(ctx, mode),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      await controller.setTheme(picked);
    }
  }

  Future<void> _openProfileSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final p = ctx.palette;
          final profile = _profile ?? UserProfile();
          final bmi = profile.bmi;
          final bmiNorm =
              bmi <= 0 ? 0.0 : ((bmi - 15) / (34 - 15)).clamp(0.0, 1.0);
          return SheetFrame(
            title: '身体档案',
            subtitle: 'BMI ${bmi > 0 ? bmi.toStringAsFixed(1) : '--'}',
            icon: Icons.person_rounded,
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                p.accent,
                                p.success,
                                p.warning,
                                p.danger,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: (c.maxWidth - 10) * bmiNorm,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: p.canvas, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _profileChip(
                        key: const Key('profile-height-btn'),
                        label: '身高',
                        value: '${profile.heightCm.toStringAsFixed(0)} cm',
                        onTap: () async {
                          await _editHeight(profile);
                          setSheetState(() {});
                        },
                        p: p,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _profileChip(
                        key: const Key('profile-weight-btn'),
                        label: '体重',
                        value: '${profile.weightKg.toStringAsFixed(1)} kg',
                        onTap: () async {
                          await _editWeight(profile);
                          setSheetState(() {});
                        },
                        p: p,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _profileChip(
                        key: const Key('profile-gender-btn'),
                        label: '性别',
                        value: profile.gender == 'female' ? '女' : '男',
                        onTap: () async {
                          await _editGender(profile);
                          setSheetState(() {});
                        },
                        p: p,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _profileChip(
                        key: const Key('profile-birthday-btn'),
                        label: '年龄 / 生日',
                        value: profile.age > 0
                            ? '${profile.age} 岁'
                            : (profile.birthday.isEmpty
                                ? '点击设置'
                                : profile.birthday),
                        onTap: () async {
                          await _editBirthday(profile);
                          setSheetState(() {});
                        },
                        p: p,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openBackupSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = ctx.palette;
        return SheetFrame(
          title: '本地备份',
          subtitle: 'JSON 导入导出 · 数据仅保存在本机',
          icon: Icons.shield_outlined,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const Key('export-json-btn'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: _saving
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _exportData();
                      },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('导出 JSON'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('import-json-btn'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: _saving
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _importData();
                      },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('导入恢复'),
              ),
              if (_hasImportBackup) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _restorePreImportBackup();
                        },
                  icon: Icon(Icons.history_rounded, size: 17, color: p.primary),
                  label: const Text('恢复上次导入前快照'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _editBirthday(UserProfile p) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(p.birthday) ?? DateTime(1995, 6, 15);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1930),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '选择出生日期',
    );
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    await _persist(
      () => _saveProfile(
        UserProfile(
          birthday: formatted,
          heightCm: p.heightCm,
          weightKg: p.weightKg,
          gender: p.gender,
        ),
      ),
    );
  }

  Future<void> _editGender(UserProfile profile) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SheetFrame(
        title: '性别',
        icon: Icons.person_outline_rounded,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectionOption(
              title: '男',
              leading: const Icon(Icons.male_rounded),
              selected: profile.gender == 'male',
              onTap: () => Navigator.pop(ctx, 'male'),
            ),
            const SizedBox(height: 8),
            SelectionOption(
              title: '女',
              leading: const Icon(Icons.female_rounded),
              selected: profile.gender == 'female',
              onTap: () => Navigator.pop(ctx, 'female'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await _persist(
      () => _saveProfile(
        UserProfile(
          birthday: profile.birthday,
          heightCm: profile.heightCm,
          weightKg: profile.weightKg,
          gender: choice,
        ),
      ),
    );
  }

  Future<void> _editHeight(UserProfile profile) async {
    final values = await editBodyValues(
      context,
      title: '身高',
      fields: const {'height': '身高 · cm'},
      initial: {'height': profile.heightCm},
    );
    if (values == null || !mounted) return;
    await _persist(
      () => _saveProfile(
        UserProfile(
          birthday: profile.birthday,
          heightCm: values['height']!,
          weightKg: profile.weightKg,
          gender: profile.gender,
        ),
      ),
    );
  }

  Future<void> _editWeight(UserProfile profile) async {
    final values = await editBodyValues(
      context,
      title: '当前体重',
      fields: const {'weight': '体重 · kg'},
      initial: {'weight': profile.weightKg},
    );
    if (values == null || !mounted) return;
    final weight = values['weight']!;
    await _persist(() async {
      final nextWeights = await saveWeightEntry(
        WeightEntry(date: DateTime.now(), weightKg: weight),
      );
      await _saveProfile(
        UserProfile(
          birthday: profile.birthday,
          heightCm: profile.heightCm,
          weightKg: weight,
          gender: profile.gender,
        ),
      );
      if (mounted) setState(() => _weights = nextWeights);
    });
  }

  Future<void> _exportData() async {
    try {
      final json = await exportAllData();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('数据导出 (JSON)'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                json,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (!ctx.mounted || !mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制 JSON 备份到剪贴板')),
                );
              },
              child: const Text('复制全部'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _importData() async {
    final ctrl = TextEditingController();
    var mode = ImportMode.merge;
    try {
      final result = await showDialog<ImportMode>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            final p = ctx.palette;
            return AlertDialog(
              title: const Text('导入数据'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ctrl,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: '粘贴 JSON 备份…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectionOption(
                      title: '合并（推荐）',
                      leading: Icon(Icons.merge_rounded, color: p.primary),
                      selected: mode == ImportMode.merge,
                      onTap: () =>
                          setDialogState(() => mode = ImportMode.merge),
                    ),
                    const SizedBox(height: 8),
                    SelectionOption(
                      title: '覆盖',
                      leading:
                          Icon(Icons.restore_page_outlined, color: p.warning),
                      selected: mode == ImportMode.overwrite,
                      onTap: () =>
                          setDialogState(() => mode = ImportMode.overwrite),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, mode);
                  },
                  child: const Text('导入'),
                ),
              ],
            );
          },
        ),
      );

      if (result == null || ctrl.text.trim().isEmpty || !mounted || _saving) {
        return;
      }

      setState(() => _saving = true);
      final themeController = context.themeController;
      try {
        final imported = await importAllData(ctrl.text, mode: result);
        if (!mounted) return;
        await themeController?.load();
        await _loadAll();
        if (!mounted) return;
        _broadcastAllRevisions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已${result == ImportMode.merge ? "合并" : "覆盖"}导入 ${imported.importedKeys} 项',
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导入失败: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _restorePreImportBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复导入前快照？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted || _saving) return;
    setState(() => _saving = true);
    final themeController = context.themeController;
    try {
      await restoreLastImportBackup();
      if (!mounted) return;
      await themeController?.load();
      await _loadAll();
      if (!mounted) return;
      _broadcastAllRevisions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复上一次导入前数据')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _broadcastAllRevisions() {
    workoutDataRevision.value++;
    workoutHistoryRevision.value++;
    workoutPlanRevision.value++;
    exerciseLibraryRevision.value++;
    exerciseLogsRevision.value++;
    restTimerPreferenceRevision.value++;
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
              const SizedBox(height: 10),
              TextButton(onPressed: _loadAll, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    final latestWeight =
        _weights.isEmpty ? profile.weightKg : _weights.last.weightKg;
    final weightPoints = [
      for (final e in _weights)
        TrendPoint('${e.date.month}/${e.date.day}', e.weightKg),
    ];
    final currentTheme = context.themeController?.current ?? AppTheme.blue;
    final themeName =
        AppPalette.forTheme(currentTheme).name.split('·').first.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 114),
      children: [
        if (_statsError != null) ...[
          SurfaceCard(
            radius: 22,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statsError!,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.danger,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(onPressed: _loadAll, child: const Text('重试')),
                    TextButton(
                      onPressed: _showRawStoredData,
                      child: const Text('查看原数据'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        // 1. Bento Consistency Row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SurfaceCard(
                  radius: 20,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              p.warning.withValues(alpha: p.isDark ? .16 : .12),
                        ),
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          size: 19,
                          color: p.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_analytics.currentStreak} 天',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              '连续打卡',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: SurfaceCard(
                  radius: 20,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              p.primary.withValues(alpha: p.isDark ? .16 : .12),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 17,
                          color: p.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_monthData.length} 天',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              '$_viewMonth月训练',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Interactive Monthly Dot Heatmap
        _buildMonthlyHeatmap(context),
        const SizedBox(height: 12),

        // 3. Visual Weight Curve Card
        SurfaceCard(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '体重趋势',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${latestWeight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: p.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('add-weight-btn'),
                    tooltip: '记录体重',
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    constraints:
                        const BoxConstraints.tightFor(width: 36, height: 36),
                    padding: EdgeInsets.zero,
                    onPressed: _saving ? null : _addWeightEntry,
                    icon: Icon(Icons.add_circle_rounded,
                        size: 25, color: p.primary),
                  ),
                  TextButton(
                    key: const Key('open-trends-btn'),
                    style: TextButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 34),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('训练与身体数据')),
                          body: const LiquidBackdrop(child: TrendsPage()),
                        ),
                      ),
                    ),
                    child: const Text('详情'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SmoothTrendChart(
                points: weightPoints,
                unit: 'kg',
                height: 128,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. 2x2 Visual Glass Quick Tiles
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickGlassTile(
                  key: const Key('hub-diet-tile'),
                  icon: Icons.restaurant_rounded,
                  tint: p.primary,
                  title: '饮食日记',
                  badge: '蛋白 · 热量',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('饮食日记')),
                        body: const LiquidBackdrop(child: NutritionPage()),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickGlassTile(
                  key: const Key('hub-theme-tile'),
                  icon: Icons.palette_rounded,
                  tint: p.accent,
                  title: '流光主题',
                  badge: themeName,
                  onTap: _openThemeSheet,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickGlassTile(
                  key: const Key('hub-profile-tile'),
                  icon: Icons.person_rounded,
                  tint: p.primaryBright,
                  title: '身体档案',
                  badge: 'BMI ${profile.bmi.toStringAsFixed(1)}',
                  onTap: _openProfileSheet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickGlassTile(
                  key: const Key('hub-backup-tile'),
                  icon: Icons.shield_outlined,
                  tint: p.warning,
                  title: '数据备份',
                  badge: _hasImportBackup ? '有快照' : '本地 JSON',
                  onTap: _openBackupSheet,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. Auto Rest Timer Switch
        SurfaceCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SwitchListTile.adaptive(
            key: const Key('auto-rest-switch'),
            value: _autoRestTimer,
            onChanged: _saving
                ? null
                : (value) async {
                    await _persist(() async {
                      await saveAutoRestTimer(value);
                      restTimerPreferenceRevision.value++;
                      if (mounted) setState(() => _autoRestTimer = value);
                    });
                  },
            title: Text(
              '自动组间休息计时',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '青燃 · v${widget.appVersion}',
            style: TextStyle(fontSize: 11.5, color: p.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyHeatmap(BuildContext context) {
    final p = context.palette;
    final daysInMonth = DateUtils.getDaysInMonth(_viewYear, _viewMonth);
    final firstWeekday = DateTime(_viewYear, _viewMonth, 1).weekday;
    final leadingBlanks = firstWeekday - 1;
    final now = DateTime.now();
    final isCurrentMonth = _viewYear == now.year && _viewMonth == now.month;
    const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_viewYear年$_viewMonth月',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: '上月',
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                constraints:
                    const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
                onPressed: () => _shiftMonth(-1),
                icon: Icon(Icons.chevron_left_rounded,
                    size: 20, color: p.textSecondary),
              ),
              IconButton(
                tooltip: '下月',
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                constraints:
                    const BoxConstraints.tightFor(width: 30, height: 30),
                padding: EdgeInsets.zero,
                onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isCurrentMonth
                      ? p.textTertiary.withValues(alpha: .35)
                      : p.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final w in weekLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: p.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellSize =
                  ((constraints.maxWidth - 24) / 7).clamp(24.0, 34.0);
              return Column(
                children: [
                  for (var row = 0; row < totalCells ~/ 7; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final cellIdx = row * 7 + col;
                                  final day = cellIdx - leadingBlanks + 1;
                                  if (day < 1 || day > daysInMonth) {
                                    return SizedBox(height: cellSize);
                                  }
                                  final count = _monthData[day] ?? 0;
                                  final isTodayCell =
                                      isCurrentMonth && day == now.day;
                                  final active = count > 0;
                                  return Center(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _openDayDetail(day),
                                      child: Container(
                                        width: cellSize,
                                        height: cellSize,
                                        decoration: BoxDecoration(
                                          gradient:
                                              active ? p.primaryGradient : null,
                                          color: active
                                              ? null
                                              : (p.isDark
                                                  ? Colors.white
                                                      .withValues(alpha: .055)
                                                  : Colors.black
                                                      .withValues(alpha: .04)),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: isTodayCell
                                              ? Border.all(
                                                  color: p.primary, width: 1.4)
                                              : null,
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '$day',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    active || isTodayCell
                                                        ? FontWeight.w800
                                                        : FontWeight.w500,
                                                color: active
                                                    ? p.onPrimary
                                                    : isTodayCell
                                                        ? p.primary
                                                        : p.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _profileChip({
    Key? key,
    required String label,
    required String value,
    required VoidCallback onTap,
    required AppPalette p,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.glassFillTop, p.glassFillBottom],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _QuickGlassTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String badge;
  final VoidCallback onTap;

  const _QuickGlassTile({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      radius: 20,
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: p.isDark ? .16 : .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tint.withValues(alpha: p.isDark ? .28 : .20),
                width: 0.85,
              ),
            ),
            child: Icon(icon, size: 19, color: tint),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: p.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressionPage extends StatelessWidget {
  const ProgressionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
      children: [
        for (var i = 0; i < progressionPhases.length; i++)
          Builder(
            builder: (context) {
              final (weeks, title, desc) = progressionPhases[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: p.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: p.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusPill(label: weeks),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: TextStyle(
                                fontSize: 13,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
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
}
